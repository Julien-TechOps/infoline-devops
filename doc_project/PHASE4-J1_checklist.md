# Phase 4 — Jour 1 : checklist d'exécution (A3-Q1 — Elasticsearch connecté à K8s)

> Document de travail perso (pas un livrable ECF). Coche au fur et à mesure.
> Plan détaillé + « pourquoi » (topo ELK, justification des choix, arbre de décision) :
> `~/.claude/plans/j-attaque-la-phase-4-soft-quasar.md` (hors repo, non versionné). Ici = **quoi faire, dans l'ordre**.
>
> **Objectif du jour :** Elasticsearch déployé sur EKS + logs des pods ingérés via Filebeat,
> le tout prouvé par des requêtes. Kibana = J2.
>
> **Légende :** 🟢 offline, gratuit, faisable dès aujourd'hui · 🔴 cluster live, **facturé** (destroy le soir).
>
> **📍 État au dim 12 juil, fin de session :** Étape 0 et Étape 1 faites. Nœuds `m7i-flex.large` Ready,
> vérifiés (`kubectl get nodes`). **Cluster détruit avant coupure** (voir rappel destroy en fin d'Étape 1).
> Reprise lundi à l'Étape 2 — le type d'instance est réglé, pas besoin d'y revenir.

---

## Étape 0 — Préparation offline (🟢 aujourd'hui, gratuit)

- [X] Relire le topo ELK (logs vs métriques · les 4 briques · le flux des logs dans k8s). Objectif : savoir
      redessiner de tête le schéma « conteneur → fichier nœud → Filebeat DaemonSet → Elasticsearch ».
- [x] Récupérer la **version ECK courante** : `v3.4.1` (dernière stable, 12/07). Stack associé retenu :
      `9.4.3` (dernière stable ES/Kibana/Beats). Pairing exact non confirmé par une source officielle
      fraîche (recherches infructueuses) — **à valider empiriquement lundi** via les logs de l'opérateur
      dès le premier `apply` du CR Elasticsearch, avant tout coût réel.
- [x] Vérifier que le `terraform destroy` de vendredi a bien été fait (confirmé indirectement : l'apply
      du dimanche a recréé le control plane depuis zéro).
- [x] Écrire les 2 manifests (versions substituées : `9.4.3`) :
  - [x] `k8s/elk/elasticsearch.yaml`
  - [x] `k8s/elk/filebeat.yaml`
  - ⚠️ **Surtout PAS dans `k8s/`** : la CI ferait `kubectl apply` dessus au prochain push. `k8s/elk/` est
        appliqué **à la main** uniquement.
- [x] Créer le squelette `doc_project/A3-Q1_synthese.md` (calqué sur `A2-Q3_synthese.md`).

> 💡 Tu peux t'arrêter là aujourd'hui : tout ce qui suit est facturé. Idéalement, la partie 🔴 se fait
> d'une traite pour minimiser les heures cluster (réveil → déploiement → preuve → destroy).

---

## Étape 1 — Lever le risque n°1 : type d'instance ✅ FAIT (dim 12 juil)

**Résolu.** Ce n'était ni une SCP ni une pénurie transitoire (hypothèses initiales, fausses) : le compte
est **Free Tier**, avec une restriction **au lancement réel** — `t3a.medium`/`t3.medium` échouaient en
boucle sur l'ASG (`InvalidParameterCombination - not eligible for Free Tier`), invisible dans la sortie
`terraform apply` (visible seulement via `describe-scaling-activities`). Un `run-instances --dry-run`
**ne détecte pas** cette restriction (teste l'IAM/SCP, pas l'éligibilité Free Tier) — piège à ne pas
reproduire. Détail complet + commande de diagnostic réutilisable : `RUNBOOK.md` §8, friction à journaliser
sous **F11** dans `FRICTIONS.md` (Étape 6).

**Type retenu : `m7i-flex.large` (8 GiB, Free Tier confirmé dans eu-west-3)**, trouvé via :
```bash
aws ec2 describe-instance-types --region eu-west-3 \
  --filters "Name=free-tier-eligible,Values=true" \
  --query 'InstanceTypes[].{Type:InstanceType,vCPU:VCpuInfo.DefaultVCpus,MemoryMiB:MemoryInfo.SizeInMiB}' \
  --output table
```
`terraform/eks/terraform.tfvars` porte déjà `node_instance_types = ["m7i-flex.large", "c7i-flex.large"]`
— **rien à retoucher lundi**, un `terraform apply` suffira à recréer un cluster identique.

- [x] `terraform.tfvars` corrigé (`m7i-flex.large`, `c7i-flex.large`).
- [x] `terraform apply` terminé sans erreur.
- [x] `kubectl get nodes -L node.kubernetes.io/instance-type` → 2 nœuds **Ready**, `m7i-flex.large`.
- [ ] 📸 `A3-Q1_kubectl-get-nodes-m7i-flex` — **pas encore capturé** (à refaire lundi après le nouvel
      `apply`, plus simple que de flouter l'Account ID sur une sortie déjà passée).

> ⚠️ **Vigilance ECF (à ne pas perdre) :** A3-Q1 dit « connectez-le **au** Kubernetes » — l'article défini
> renvoie au cluster IaC déjà noté en A1-Q1. Rester sur EKS (comme fait ici) préserve cette continuité.
> Un repli vers un k8s local (kind/minikube) aurait cassé ce lien — dégradé au rang de **dernier recours
> uniquement**, voir *Plans de repli* en bas (mis à jour).

---

## 🛑 Fin de session dimanche — destroy AVANT de fermer

Seule l'Étape 1 est faite (nœuds nus, rien d'ELK dessus, rien à perdre). Le cluster **tourne et facture**
tant qu'il n'est pas détruit — pas de raison de le laisser tourner cette nuit.

- [x] `cd terraform/eks && terraform destroy`
- [x] Vérifs vides : `terraform state list` · `aws eks list-clusters --region eu-west-3`
      · `aws ec2 describe-nat-gateways --region eu-west-3 --filter "Name=state,Values=available"`
      — les trois confirmés vides.
- [x] Commit Git de cette checklist + des fichiers touchés aujourd'hui (`terraform.tfvars`, `RUNBOOK.md`,
      `k8s/elk/`, `A3-Q1_synthese.md`).

Lundi : reprise directe à l'**Étape 2**, après un nouveau `terraform apply` (~15-20 min, même config,
plus d'investigation à refaire).

---

## Étape 2 — Installer l'opérateur ECK (🔴 ~15 min)

Version retenue dim 12 juil : **ECK `3.4.1`** / Stack **`9.4.3`** (voir note Étape 0 — pairing à
confirmer par les logs de l'opérateur, pas par une source doc officielle).

- [ ] `kubectl create -f https://download.elastic.co/downloads/eck/3.4.1/crds.yaml`
- [ ] `kubectl apply -f https://download.elastic.co/downloads/eck/3.4.1/operator.yaml`
- [ ] `kubectl -n elastic-system get pods` → opérateur **Running**.
- [ ] Si le CR Elasticsearch (Étape 3) est rejeté pour incompatibilité de version : baisser `version:`
      dans `k8s/elk/elasticsearch.yaml` **et** `k8s/elk/filebeat.yaml` vers la dernière version `8.x`
      à la place (couple ES/Kibana 8.x + ECK 3.x reste généralement supporté en transition).

---

## Étape 3 — Déployer Elasticsearch (🔴 ~45 min)

- [ ] `kubectl apply -f k8s/elk/elasticsearch.yaml`
- [ ] `kubectl get elasticsearch -w` → `HEALTH` green/yellow, `PHASE` **Ready**.
      *(yellow = normal en single-node : réplicas non assignés. À documenter, pas un bug.)*
- [ ] Récupérer le mot de passe `elastic` :
      ```
      PW=$(kubectl get secret infoline-es-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
      ```
- [ ] Port-forward (dans un terminal dédié, à garder ouvert) :
      `kubectl port-forward service/infoline-es-es-http 9200`
- [ ] `curl -k -u elastic:$PW https://localhost:9200/_cluster/health?pretty`
- [ ] 💾 `A3-Q1_elasticsearch-health` (transcript du health).

---

## Étape 4 — Déployer Filebeat (collecteur, DaemonSet) (🔴 ~45 min)

- [ ] `kubectl apply -f k8s/elk/filebeat.yaml`
- [ ] `kubectl get pods -l beat.k8s.elastic.co/name=infoline-filebeat` → **un pod par nœud**, Running.
- [ ] Si un pod crash-loop : `kubectl logs <pod-filebeat>` (souvent RBAC ou hostPath). 
- [ ] 📸 `A3-Q1_filebeat-daemonset` (un pod Filebeat par nœud).

---

## Étape 5 — Prouver « connecté à Kubernetes » (🔴 ~30 min)

- [ ] Index créé + docs > 0 :
      `curl -k -u elastic:$PW https://localhost:9200/_cat/indices?v` → une ligne `filebeat-*` / `.ds-filebeat-*`,
      `docs.count > 0`. 💾 `A3-Q1_cat-indices`.
- [ ] Générer du log parlant : quelques `curl` sur l'ELB de l'API (`kubectl get svc infoline-api`) + `kubectl logs`.
- [ ] Retrouver ces logs dans ES (la preuve reine A3-Q1) :
      ```
      curl -k -u elastic:$PW \
        'https://localhost:9200/filebeat-*/_search?q=kubernetes.pod.name:infoline-api*&size=3&pretty'
      ```
      → doit renvoyer des lignes de log **réelles** de l'API. 💾 `A3-Q1_search-api-logs`.

**✅ Les 6 points verts (= A3-Q1 démontré) :** nœuds Ready ≥4GiB · opérateur ECK Running · ES Ready ·
1 Filebeat/nœud · index `filebeat-*` avec docs>0 · recherche `infoline-api` renvoie des logs.

---

## Étape 6 — Doc au fil de l'eau (RITUEL, non négociable) (🟢 ~50 min, peut se faire après destroy)

- [ ] `doc_project/A3-Q1_synthese.md` — remplir (Réponse / Pointeurs / Écart assumé / Conformité / Statut).
      **Écarts à assumer :** emptyDir (pas de persistance) · ECK (opérateur vs manifests bruts) · type d'instance (contrainte compte).
- [ ] `architecture.md` — remplir le stub `### Pourquoi ELK pour la supervision (logs, pas métriques)` +
      « Ce qui est réalisé » ELK + les « Pourquoi » (ECK, emptyDir, Filebeat vs Fluent Bit/Logstash, type d'instance).
- [ ] `doc_project/FRICTIONS.md` — nouvelle `## Session Lun 13 juil — Phase 4 : ELK`, numérotation à partir de **Friction 11**.
- [ ] `doc_project/backlog.md` — Phase 4 colonne Infra → **🔶**.
- [ ] `RUNBOOK.md` — démarrer section « Phase 4 — ELK » + **étendre §7 destroy** (`kubectl delete -f k8s/elk/` avant `terraform destroy`).
- [ ] Déposer les captures `A3-Q1_*` dans `doc_project/captures/` (**flouter `<ACCOUNT_ID>`**).

---

## Étape 7 — Fin de session (🔴 destroy obligatoire)

- [ ] Commit Git (livrable noté).
- [ ] `kubectl delete -f k8s/elk/`
- [ ] `cd terraform/eks && terraform destroy`
- [ ] Vérifs vides : `terraform state list` · `aws eks list-clusters --region eu-west-3`
      · `aws ec2 describe-nat-gateways --region eu-west-3 --filter "Name=state,Values=available"`
- [ ] Note : données ES (emptyDir) perdues au destroy = **normal**. Les manifests sont la source de vérité, on reconstruit J2.

---

## Aide-mémoire — les 3 pièges à ne pas oublier
1. `node.store.allow_mmap: false` dans le CRD ES → évite la friction `vm.max_map_count` sur le nœud managé.
2. Manifests ELK dans **`k8s/elk/`**, jamais `k8s/` (sinon la CI les auto-applique) — et un `git push`
   qui touche `k8s/elk/*.yaml` déclenche quand même le workflow (`paths-ignore` ne couvre que `**.md` et
   `doc_project/**`) : taguer `[skip ci]` tout commit de prépa tant que rien n'est censé se déployer.
3. ES et Filebeat = **même version** (`9.4.3` actuellement dans les deux manifests) — pairing ECK 3.4.1
   ↔ Stack 9.4.3 non confirmé par une doc officielle fraîche, **à valider par les logs de l'opérateur**
   à l'Étape 2/3 lundi (repli documenté : dernière version `8.x` si rejet).

---

## Plans de repli — risque type d'instance RÉSOLU, section gardée pour mémoire

Le blocage est levé (`m7i-flex.large`, Étape 1 ✅). Les plans ci-dessous ne sont plus nécessaires pour ce
risque précis, gardés au cas où un **nouveau** blocage surgirait (ex. capacité `m7i-flex.large`
insuffisante dans l'AZ, quota atteint) :

- **Plan C (dégradé, dernier recours EKS)** — si `m7i-flex.large`/`c7i-flex.large` devenaient indisponibles :
  retester `describe-instance-types --filters free-tier-eligible` (la liste peut évoluer), sinon ES en
  configuration très serrée sur les types micro/small restants. Reste **sur EKS**.
- **Plan D (k8s local, DERNIER recours seulement — pas une option confortable)** — démontrer ELK sur un
  cluster local (kind/minikube) **casse la continuité avec le cluster IaC noté en A1-Q1** que A3-Q1
  référence explicitement (« connectez-le **au** Kubernetes » = celui déjà construit). À n'envisager que
  si EKS devient totalement injoignable avant la deadline, et à documenter comme un écart majeur assumé
  (pas comme une solution équivalente).
- Ce genre de risque est prévu pour être absorbé par la **journée tampon (Jeu 16 juil)** si besoin.

---

## Manifests — écrits, pas encore appliqués

Les templates qui vivaient ici sont maintenant les **vrais fichiers** (versions substituées, `9.4.3`) :
- `k8s/elk/elasticsearch.yaml`
- `k8s/elk/filebeat.yaml`

Ce sont eux la source de vérité désormais — ne pas les recopier ici en double (risque de divergence).
Pas encore testés sur cluster live : à valider Étapes 3-4 lundi.
