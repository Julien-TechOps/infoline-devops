#!/usr/bin/env bash
#
# rebuild.sh — reconstruction centralisée de l'infra InfoLine (mesure du RTO)
#
# ⚠️ BROUILLON Phase 5 — NON testé de bout en bout (validation prévue au run du 22 juil).
#    Dérivé de RUNBOOK.md (procédure validée manuellement). Ne PAS communiquer de RTO
#    mesuré tant que ce script n'a pas tourné en conditions réelles.
#
# Reconstruit dans l'ordre de dépendance : ECR → IAM-CI → Lambda → EKS, puis rafraîchit
# kubectl. Le déploiement de l'API se fait ensuite via CI (git push) — voir la fin du script.
#
# Usage :
#   ./scripts/rebuild.sh [--yes] [--deploy-api-manual]
#   AWS_REGION=eu-west-3 CLUSTER_NAME=infoline-eks ./scripts/rebuild.sh
#
set -euo pipefail

AWS_REGION="${AWS_REGION:-eu-west-3}"
CLUSTER_NAME="${CLUSTER_NAME:-infoline-eks}"
ASSUME_YES=0
DEPLOY_API_MANUAL=0

for arg in "$@"; do
  case "$arg" in
    -y|--yes)              ASSUME_YES=1 ;;
    --deploy-api-manual)   DEPLOY_API_MANUAL=1 ;;
    *) echo "Argument inconnu : $arg" >&2; exit 2 ;;
  esac
done

# Se placer à la racine du repo (le script vit dans scripts/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mÉCHEC : %s\033[0m\n' "$*" >&2; exit 1; }

# --- Préflight -------------------------------------------------------------
log "Préflight — outils et identité AWS"
for bin in aws terraform kubectl mvn; do
  command -v "$bin" >/dev/null 2>&1 || fail "$bin introuvable (cf. RUNBOOK §1)."
done
aws sts get-caller-identity >/dev/null || fail "AWS CLI non authentifié."

if [ "$ASSUME_YES" -ne 1 ]; then
  echo "Cette opération va exécuter 'terraform apply' (création de ressources AWS facturées)."
  read -r -p "Continuer ? [y/N] " reply
  [ "$reply" = "y" ] || [ "$reply" = "Y" ] || { echo "Annulé."; exit 0; }
fi

START_TS=$(date +%s)

apply_module() {
  local dir="$1"
  log "terraform apply — $dir"
  terraform -chdir="$dir" init -input=false >/dev/null
  terraform -chdir="$dir" apply -auto-approve
}

# --- 1. ECR (permanent, idempotent) ---------------------------------------
apply_module terraform/ecr

# --- 2. IAM-CI (permanent) -------------------------------------------------
apply_module terraform/iam-ci

# --- 3. Lambda login — compiler le jar AVANT l'apply (RUNBOOK §2.5) --------
log "Build du jar Lambda (mvn package)"
mvn -f lambda-login package -q || fail "Build Maven de la Lambda échoué."
apply_module terraform/lambda-login

# --- 4. EKS (le poste le plus long, ~15-20 min) ---------------------------
apply_module terraform/eks
log "Rafraîchissement du kubeconfig (endpoint recréé à chaque reconstruction — RUNBOOK §8)"
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
log "Vérification des nœuds"
kubectl get nodes

END_TS=$(date +%s)
ELAPSED=$(( END_TS - START_TS ))
log "Infra reconstruite en ${ELAPSED}s (~$(( ELAPSED / 60 )) min) — RTO infra indicatif"

# --- 5. Déploiement de l'API ----------------------------------------------
if [ "$DEPLOY_API_MANUAL" -eq 1 ]; then
  log "Déploiement manuel de l'API (RUNBOOK §4) — dernière image ECR"
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  TAG=$(aws ecr describe-images --repository-name infoline-api --region "$AWS_REGION" \
        --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' --output text)
  [ "$TAG" = "None" ] && fail "Aucune image sur ECR — déclencher d'abord un build CI."
  IMAGE="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/infoline-api:${TAG}"
  echo "Image : $IMAGE"
  sed "s|IMAGE_PLACEHOLDER|${IMAGE}|" k8s/api-deployment.yaml | kubectl apply -f -
  kubectl apply -f k8s/api-service.yaml
  kubectl rollout status deployment/infoline-api --timeout=240s
else
  cat <<'EOF'

Infra prête. Chemin NOMINAL de déploiement de l'API = CI/CD (RUNBOOK §3) :
  git commit --allow-empty -m "redeploy" && git push origin main
  # → GitHub Actions build/push l'image et fait le kubectl apply + rollout.

(Alternative : relancer ce script avec --deploy-api-manual pour déployer la dernière
 image ECR sans passer par la CI — RUNBOOK §4.)
EOF
fi

log "Terminé."
