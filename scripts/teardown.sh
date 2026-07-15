#!/usr/bin/env bash
#
# teardown.sh — destruction de l'infra InfoLine
#
# ⚠️ BROUILLON Phase 5 — NON testé de bout en bout (validation prévue au run du 22 juil).
#    Dérivé de RUNBOOK.md §7. Le chemin de référence garanti reste le RUNBOOK.
#
# Par défaut : détruit UNIQUEMENT EKS (destroy quotidien — control plane facturé à l'heure),
# après avoir supprimé le Service LoadBalancer (ELB créé hors Terraform — RUNBOOK §7).
# Avec --full : détruit aussi Lambda, ECR et IAM-CI (fin de projet).
#
# Usage :
#   ./scripts/teardown.sh [--full] [--yes]
#
set -euo pipefail

AWS_REGION="${AWS_REGION:-eu-west-3}"
FULL=0
ASSUME_YES=0

for arg in "$@"; do
  case "$arg" in
    --full)   FULL=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    *) echo "Argument inconnu : $arg" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mÉCHEC : %s\033[0m\n' "$*" >&2; exit 1; }

command -v terraform >/dev/null 2>&1 || fail "terraform introuvable."
command -v kubectl   >/dev/null 2>&1 || fail "kubectl introuvable."

SCOPE="EKS uniquement (destroy quotidien)"
[ "$FULL" -eq 1 ] && SCOPE="TOTAL — EKS + Lambda + ECR + IAM-CI (fin de projet)"

if [ "$ASSUME_YES" -ne 1 ]; then
  echo "Destruction : $SCOPE"
  read -r -p "Confirmer la destruction ? [y/N] " reply
  [ "$reply" = "y" ] || [ "$reply" = "Y" ] || { echo "Annulé."; exit 0; }
fi

# --- Supprimer les Services LoadBalancer AVANT le destroy (ELB hors IaC — RUNBOOK §7) ---
# '|| true' : sans objets déployés, kubectl echoue sans que ce soit une erreur bloquante.
log "Suppression des Services exposés (évite l'ELB orphelin qui bloque la suppression du VPC)"
kubectl delete -f k8s/ --ignore-not-found=true 2>/dev/null || true
# k8s/elk/ n'expose rien en LoadBalancer par défaut (accès port-forward) — décommenter si ça change :
# kubectl delete -f k8s/elk/ --ignore-not-found=true 2>/dev/null || true

destroy_module() {
  local dir="$1"
  log "terraform destroy — $dir"
  terraform -chdir="$dir" destroy -auto-approve
}

# --- EKS (toujours) --------------------------------------------------------
destroy_module terraform/eks
log "Contrôles post-destroy EKS"
aws eks list-clusters --region "$AWS_REGION" --no-cli-pager || true
aws ec2 describe-nat-gateways --region "$AWS_REGION" \
  --filter "Name=state,Values=available" --no-cli-pager || true

# --- Le reste (seulement en --full) ---------------------------------------
if [ "$FULL" -eq 1 ]; then
  destroy_module terraform/lambda-login   # login serverless
  destroy_module terraform/ecr            # ⚠️ supprime les images poussées
  destroy_module terraform/iam-ci         # ⚠️ invalide les clés → secrets GitHub à re-régler
  log "Destroy total terminé — penser à re-régler les secrets GitHub au prochain rebuild."
else
  log "EKS détruit. ECR / IAM-CI / Lambda conservés (coût quasi nul)."
fi
