julien@Julien:~/infoline-devops$ curl -k --max-time 10 -u elastic:$PW "https://localhost:9200/filebeat-*/_search?q=kubernetes.pod.name:infoline-es*&size=1&pretty"
{
  "took" : 9,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 544,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : ".ds-filebeat-9.4.3-2026.07.13-000001",
        "_id" : "w8VtWp8BpOzRuRnXV2yc",
        "_score" : 1.0,
        "_source" : {
          "container" : {
            "image" : {
              "name" : "docker.elastic.co/elasticsearch/elasticsearch:9.4.3"
            },
            "runtime" : "containerd",
            "id" : "39016a2f85c1db7bfc2b40930e8c2a21fd811db590f9430523fc318456dfdaf4"
          },
          "kubernetes" : {
            "container" : {
              "name" : "elasticsearch"
            },
            "node" : {
              "uid" : "33279a6f-2362-4780-80df-cd746e310787",
              "hostname" : "ip-10-0-1-100.eu-west-3.compute.internal",
              "name" : "ip-10-0-1-100.eu-west-3.compute.internal",
              "labels" : {
                "kubernetes_io/hostname" : "ip-10-0-1-100.eu-west-3.compute.internal",
                "topology_kubernetes_io/region" : "eu-west-3",
                "topology_kubernetes_io/zone" : "eu-west-3a",
                "kubernetes_io/arch" : "amd64",
                "failure-domain_beta_kubernetes_io/region" : "eu-west-3",
                "topology_k8s_aws/zone-id" : "euw3-az1",
                "k8s_io/cloud-provider-aws" : "510295eb5801c51df687473f9980304a",
                "eks_amazonaws_com/sourceLaunchTemplateVersion" : "1",
                "beta_kubernetes_io/instance-type" : "m7i-flex.large",
                "eks_amazonaws_com/nodegroup-image" : "ami-0691414b289e5459b",
                "eks_amazonaws_com/capacityType" : "ON_DEMAND",
                "eks_amazonaws_com/nodegroup" : "main-20260713070040289100000013",
                "failure-domain_beta_kubernetes_io/zone" : "eu-west-3a",
                "node_kubernetes_io/instance-type" : "m7i-flex.large",
                "eks_amazonaws_com/sourceLaunchTemplateId" : "lt-0a2db1b2f5d757558",
                "beta_kubernetes_io/os" : "linux",
                "kubernetes_io/os" : "linux",
                "beta_kubernetes_io/arch" : "amd64"
              }
            },
            "pod" : {
              "uid" : "66b48be4-36ce-474f-a5f0-544b41400156",
              "ip" : "10.0.1.182",
              "name" : "infoline-es-es-default-0"
            },
            "statefulset" : {
              "name" : "infoline-es-es-default"
            },
            "namespace" : "default",
            "namespace_uid" : "10770f09-1ac2-4bee-8ba3-bc9050713982",
            "namespace_labels" : {
              "kubernetes_io/metadata_name" : "default"
            },
            "labels" : {
              "elasticsearch_k8s_elastic_co/node-data_hot" : "true",
              "elasticsearch_k8s_elastic_co/node-data_content" : "true",
              "elasticsearch_k8s_elastic_co/node-voting_only" : "false",
              "elasticsearch_k8s_elastic_co/node-data_frozen" : "true",
              "apps_kubernetes_io/pod-index" : "0",
              "controller-revision-hash" : "infoline-es-es-default-76f45bd948",
              "elasticsearch_k8s_elastic_co/node-data" : "true",
              "elasticsearch_k8s_elastic_co/node-ingest" : "true",
              "elasticsearch_k8s_elastic_co/node-remote_cluster_client" : "true",
              "elasticsearch_k8s_elastic_co/cluster-name" : "infoline-es",
              "elasticsearch_k8s_elastic_co/node-data_warm" : "true",
              "elasticsearch_k8s_elastic_co/statefulset-name" : "infoline-es-es-default",
              "common_k8s_elastic_co/type" : "elasticsearch",
              "elasticsearch_k8s_elastic_co/node-data_cold" : "true",
              "elasticsearch_k8s_elastic_co/node-ml" : "true",
              "elasticsearch_k8s_elastic_co/node-master" : "true",
              "elasticsearch_k8s_elastic_co/http-scheme" : "https",
              "elasticsearch_k8s_elastic_co/node-transform" : "true",
              "elasticsearch_k8s_elastic_co/version" : "9.4.3",
              "statefulset_kubernetes_io/pod-name" : "infoline-es-es-default-0"
            }
          },
          "agent" : {
            "name" : "ip-10-0-1-100.eu-west-3.compute.internal",
            "id" : "2c153efb-033c-4dc3-8981-f873d7310f5d",
            "type" : "filebeat",
            "ephemeral_id" : "ee76a837-39a3-493e-8dc2-98be19657ad0",
            "version" : "9.4.3"
          },
          "process" : {
            "thread" : {
              "name" : "elasticsearch[infoline-es-es-default-0][generic][T#17]"
            }
          },
          "log" : {
            "file" : {
              "path" : "/var/log/containers/infoline-es-es-default-0_default_elasticsearch-39016a2f85c1db7bfc2b40930e8c2a21fd811db590f9430523fc318456dfdaf4.log"
            },
            "offset" : 242705,
            "level" : "INFO",
            "logger" : "org.elasticsearch.xpack.security.authc.file.FileUserPasswdStore"
          },
          "message" : "users file [/usr/share/elasticsearch/config/users] changed. updating users...",
          "fileset" : {
            "name" : "server"
          },
          "cloud" : {
            "availability_zone" : "eu-west-3a",
            "image" : {
              "id" : "ami-0691414b289e5459b"
            },
            "instance" : {
              "id" : "i-02dd2b91d5734578b"
            },
            "provider" : "aws",
            "machine" : {
              "type" : "m7i-flex.large"
            },
            "service" : {
              "name" : "EC2"
            },
            "region" : "eu-west-3",
            "account" : {
              "id" : <ACCOUNT_ID>
            }
          },
          "input" : {
            "type" : "container"
          },
          "orchestrator" : {
            "cluster" : {
              "name" : "infoline-eks",
              "id" : "arn:aws:eks:eu-west-3:<ACCOUNT_ID>:cluster/infoline-eks"
            }
          },
          "@timestamp" : "2026-07-13T07:41:14.055Z",
          "ecs" : {
            "version" : "1.2.0"
          },
          "elasticsearch" : {
            "server" : {
              "process" : {
                "thread" : { }
              },
              "ecs" : { },
              "elasticsearch" : {
                "cluster" : { },
                "node" : { }
              },
              "log" : { },
              "service" : { },
              "event" : { }
            },
            "cluster" : {
              "name" : "infoline-es",
              "uuid" : "LLLbn1O8TVSnMp74Egn2TA"
            },
            "node" : {
              "name" : "infoline-es-es-default-0",
              "id" : "wvZKjICiTeKD1xGA_gmbmg"
            }
          },
          "stream" : "stdout",
          "service" : {
            "name" : "ES_ECS",
            "type" : "elasticsearch"
          },
          "host" : {
            "hostname" : "ip-10-0-1-100.eu-west-3.compute.internal",
            "os" : {
              "kernel" : "6.12.90-120.164.amzn2023.x86_64",
              "codename" : "Coughlan",
              "name" : "Red Hat Enterprise Linux",
              "family" : "redhat",
              "type" : "linux",
              "version" : "10.2 (Coughlan)",
              "platform" : "rhel"
            },
            "containerized" : false,
            "ip" : [
              "10.0.1.100",
              "fe80::406:c5ff:fe62:db35",
              "fe80::1043:12ff:fe65:b8e6",
              "10.0.1.144",
              "fe80::404:8fff:fe11:3833",
              "fe80::6846:6fff:fe26:67c"
            ],
            "name" : "infoline-es-es-default-0",
            "id" : "wvZKjICiTeKD1xGA_gmbmg",
            "mac" : [
              "06-04-8F-11-38-33",
              "06-06-C5-62-DB-35",
              "12-43-12-65-B8-E6",
              "6A-46-6F-26-06-7C"
            ],
            "architecture" : "x86_64"
          },
          "aws" : {
            "tags" : {
              "eks:cluster-name" : "infoline-eks"
            }
          },
          "event" : {
            "ingested" : "2026-07-13T07:42:23.075697940Z",
            "created" : "2026-07-13T07:41:14.056Z",
            "kind" : "event",
            "module" : "elasticsearch",
            "category" : "database",
            "type" : "info",
            "dataset" : "elasticsearch.server"
          }
        }
      }
    ]
  }
}