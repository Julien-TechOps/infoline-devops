julien@Julien:~/infoline-devops$ kubectl apply -f k8s/elk/filebeat.yaml
serviceaccount/filebeat created
clusterrole.rbac.authorization.k8s.io/filebeat created
clusterrolebinding.rbac.authorization.k8s.io/filebeat created
beat.beat.k8s.elastic.co/infoline-filebeat created

julien@Julien:~/infoline-devops$ kubectl get beat
NAME                HEALTH   AVAILABLE   EXPECTED   TYPE       VERSION   AGE
infoline-filebeat   green    2           2          filebeat   9.4.3     17s

julien@Julien:~/infoline-devops$ kubectl get pods -l beat.k8s.elastic.co/name=infoline-filebeat -o wide
NAME                                    READY   STATUS    RESTARTS   AGE   IP           NODE                                       NOMINATED NODE   READINESS GATES
infoline-filebeat-beat-filebeat-9vj57   1/1     Running   0          97s   10.0.1.100   ip-10-0-1-100.eu-west-3.compute.internal   <none>           <none>
infoline-filebeat-beat-filebeat-fbds4   1/1     Running   0          97s   10.0.2.43    ip-10-0-2-43.eu-west-3.compute.internal    <none>           <none>