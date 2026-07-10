### AVANT — état initial

$ kubectl get pods -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP          NODE                                      NOMINATED NODE   READINESS GATES
infoline-api-5b6f7c7895-5jddz   1/1     Running   0          28m   10.0.2.5    ip-10-0-2-21.eu-west-3.compute.internal   <none>           <none>
infoline-api-5b6f7c7895-fwtrw   1/1     Running   0          28m   10.0.2.78   ip-10-0-2-21.eu-west-3.compute.internal   <none>           <none>

### PENDANT — bascule
Preuve de séquentialité : les deux pods APRÈS
ont un écart d'âge de ~58s (7m40s / 6m42s), confirmant un remplacement un pod à la fois
(`maxSurge:0`/`maxUnavailable:1`), pas simultané.

### APRÈS — rollout terminé
$ kubectl rollout status deployment/infoline-api
deployment "infoline-api" successfully rolled out

$ kubectl get pods -o wide
NAME                          READY   STATUS    RESTARTS   AGE     IP          NODE                                      NOMINATED NODE   READINESS GATES
infoline-api-955fc7c6-gfwcp   1/1     Running   0          7m40s   10.0.2.78   ip-10-0-2-21.eu-west-3.compute.internal   <none>           <none>
infoline-api-955fc7c6-s476b   1/1     Running   0          6m42s   10.0.2.5    ip-10-0-2-21.eu-west-3.compute.internal   <none>           <none>

**Hash ReplicaSet : `5b6f7c7895` → `955fc7c6`** — confirme un nouveau ReplicaSet créé et
l'ancien retiré, cohérent avec un rolling update réussi.