####### Creating Roles ####
resource "k8s_manifest" "kubernetes_dashboard_role" {
  depends_on = ["k8s_manifest.kubernetes_dashboard_secret"]

  status    = "${var.kubeconfig_path}"
  name      = "kubernetes-dashboard-minimal"
  kind      = "Role"
  namespace = "kube-system"
  content   = "${file("${path.module}/kubernetes-dashboard-resources/kubernetes-dashboard-role.yaml")}"
}

####### Creating Service Account ####

resource "k8s_manifest" "kubernetes_dashboard_sa" {
  depends_on = ["k8s_manifest.kubernetes_dashboard_role"]

  status    = "${var.kubeconfig_path}"
  name      = "kubernetes-dashboard"
  kind      = "ServiceAccount"
  namespace = "kube-system"
  content   = "${file("${path.module}/kubernetes-dashboard-resources/kubernetes-dashboard-sa.yaml")}"
}

resource "k8s_manifest" "kubernetes_dashboard_rb" {
  depends_on = ["k8s_manifest.kubernetes_dashboard_sa"]

  status    = "${var.kubeconfig_path}"
  name      = "kubernetes-dashboard-minimal"
  kind      = "RoleBinding"
  namespace = "kube-system"
  content   = "${file("${path.module}/kubernetes-dashboard-resources/kubernetes-dashboard-rb.yaml")}"
}

######### Secret ###

resource "k8s_manifest" "kubernetes_dashboard_secret" {
  status    = "${var.kubeconfig_path}"
  name      = "kubernetes-dashboard-certs"
  kind      = "Secret"
  namespace = "kube-system"
  content   = "${file("${path.module}/kubernetes-dashboard-resources/kubernetes-dashboard-secret.yaml")}"
}

######### Cluster Role bindings ###

resource "k8s_manifest" "dashboard_admin_sa" {
  status    = "${var.kubeconfig_path}"
  name      = "admin-user"
  kind      = "ServiceAccount"
  namespace = "kube-system"
  content   = "${file("${path.module}/kubernetes-dashboard-resources/dashboard-admin-user-sa.yaml")}"
}

resource "k8s_manifest" "dashboard_admin_crb" {
  depends_on = ["k8s_manifest.dashboard_admin_sa"]

  status    = "${var.kubeconfig_path}"
  name      = "admin-user"
  kind      = "ClusterRoleBinding"
  namespace = "kube-system"
  content   = "${file("${path.module}/kubernetes-dashboard-resources/dashboard-admin-user-crb.yaml")}"
}

#########  Service #####

resource "k8s_manifest" "kubernetes_dashboard_service" {
  depends_on = ["k8s_manifest.kubernetes_dashboard_rb"]

  status    = "${var.kubeconfig_path}"
  name      = "kubernetes-dashboard"
  kind      = "Service"
  namespace = "kube-system"
  content   = "${file("${path.module}/kubernetes-dashboard-resources/kubernetes-dashboard-service.yaml")}"
}

########## Deployment of Dashboard #####

resource "k8s_manifest" "kubernetes_dashboard_deploy" {
  depends_on = ["k8s_manifest.kubernetes_dashboard_service"]

  status    = "${var.kubeconfig_path}"
  name      = "kubernetes-dashboard"
  kind      = "Deployment"
  namespace = "kube-system"
  content   = "${file("${path.module}/kubernetes-dashboard-resources/kubernetes-dashboard-deployment.yaml")}"
}
