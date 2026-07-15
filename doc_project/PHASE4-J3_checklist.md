# Phase 4 — Jour 3 : checklist d'exécution (Consolidation — dashboard + scénario d'incident)

> Document de travail perso (pas un livrable ECF). Coche au fur et à mesure.
> Plan détaillé + « pourquoi » : `~/.claude/plans/j-attaque-la-phase-4-soft-quasar.md` (section Jour 3).
>
> **Objectif du jour :** produire des logs applicatifs réels, un **dashboard Kibana minimal**, et **boucler
> l'observabilité** — un dysfonctionnement visible dans Kibana = la « notification » demandée par InfoLine.
> **Décision actée :** incident = **déploiement cassé** (crash au démarrage, zéro modif code, rollback).
>
> **Légende :** 🟢 offline, gratuit · 🔴 cluster live, **facturé**.
>
> ⚠️ **Nouveau ce jour : l'API redéployée crée un Service LoadBalancer (ELB).** `kubectl delete -f k8s/`
> est **obligatoire avant** `terraform destroy` (ELB hors IaC — sinon orphelin qui bloque la suppression du VPC).

---

## Étape 0 — Préparation offline (🟢)
- [x] Relire le topo J3 : recherche réactive → dashboard proactif · signal vs bruit (baseline) · boucle
      émettre→…→remarquer→agir · log > métrique · incident = exploitation, pas bug métier.
- [x] Aucun manifeste neuf : on réutilise `k8s/api-deployment.yaml` + `k8s/api-service.yaml` (Phase 3).

---

## Étape 1 — Réveil + reconstruction ELK complète (🔴 ~40 min)
Cluster détruit → reconstruire ES + Filebeat + **Kibana**. Suivre `RUNBOOK.md` §2.4 puis §4bis.
- [x] `cd terraform/eks && terraform apply` (~15-20 min) ; `aws eks update-kubeconfig --region eu-west-3 --name infoline-eks`.
- [x] ECK : `kubectl create -f https://download.elastic.co/downloads/eck/3.4.1/crds.yaml`
      puis `kubectl apply -f https://download.elastic.co/downloads/eck/3.4.1/operator.yaml`.
- [x] `kubectl apply -f k8s/elk/elasticsearch.yaml` → Ready ; `kubectl apply -f k8s/elk/filebeat.yaml` → beat green.
- [x] `kubectl apply -f k8s/elk/kibana.yaml` → `kubectl get kibana` green.
- [x] Port-forward Kibana (terminal dédié) : `kubectl port-forward service/infoline-kibana-kb-http 5601`.

---

## Étape 2 — Déployer l'API + état sain (baseline) (🔴 ~30 min)
- [x] Construire la référence ECR (sans coder l'Account ID en dur) :
      ```bash
      ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
      IMAGE="$ACCOUNT_ID.dkr.ecr.eu-west-3.amazonaws.com/infoline-api:0d0207f"
      ```
- [x] Déployer (substitution du placeholder + service), cf. RUNBOOK §4 :
      ```bash
      sed "s|IMAGE_PLACEHOLDER|$IMAGE|" k8s/api-deployment.yaml | kubectl apply -f -
      kubectl apply -f k8s/api-service.yaml
      ```
- [x] Attendre les 2 pods : `kubectl get pods -l app=infoline-api` → `2/2 Running`.
- [x] Récupérer l'ELB + tester (l'ELB met 1-2 min à répondre) :
      ```bash
      ELB=$(kubectl get svc infoline-api -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
      curl http://$ELB/hello        # → Hello from InfoLine API (état SAIN)
      ```
- [x] Générer un peu de trafic baseline : `for i in $(seq 1 20); do curl -s -w "\n" http://$ELB/hello; done`.
- [x] 📸 `A3-consolidation_api-healthy` (pods Running + curl 200).

---

## Étape 3 — Dashboard Kibana minimal (🔴 ~50 min)
Dans Kibana (`https://localhost:5601`) : **☰ → Dashboard → Create a dashboard**. Ajouter des panneaux basés
sur la data view `filebeat-*` (bouton **Create visualization**, type **Bar/Area** ou **Metric**) :
- [ ] **Panneau 1 — Volume de logs dans le temps** : axe X = `@timestamp` (Date histogram), axe Y = Count.
      C'est le « pouls » du cluster.
- [ ] **Panneau 2 — Répartition par pod** : Count, décomposé par `kubernetes.pod.name` (Top 10). Voir qui parle.
- [ ] **Panneau 3 — Compteur d'erreurs** : type Metric, filtre `message : "WARN" or message : "ERROR"`.
- [ ] *(option)* **Panneau 4** : une recherche sauvegardée filtrée sur `kubernetes.pod.name : infoline-api*`.
- [ ] **Save** le dashboard → nom « InfoLine — Supervision ELK ».
- [ ] 📸 `A3-consolidation_dashboard-baseline` (état normal, avant incident).

---

## Étape 4 — Provoquer l'incident (déploiement cassé) (🔴 ~30 min)
- [ ] Injecter la panne (variable d'env invalide → Spring Boot échoue à binder `server.port`) :
      ```bash
      kubectl set env deployment/infoline-api SERVER_PORT=notanumber
      ```
- [ ] Observer le crash : `kubectl get pods -l app=infoline-api -w`
      → nouveau(x) pod(s) en **CrashLoopBackOff** / **Error** (⚠️ `Ctrl+C` pour sortir du watch).
- [ ] Confirmer que l'erreur est **loggée** (donc collectée par Filebeat) :
      ```bash
      POD=$(kubectl get pods -l app=infoline-api --field-selector=status.phase!=Running -o jsonpath='{.items[0].metadata.name}')
      kubectl logs "$POD" --previous 2>/dev/null || kubectl logs "$POD"
      ```
      → doit montrer l'exception de démarrage (`Failed to bind properties under 'server.port'` / stack trace).
- [ ] 📸 `A3-consolidation_incident-pods` (CrashLoopBackOff) + `A3-consolidation_incident-logs` (l'exception).

> Note : avec `maxSurge: 0 / maxUnavailable: 1`, un ancien pod peut continuer à servir → l'app est
> **dégradée** (pas forcément 100 % down). Peu importe : la **preuve** est la stack trace du pod qui crash,
> visible dans Kibana. C'est ça, le « dysfonctionnement visible ».

---

## Étape 5 — Détecter dans Kibana (le livrable-reine) (🔴 ~30 min)
- [ ] **Rafraîchir le dashboard** (time picker « Last 15 minutes », Refresh) → le pic d'erreurs / l'activité
      anormale du pod API apparaît. 📸 `A3-consolidation_dashboard-incident`.
- [ ] **Discover** → requête ciblée sur l'incident :
      ```
      kubernetes.pod.name : infoline-api* and message : "ERROR"
      ```
      (ou recherche plein-texte `message : "server.port"`) → retrouve la stack trace de crash.
- [ ] 📸 `A3-consolidation_incident-kibana` (colonnes réduites, **Account ID non visible**).
      **→ Un dysfonctionnement réel, repéré dans Kibana sans le chercher = la « notification » InfoLine.** ✅

---

## Étape 6 — Résoudre l'incident (fermer la boucle) (🔴 ~15 min)
- [ ] Rollback : `kubectl rollout undo deployment/infoline-api` (ou `kubectl set env deployment/infoline-api SERVER_PORT-`).
- [ ] `kubectl get pods -l app=infoline-api` → `2/2 Running` ; `curl http://$ELB/hello` → 200 rétabli.
- [ ] *(option)* 📸 `A3-consolidation_recovery` (retour à la normale — détecter **puis agir**).

---

## Étape 7 — Doc au fil de l'eau (RITUEL) (🟢 ~40 min)
- [ ] `doc_project/A3-Q2_synthese.md` — ajouter une section **« Consolidation (J3) — dashboard + scénario de
      détection d'incident »** : le dashboard (3 panneaux), le récit incident → détection Kibana → résolution.
- [ ] `doc_project/backlog.md` — ligne consolidation J3 → ✅ + narratif Mer 15 juil.
- [ ] `doc_project/FRICTIONS.md` — friction éventuelle (sinon « aucune friction bloquante »).
- [ ] Captures `A3-consolidation_*` déposées et **PNG vérifiés** (Account ID non visible dans dashboard/Discover).

---

## Étape 8 — Fin de session (🔴 destroy) — ⚠️ ordre important
- [ ] **`kubectl delete -f k8s/`** ← **l'API + son ELB** (obligatoire avant destroy, sinon ELB orphelin).
- [ ] *(option)* `kubectl delete -f k8s/elk/` (ELK n'a pas d'ELB, mais nettoyage propre).
- [ ] `cd terraform/eks && terraform destroy`.
- [ ] Vérifs vides : `terraform state list` · `aws eks list-clusters --region eu-west-3`
      · `aws ec2 describe-nat-gateways --region eu-west-3 --filter "Name=state,Values=available"`
      · **`aws elb describe-load-balancers --region eu-west-3 --query 'LoadBalancerDescriptions[].LoadBalancerName'`** (aucun ELB orphelin).
- [ ] Commit `[skip ci]` (doc + captures ; aucun manifeste modifié → doc-only, mais `[skip ci]` par cohérence).

---

## ⚠️ Pièges du jour
1. **ELB de l'API** : `kubectl delete -f k8s/` AVANT `terraform destroy` (le seul vrai risque d'orphelin).
2. **Floutage images** : dashboard et Discover exposent `cloud.account.id` → colonnes réduites + vérif visuelle des PNG.
3. **`kubectl logs --previous`** : un pod en CrashLoop a déjà redémarré → utiliser `--previous` pour voir l'erreur.
4. **watch `-w`** : `Ctrl+C` avant d'enchaîner (réflexe des jours précédents).

---

## Vérification (consolidation A3 démontrée)
1. `curl http://<elb>/hello` = 200 avant incident (baseline saine).
2. Dashboard sauvegardé, ≥ 3 panneaux, état baseline capturé.
3. Incident : `kubectl get pods` → CrashLoopBackOff ; `kubectl logs --previous` → stack trace.
4. **Visible dans Kibana** : dashboard montre le pic + Discover retrouve la stack trace du pod API.
5. Résolu : rollback → `curl /hello` = 200.
6. Scénario documenté (détecter → agir) + captures floutées.
