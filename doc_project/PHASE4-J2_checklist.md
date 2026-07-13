# Phase 4 — Jour 2 : checklist d'exécution (A3-Q2 — Kibana + requêtes KQL)

> Document de travail perso (pas un livrable ECF). Coche au fur et à mesure.
> Plan détaillé + « pourquoi » : `~/.claude/plans/j-attaque-la-phase-4-soft-quasar.md` (section Jour 2).
>
> **Objectif du jour :** Kibana connecté à Elasticsearch + data view `filebeat-*` + plusieurs requêtes KQL
> commentées + captures. **Décisions actées :** accès **port-forward** (pas de LoadBalancer) · **périmètre J2
> seul** (KQL sur les logs existants ; API + scénario d'incident = J3).
>
> **Légende :** 🟢 offline, gratuit · 🔴 cluster live, **facturé** (destroy en fin de session).
>
> **Frontière assumée (à documenter) :** login = **Lambda/CloudWatch**, hors ELK (Filebeat ne collecte que
> les logs des pods K8s). Latence = filtrage par **fenêtre temporelle** faute de log applicatif (hello-world).

---

## Étape 0 — Préparation offline (🟢 fait à l'avance)

- [x] Manifest **`k8s/elk/kibana.yaml`** écrit (CRD Kibana ECK, `version 9.4.3`, `elasticsearchRef: infoline-es`).
- [x] Squelette **`doc_project/A3-Q2_synthese.md`** créé.
- [x] (Facultatif) Relire le topo J2 : Kibana = UI sur ES · data view = glob + champ temps · KQL = `champ : valeur`.

---

## Étape 1 — Réveil du cluster + reconstruction ELK (🔴 ~35 min)

Le cluster est détruit (fin J1) → on reconstruit la stack A3-Q1 avant d'ajouter Kibana. Suivre `RUNBOOK.md`
§2.4 puis §4bis (déjà validé J1). Pas besoin de re-capturer A3-Q1.

- [x] `cd terraform/eks && terraform apply` (~15-20 min ; config `m7i-flex.large` déjà en place).
- [x] `aws eks update-kubeconfig --region eu-west-3 --name infoline-eks` ; `kubectl get nodes` → 2× Ready.
- [x] ECK : `kubectl create -f https://download.elastic.co/downloads/eck/3.4.1/crds.yaml`
      puis `kubectl apply -f https://download.elastic.co/downloads/eck/3.4.1/operator.yaml`.
- [x] `kubectl apply -f k8s/elk/elasticsearch.yaml` → `kubectl get elasticsearch` Ready.
- [x] `kubectl apply -f k8s/elk/filebeat.yaml` → `kubectl get beat` green (2/2).

---

## Étape 2 — Déployer Kibana (🔴 ~30 min)

- [x] `kubectl apply -f k8s/elk/kibana.yaml`
- [x] `kubectl get kibana -w` → `HEALTH green` (⏳ l'init prend quelques min : `red`/`yellow` transitoire = normal ;
      **`Ctrl+C`** pour sortir du watch avant de continuer). 💾 `A3-Q2_kibana-ready.md`.

---

## Étape 3 — Accéder à Kibana + se connecter (🔴 ~15 min)

- [x] Terminal dédié : `kubectl port-forward service/infoline-kibana-kb-http 5601` (bloquant, laisser ouvert).
- [x] Navigateur : `https://localhost:5601` → avertissement certificat auto-signé → « Proceed ».
- [x] Login **`elastic`** / mot de passe :
      `kubectl get secret infoline-es-es-elastic-user -o go-template='{{.data.elastic | base64decode}}'`
- [x] 📸 `A3-Q2_kibana-home` (page d'accueil connectée).

---

## Étape 4 — Créer la data view `filebeat-*` (🔴 ~15 min)

- [x] **Stack Management → Data Views → Create data view** : pattern `filebeat-*`, champ temps `@timestamp`.
- [x] Ouvrir **Discover** → les logs s'affichent avec l'histogramme temporel.
- [x] 📸 `A3-Q2_data-view` + `A3-Q2_discover`.
- [x] **Réduire les colonnes affichées** à `@timestamp`, `log.level`, `kubernetes.pod.name`, `message`
      → évite d'afficher `cloud.account.id` dans les captures suivantes (voir ⚠️ floutage en bas).

---

## Étape 5 — Requêtes KQL commentées (🔴 ~60 min) — cœur d'A3-Q2

Pour **chaque** requête : taper dans Discover, capturer (📸), et écrire **1 phrase** de commentaire (ce
qu'elle répond / en quoi elle sert la supervision). Jeu proposé (adapter aux logs présents) :

- [x] `message : "WARN" or message : "ERROR"` → anomalies tous pods confondus (champ réellement alimenté). 📸 `A3-Q2_kql-errors`.
- [x] `message : "certificate_unknown"` → recherche plein-texte d'un incident concret (rejets TLS). 📸 `A3-Q2_kql-certificate`.
- [x] `kubernetes.namespace : "kube-system"` → logs des composants système. 📸 `A3-Q2_kql-namespace`.
- [x] `kubernetes.pod.name : infoline-es*` → cibler un service précis (ES lui-même). 📸 `A3-Q2_kql-pod`.
- [x] `stream : "stderr"` → flux d'erreur des conteneurs. 📸 `A3-Q2_kql-stderr`.
- [x] `kubernetes.namespace : "kube-system" and stream : "stderr"` → combiner deux critères (ET). 📸 `A3-Q2_kql-combined`.
- [x] **Temporel/latence** : jouer avec le **time picker** (fenêtre bornée) ; commenter que l'axe
      temporel remplace un champ de latence (apps triviales sans log de temps de réponse). 📸 `A3-Q2_kql-timewindow`.
- [x] **Login** : pas de capture ELK — noté dans la synthèse : logs côté Lambda/CloudWatch.

---

## Étape 6 — Doc au fil de l'eau (RITUEL) (🟢 ~45 min, possible après destroy)

- [x] `doc_project/A3-Q2_synthese.md` — remplir (Kibana connecté, data view, KQL commentées, écarts assumés).
- [x] `architecture.md` — section « Supervision par les logs — ELK » : ajouter Kibana à « Ce qui est réalisé »
      + « Pourquoi port-forward plutôt que LoadBalancer pour Kibana ».
- [x] `doc_project/backlog.md` — ligne **A3-Q2 → ✅** + narratif Lun 13 juil (réalisé en avance).
- [x] `doc_project/FRICTIONS.md` — friction Filebeat 9.x consignée.
- [x] `RUNBOOK.md` — §4bis : étape Kibana (apply + port-forward 5601) ; §7 : Kibana port-forward = pas d'ELB.
- [x] Captures `A3-Q2_*` déposées et **PNG vérifiés** (Account ID non visible).

---

## Étape 7 — Fin de session (🔴 destroy)

- [ ] Commit `[skip ci]` — ⚠️ `k8s/elk/kibana.yaml` **n'est pas** couvert par `paths-ignore` → sans `[skip ci]`
      le push déclencherait le pipeline API contre le cluster.
- [ ] `cd terraform/eks && terraform destroy` (Kibana en port-forward → **pas d'ELB** à supprimer, `destroy` seul suffit).
- [ ] Vérifs vides : `terraform state list` · `aws eks list-clusters --region eu-west-3` · NAT gateways.

---

## ⚠️ Floutage dans les captures Kibana (piège spécifique J2)
Les documents Discover contiennent `cloud.account.id` et l'ARN `orchestrator.cluster.id` (**Account ID**).
Le grep ne détecte **pas** un ID dans une image → vérifier chaque PNG à l'œil. Deux parades :
1. Réduire les colonnes Discover (Étape 4) pour que l'Account ID n'apparaisse jamais à l'écran.
2. Sinon, flouter la zone sur la capture avant de la déposer.

---

## Vérification (A3-Q2 démontré)
1. `kubectl get kibana` → `HEALTH green`.
2. `https://localhost:5601` → connexion `elastic` OK.
3. Data view `filebeat-*` créée ; Discover affiche les logs.
4. Plusieurs requêtes KQL exécutées + **commentées** (1 capture/requête).
5. Écarts documentés (login = Lambda/CloudWatch ; latence = fenêtre temporelle ; accès port-forward).
