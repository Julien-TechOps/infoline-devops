julien@Julien:~/infoline-devops$ kubectl get kibana infoline-kibana
NAME              HEALTH   NODES   VERSION   AGE
infoline-kibana   green    1       9.4.3     111m
julien@Julien:~/infoline-devops$ kubectl get pods -l kibana.k8s.elastic.co/name=infoline-kibana
NAME                                  READY   STATUS    RESTARTS   AGE
infoline-kibana-kb-69576cf466-9wmr6   1/1     Running   0          112m