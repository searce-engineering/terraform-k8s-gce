####### Creating CRB for cluster-autoscaler ####
resource "k8s_manifest" "cluster_autoscaler_role" {
  status    = "${var.kubeconfig_path}"
  name      = "cluster-autoscaler"
  kind      = "Role"
  namespace = "kube-system"
  content   = "${file("${path.module}/cluster-autoscaler-resources/role.yaml")}"
}

resource "k8s_manifest" "cluster_autoscaler_clusterrole" {
  status    = "${var.kubeconfig_path}"
  name      = "cluster-autoscaler"
  kind      = "ClusterRole"
  namespace = "kube-system"
  content   = "${file("${path.module}/cluster-autoscaler-resources/clusterrole.yaml")}"
}

resource "k8s_manifest" "cluster_autoscaler_sa" {
  status    = "${var.kubeconfig_path}"
  name      = "cluster-autoscaler"
  kind      = "ServiceAccount"
  namespace = "kube-system"
  content   = "${file("${path.module}/cluster-autoscaler-resources/sa.yaml")}"
}

resource "k8s_manifest" "cluster_autoscaler_rolebinding" {
  depends_on = ["k8s_manifest.cluster_autoscaler_role", "k8s_manifest.cluster_autoscaler_sa"]
  status     = "${var.kubeconfig_path}"
  name       = "cluster-autoscaler"
  kind       = "RoleBinding"
  namespace  = "kube-system"
  content    = "${file("${path.module}/cluster-autoscaler-resources/rolebinding.yaml")}"
}

resource "k8s_manifest" "cluster_autoscaler_crb" {
  depends_on = ["k8s_manifest.cluster_autoscaler_clusterrole", "k8s_manifest.cluster_autoscaler_sa"]

  status    = "${var.kubeconfig_path}"
  name      = "cluster-autoscaler"
  kind      = "ClusterRoleBinding"
  namespace = "kube-system"
  content   = "${file("${path.module}/cluster-autoscaler-resources/crb.yaml")}"
}
