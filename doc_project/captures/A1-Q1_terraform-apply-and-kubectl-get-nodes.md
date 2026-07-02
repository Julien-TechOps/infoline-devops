julien@Julien:~/infoline-devops/terraform/eks$ terraform apply tfplan
module.eks.aws_iam_policy.custom[0]: Creating...
module.eks.module.eks_managed_node_group["main"].aws_iam_role.this[0]: Creating...
module.vpc.aws_vpc.this[0]: Creating...
module.eks.aws_iam_role.this[0]: Creating...
module.eks.aws_cloudwatch_log_group.this[0]: Creating...
module.eks.aws_cloudwatch_log_group.this[0]: Creation complete after 2s [id=/aws/eks/infoline-eks/cluster]
module.eks.aws_iam_policy.custom[0]: Creation complete after 8s [id=arn:aws:iam::<ACCOUNT_ID>:policy/infoline-eks-cluster-20260701053412151400000003]
module.eks.aws_iam_role.this[0]: Creation complete after 3s [id=infoline-eks-cluster-20260701053412150500000001]
module.eks.module.eks_managed_node_group["main"].aws_iam_role.this[0]: Creation complete after 3s [id=main-eks-node-group-20260701053412150700000002]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]: Creating...
module.eks.aws_iam_role_policy_attachment.custom[0]: Creating...
module.eks.module.eks_managed_node_group["main"].aws_iam_role_policy_attachment.this["AmazonEKS_CNI_Policy"]: Creating...
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]: Creating...
module.eks.module.eks_managed_node_group["main"].aws_iam_role_policy_attachment.this["AmazonEKSWorkerNodePolicy"]: Creating...
module.eks.module.eks_managed_node_group["main"].aws_iam_role_policy_attachment.this["AmazonEC2ContainerRegistryReadOnly"]: Creating...
module.eks.module.kms.data.aws_iam_policy_document.this[0]: Reading...
module.eks.module.kms.data.aws_iam_policy_document.this[0]: Read complete after 0s [id=1504297012]
module.eks.module.kms.aws_kms_key.this[0]: Creating...
module.eks.module.eks_managed_node_group["main"].aws_iam_role_policy_attachment.this["AmazonEKS_CNI_Policy"]: Creation complete after 1s [id=main-eks-node-group-20260701053412150700000002-20260701053415019800000004]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]: Creation complete after 1s [id=infoline-eks-cluster-20260701053412150500000001-20260701053415019900000005]
module.eks.aws_iam_role_policy_attachment.custom[0]: Creation complete after 1s [id=infoline-eks-cluster-20260701053412150500000001-20260701053415036100000006]
module.eks.module.eks_managed_node_group["main"].aws_iam_role_policy_attachment.this["AmazonEKSWorkerNodePolicy"]: Creation complete after 1s [id=main-eks-node-group-20260701053412150700000002-20260701053415562700000007]
module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]: Creation complete after 1s [id=infoline-eks-cluster-20260701053412150500000001-20260701053415563200000009]
module.eks.module.eks_managed_node_group["main"].aws_iam_role_policy_attachment.this["AmazonEC2ContainerRegistryReadOnly"]: Creation complete after 1s [id=main-eks-node-group-20260701053412150700000002-20260701053415563100000008]
module.vpc.aws_vpc.this[0]: Still creating... [00m09s elapsed]
module.eks.module.kms.aws_kms_key.this[0]: Still creating... [00m09s elapsed]
module.vpc.aws_vpc.this[0]: Creation complete after 15s [id=vpc-0d67d372811ba6592]
module.vpc.aws_default_security_group.this[0]: Creating...
module.vpc.aws_default_route_table.default[0]: Creating...
module.vpc.aws_route_table.public[0]: Creating...
module.vpc.aws_internet_gateway.this[0]: Creating...
module.vpc.aws_subnet.private[0]: Creating...
module.vpc.aws_subnet.private[1]: Creating...
module.vpc.aws_default_network_acl.this[0]: Creating...
module.eks.aws_security_group.cluster[0]: Creating...
module.eks.aws_security_group.node[0]: Creating...
module.vpc.aws_default_route_table.default[0]: Creation complete after 1s [id=rtb-0444b021cbb62d28a]
module.vpc.aws_subnet.public[0]: Creating...
module.vpc.aws_internet_gateway.this[0]: Creation complete after 2s [id=igw-089a072ba34cd9e7d]
module.vpc.aws_route_table.private[0]: Creating...
module.vpc.aws_route_table.public[0]: Creation complete after 2s [id=rtb-070bfcedd6058cbab]
module.vpc.aws_subnet.private[0]: Creation complete after 2s [id=subnet-0e65376cdcd987330]
module.vpc.aws_subnet.private[1]: Creation complete after 2s [id=subnet-0609a2363310c6436]
module.vpc.aws_route.public_internet_gateway[0]: Creating...
module.vpc.aws_subnet.public[1]: Creating...
module.vpc.aws_eip.nat[0]: Creating...
module.vpc.aws_subnet.public[0]: Creation complete after 1s [id=subnet-0b38f564f3cf5ef87]
module.vpc.aws_route_table.private[0]: Creation complete after 1s [id=rtb-0f0795fab986b60cd]
module.vpc.aws_route_table_association.private[1]: Creating...
module.vpc.aws_route_table_association.private[0]: Creating...
module.vpc.aws_subnet.public[1]: Creation complete after 1s [id=subnet-0d139ab8b49aeb934]
module.vpc.aws_route_table_association.public[1]: Creating...
module.vpc.aws_default_security_group.this[0]: Creation complete after 3s [id=<SG_DEFAULT_ID>]
module.vpc.aws_route_table_association.public[0]: Creating...
module.vpc.aws_eip.nat[0]: Creation complete after 1s [id=eipalloc-090ee45cb0ed9d015]
module.vpc.aws_nat_gateway.this[0]: Creating...
module.vpc.aws_default_network_acl.this[0]: Creation complete after 3s [id=acl-0df8b46af5ab84686]
module.vpc.aws_route.public_internet_gateway[0]: Creation complete after 1s [id=r-rtb-070bfcedd6058cbab1080289494]
module.vpc.aws_route_table_association.private[0]: Creation complete after 1s [id=rtbassoc-0ea08c4cc99acf13c]
module.vpc.aws_route_table_association.private[1]: Creation complete after 1s [id=rtbassoc-0f3f86a312d7de772]
module.eks.aws_security_group.cluster[0]: Creation complete after 4s [id=sg-0df0fb7b3cc17f524]
module.eks.aws_security_group.node[0]: Creation complete after 4s [id=sg-0a9b5599547c38ced]
module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"]: Creating...
module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"]: Creating...
module.eks.aws_security_group_rule.node["egress_all"]: Creating...
module.vpc.aws_route_table_association.public[1]: Creation complete after 1s [id=rtbassoc-0022f35f00afa901e]
module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"]: Creating...
module.vpc.aws_route_table_association.public[0]: Creation complete after 1s [id=rtbassoc-07d8847169b865249]
module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"]: Creation complete after 1s [id=sgrule-2732305770]
module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"]: Creating...
module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]: Creation complete after 1s [id=sgrule-477732568]
module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]: Creating...
module.eks.module.kms.aws_kms_key.this[0]: Still creating... [00m18s elapsed]
module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"]: Creation complete after 2s [id=sgrule-3576078976]
module.eks.aws_security_group_rule.node["ingress_cluster_443"]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"]: Creation complete after 9s [id=sgrule-476366102]
module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]: Creation complete after 4s [id=sgrule-220702165]
module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"]: Creation complete after 6s [id=sgrule-4170437747]
module.eks.aws_security_group_rule.node["egress_all"]: Creation complete after 7s [id=sgrule-1226588752]
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m15s elapsed]
module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"]: Creation complete after 8s [id=sgrule-734559007]
module.eks.module.kms.aws_kms_key.this[0]: Creation complete after 25s [id=0ddfaf0a-d657-4ea3-bcef-c8200364087e]
module.eks.module.kms.aws_kms_alias.this["cluster"]: Creating...
module.eks.aws_iam_policy.cluster_encryption[0]: Creating...
module.eks.module.kms.aws_kms_alias.this["cluster"]: Creation complete after 0s [id=alias/eks/infoline-eks]
module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"]: Creation complete after 9s [id=sgrule-2843215418]
module.eks.aws_iam_policy.cluster_encryption[0]: Creation complete after 1s [id=arn:aws:iam::<ACCOUNT_ID>:policy/infoline-eks-cluster-ClusterEncryption2026070105343969350000000f]
module.eks.aws_iam_role_policy_attachment.cluster_encryption[0]: Creating...
module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]: Still creating... [00m09s elapsed]
module.eks.aws_iam_role_policy_attachment.cluster_encryption[0]: Creation complete after 1s [id=infoline-eks-cluster-20260701053412150500000001-20260701053441588300000010]
module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]: Creation complete after 10s [id=sgrule-3329924769]
module.eks.aws_security_group_rule.node["ingress_cluster_443"]: Still creating... [00m09s elapsed]
module.eks.aws_security_group_rule.node["ingress_cluster_443"]: Creation complete after 11s [id=sgrule-918321311]
module.eks.aws_eks_cluster.this[0]: Creating...
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m19s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m09s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m28s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m18s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m37s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m27s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m46s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m36s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [00m55s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m45s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [01m04s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [00m54s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [01m13s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m03s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [01m22s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m12s elapsed]
module.vpc.aws_nat_gateway.this[0]: Still creating... [01m31s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m21s elapsed]
module.vpc.aws_nat_gateway.this[0]: Creation complete after 1m40s [id=nat-03e7639f6d2ff7e3a]
module.vpc.aws_route.private_nat_gateway[0]: Creating...
module.vpc.aws_route.private_nat_gateway[0]: Creation complete after 1s [id=r-rtb-0f0795fab986b60cd1080289494]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m36s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m49s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [01m58s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m07s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m16s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m25s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m34s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m43s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [02m52s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m01s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m16s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m20s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m29s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m38s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m47s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [03m56s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m06s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m14s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m24s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m33s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m42s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [04m56s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m00s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m09s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m18s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m27s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m36s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m46s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [05m55s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m04s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m13s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m22s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m37s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m40s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m49s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [06m58s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [07m07s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [07m16s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [07m26s elapsed]
module.eks.aws_eks_cluster.this[0]: Creation complete after 7m27s [id=infoline-eks]
module.eks.aws_eks_access_entry.this["cluster_creator"]: Creating...
module.eks.data.tls_certificate.this[0]: Reading...
module.eks.time_sleep.this[0]: Creating...
module.eks.data.tls_certificate.this[0]: Read complete after 1s [id=a6171d3110f6e4425c2a1a58f235b2f131b510af]
module.eks.aws_iam_openid_connect_provider.oidc_provider[0]: Creating...
module.eks.aws_eks_access_entry.this["cluster_creator"]: Creation complete after 2s [id=infoline-eks:arn:aws:iam::<ACCOUNT_ID>:user/<IAM_USER>]
module.eks.aws_eks_access_policy_association.this["cluster_creator_admin"]: Creating...
module.eks.aws_eks_access_policy_association.this["cluster_creator_admin"]: Creation complete after 1s [id=infoline-eks#arn:aws:iam::<ACCOUNT_ID>:user/<IAM_USER>#arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy]
module.eks.aws_iam_openid_connect_provider.oidc_provider[0]: Creation complete after 3s [id=arn:aws:iam::<ACCOUNT_ID>:oidc-provider/oidc.eks.eu-west-3.amazonaws.com/id/<OIDC_HASH>]
module.eks.time_sleep.this[0]: Still creating... [00m09s elapsed]
module.eks.time_sleep.this[0]: Still creating... [00m19s elapsed]
module.eks.time_sleep.this[0]: Still creating... [00m28s elapsed]
module.eks.time_sleep.this[0]: Creation complete after 28s [id=2026-07-01T05:42:38Z]
module.eks.module.eks_managed_node_group["main"].module.user_data.null_resource.validate_cluster_service_cidr: Creating...
module.eks.module.eks_managed_node_group["main"].aws_launch_template.this[0]: Creating...
module.eks.module.eks_managed_node_group["main"].module.user_data.null_resource.validate_cluster_service_cidr: Creation complete after 0s [id=6184312201344725227]
module.eks.module.eks_managed_node_group["main"].aws_launch_template.this[0]: Creation complete after 7s [id=lt-015ff966a5efc9531]
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Creating...
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Still creating... [00m09s elapsed]
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Still creating... [00m18s elapsed]
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Still creating... [00m27s elapsed]
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Still creating... [00m36s elapsed]
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Still creating... [00m45s elapsed]
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Still creating... [01m00s elapsed]
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Still creating... [01m04s elapsed]
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Still creating... [01m13s elapsed]
module.eks.module.eks_managed_node_group["main"].aws_eks_node_group.this[0]: Creation complete after 1m15s [id=infoline-eks:main-20260701054245615800000013]

Apply complete! Resources: 54 added, 0 changed, 0 destroyed.

Outputs:

cluster_certificate_authority_data = <sensitive>
cluster_endpoint = "https://<OIDC_HASH>.gr7.eu-west-3.eks.amazonaws.com"
cluster_name = "infoline-eks"
configure_kubectl = "aws eks update-kubeconfig --region eu-west-3 --name infoline-eks"
private_subnet_ids = [
  "subnet-0e65376cdcd987330",
  "subnet-0609a2363310c6436",
]
vpc_id = "vpc-0d67d372811ba6592"
julien@Julien:~/infoline-devops/terraform/eks$ aws eks update-kubeconfig --region eu-west-3 --name infoline-eks
Updated context arn:aws:eks:eu-west-3:<ACCOUNT_ID>:cluster/infoline-eks in /home/julien/.kube/config
julien@Julien:~/infoline-devops/terraform/eks$ kubectl get nodes
NAME                                      STATUS   ROLES    AGE    VERSION
ip-10-0-1-14.eu-west-3.compute.internal   Ready    <none>   4m6s   v1.34.9-eks-93b80c6
ip-10-0-2-31.eu-west-3.compute.internal   Ready    <none>   4m5s   v1.34.9-eks-93b80c6
julien@Julien:~/infoline-devops/terraform/eks$ 