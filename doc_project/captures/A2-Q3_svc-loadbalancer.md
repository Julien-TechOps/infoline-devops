julien@Julien:~/infoline-devops$ kubectl apply -f k8s/api-service.yaml
service/infoline-api created
julien@Julien:~/infoline-devops$ kubectl get endpoints infoline-api
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME           ENDPOINTS                         AGE
infoline-api   10.0.2.156:8080,10.0.2.209:8080   11s
julien@Julien:~/infoline-devops$ kubectl get svc infoline-api -w
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP                                                             PORT(S)        AGE
infoline-api   LoadBalancer   172.20.149.18   a4551f357b9c24ff2a2756dbe8273a19-31972297.eu-west-3.elb.amazonaws.com   80:32284/TCP   47s