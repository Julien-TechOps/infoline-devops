julien@Julien:~/infoline-devops$ curl -k -u elastic:$PW "https://localhost:9200/_cat/indices/filebeat-*?v"
health status index                                uuid                   pri rep docs.count docs.deleted store.size pri.store.size dataset.size
yellow open   .ds-filebeat-9.4.3-2026.07.13-000001 LU5pSM3eQ0eWwqj0U0BBaQ   1   1       1290            0      1.5mb          1.5mb        1.5mb
julien@Julien:~/infoline-devops$ curl -k -u elastic:$PW "https://localhost:9200/filebeat-*/_count?pretty"
{
  "count" : 1290,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  }
}