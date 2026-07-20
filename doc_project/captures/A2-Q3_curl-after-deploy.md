julien@Julien:~/infoline-devops$ kubectl get svc infoline-api
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
infoline-api   LoadBalancer   172.20.80.126   <ELB_DNS>     80:31746/TCP   56m
julien@Julien:~/infoline-devops$ curl http://<ELB_DNS>/hello
Hello from InfoLine API