julien@Julien:~/infoline-devops$ kubectl set env deployment/infoline-api SERVER_PORT=notanumber
deployment.apps/infoline-api env updated
julien@Julien:~/infoline-devops$ kubectl get pods -l app=infoline-api -w
NAME                            READY   STATUS             RESTARTS      AGE
infoline-api-78b6f764f8-kd4qq   0/1     CrashLoopBackOff   1 (13s ago)   30s
infoline-api-955fc7c6-xqd5v     1/1     Running            0             92m
infoline-api-78b6f764f8-kd4qq   0/1     Running            2 (16s ago)   33s
infoline-api-78b6f764f8-kd4qq   0/1     Error              2 (24s ago)   41s