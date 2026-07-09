# Access Entry EKS pour l'utilisateur IAM du CI (infoline-ci).
#
# Sur EKS, deux couches d'autorisation cohabitent : IAM (authentification AWS) et RBAC
# Kubernetes (autorisation dans le cluster). L'Access Entry (mécanisme moderne EKS, pas
# aws-auth legacy) fait le pont : sans elle, kubectl renvoie "the server has asked for the
# client to provide credentials" alors même que l'auth AWS réussit (cf. architecture.md,
# « Pourquoi un utilisateur IAM CI dédié »).
#
# Versionné ici car terraform/eks/ est détruit/recréé chaque session : une Access Entry
# posée à la main en CLI disparaît à chaque cycle et recasse le pipeline.

# infoline-ci est géré dans un state séparé (terraform/iam-ci/). On lit son ARN à chaud
# plutôt que de le coder en dur ou de fusionner les deux states.
data "aws_iam_user" "ci" {
  user_name = "infoline-ci"
}

resource "aws_eks_access_entry" "ci" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_iam_user.ci.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ci" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_iam_user.ci.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ci]
}
