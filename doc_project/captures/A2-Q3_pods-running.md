julien@Julien:~/infoline-devops$ kubectl apply -f k8s/api-deployment.yaml
deployment.apps/infoline-api created
julien@Julien:~/infoline-devops$ kubectl get pods -w
NAME                            READY   STATUS              RESTARTS   AGE
infoline-api-76987f66dd-2cwqz   0/1     ContainerCreating   0          12s
infoline-api-76987f66dd-lcftg   0/1     Running             0          12s
infoline-api-76987f66dd-2cwqz   0/1     Running             0          15s
infoline-api-76987f66dd-lcftg   1/1     Running             0          27s
infoline-api-76987f66dd-2cwqz   1/1     Running             0          36s