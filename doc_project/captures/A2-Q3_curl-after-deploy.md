julien@Julien:~/infoline-devops$ kubectl get svc infoline-api
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)        AGE
infoline-api   LoadBalancer   172.20.80.126   a743fbab6f0c049bf88f51eaaa08c2b5-228662540.eu-west-3.elb.amazonaws.com   80:31746/TCP   56m
julien@Julien:~/infoline-devops$ curl http://a743fbab6f0c049bf88f51eaaa08c2b5-228662540.eu-west-3.elb.amazonaws.com/hello
Hello from InfoLine API