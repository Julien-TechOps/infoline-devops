julien@Julien:~/infoline-devops$ kubectl get pods -l app=infoline-api -w
NAME                            READY   STATUS             RESTARTS         AGE
infoline-api-78b6f764f8-kd4qq   0/1     CrashLoopBackOff   10 (4m29s ago)   32m
infoline-api-955fc7c6-xqd5v     1/1     Running            0                124m
^Cjulien@Julien:~/infoline-devopskubectl rollout undo deployment/infoline-apipi
Warning: resource deployments/infoline-api was previously managed with 'kubectl apply'. Rolling back will not update the kubectl.kubernetes.io/last-applied-configuration annotation, which may cause unexpected behavior on future 'kubectl apply' operations. Consider using 'kubectl apply' with your previous configuration file instead.
deployment.apps/infoline-api rolled back
julien@Julien:~/infoline-devops$ kubectl get pods -l app=infoline-api
NAME                          READY   STATUS    RESTARTS   AGE
infoline-api-955fc7c6-d8g2w   0/1     Running   0          17s
infoline-api-955fc7c6-xqd5v   1/1     Running   0          125m
julien@Julien:~/infoline-devops$ kubectl get pods -l app=infoline-api
NAME                          READY   STATUS    RESTARTS   AGE
infoline-api-955fc7c6-d8g2w   1/1     Running   0          28s
infoline-api-955fc7c6-xqd5v   1/1     Running   0          125m
julien@Julien:~/infoline-devops$ curl http://$ELB/hello