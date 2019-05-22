####### Creating Cluster Roles ####
resource "k8s_manifest" "aggregated_metrics_reader_crole" {
  status    = "${var.kubeconfig_path}"
  name      = "system:aggregated-metrics-reader"
  kind      = "ClusterRole"
  namespace = "kube-system"
  content   = "${file("${path.module}/metric-server-resources/aggregated-metrics-reader-cr.yaml")}"
}

resource "k8s_manifest" "metrics_server_crole" {
  status    = "${var.kubeconfig_path}"
  name      = "system:metrics-server"
  kind      = "ClusterRole"
  namespace = "kube-system"
  content   = "${file("${path.module}/metric-server-resources/metrics-server-cr.yaml")}"
}

####### Creating Service Account for metrics-server ####

resource "k8s_manifest" "metrics_server_sa" {
  status    = "${var.kubeconfig_path}"
  name      = "metrics-server"
  kind      = "ServiceAccount"
  namespace = "kube-system"
  content   = "${file("${path.module}/metric-server-resources/metrics-server-sa.yaml")}"
}

######### Role bindings ###

resource "k8s_manifest" "auth_reader_rb" {
  depends_on = ["k8s_manifest.metrics_server_sa"]

  status    = "${var.kubeconfig_path}"
  name      = "metrics-server-auth-reader"
  kind      = "RoleBinding"
  namespace = "kube-system"
  content   = "${file("${path.module}/metric-server-resources/auth-reader-rb.yaml")}"
}

######### Cluster Role bindings ###

resource "k8s_manifest" "metrics_server_crb" {
  depends_on = ["k8s_manifest.metrics_server_sa"]

  status    = "${var.kubeconfig_path}"
  name      = "system:metrics-server"
  kind      = "ClusterRoleBinding"
  namespace = "kube-system"
  content   = "${file("${path.module}/metric-server-resources/metrics-server-crb.yaml")}"
}

resource "k8s_manifest" "auth-delegator_crb" {
  depends_on = ["k8s_manifest.metrics_server_sa"]

  status    = "${var.kubeconfig_path}"
  name      = "metrics-server:system:auth-delegator"
  kind      = "ClusterRoleBinding"
  namespace = "kube-system"
  content   = "${file("${path.module}/metric-server-resources/auth-delegator-crb.yaml")}"
}

######### metrics-server Service #####

resource "k8s_manifest" "metrics_server_service" {
  depends_on = ["k8s_manifest.metrics_server_crb"]

  status    = "${var.kubeconfig_path}"
  name      = "metrics-server"
  kind      = "Service"
  namespace = "kube-system"
  content   = "${file("${path.module}/metric-server-resources/metrics-server-service.yaml")}"
}

######### API service #####

resource "k8s_manifest" "metrics_server_apiservice" {
  depends_on = ["k8s_manifest.metrics_server_service"]

  status    = "${var.kubeconfig_path}"
  name      = "v1beta1.metrics.k8s.io"
  kind      = "APIService"
  namespace = "kube-system"
  content   = "${file("${path.module}/metric-server-resources/metrics-apiservice.yaml")}"
}

########## Deployment of cluster-autoscaler #####

resource "k8s_manifest" "cluster_autoscaler_deploy" {
  depends_on = ["k8s_manifest.metrics_server_service"]

  status    = "${var.kubeconfig_path}"
  name      = "metrics-server"
  kind      = "Deployment"
  namespace = "kube-system"
  content   = "${file("${path.module}/metric-server-resources/metrics-server-deployment.yaml")}"
}
