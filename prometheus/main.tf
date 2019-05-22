####### Creating Namespace ####
resource "k8s_manifest" "monitoring_namespace" {
  status  = "${var.kubeconfig_path}"
  name    = "monitoring"
  kind    = "Namespace"
  content = "${file("${path.module}/prometheus-resources/namespace.yaml")}"
}

####### Creating Cluster Roles for prometheus ####
resource "k8s_manifest" "prometheus_crole" {
  status    = "${var.kubeconfig_path}"
  name      = "prometheus"
  kind      = "ClusterRole"
  namespace = "${k8s_manifest.monitoring_namespace.name}"
  content   = "${file("${path.module}/prometheus-resources/clusterrole.yaml")}"
}

####### Creating Cluster Rolebinding for prometheus ####
resource "k8s_manifest" "prometheus_crb" {
  depends_on = ["k8s_manifest.prometheus_crole"]

  status    = "${var.kubeconfig_path}"
  name      = "prometheus"
  kind      = "ClusterRoleBinding"
  namespace = "${k8s_manifest.monitoring_namespace.name}"
  content   = "${file("${path.module}/prometheus-resources/clusterrolebinding.yaml")}"
}

######### Prometheus ConfigMap #####
resource "k8s_manifest" "prometheus_ConfigMap" {
  depends_on = ["k8s_manifest.prometheus_crb"]

  status    = "${var.kubeconfig_path}"
  name      = "prometheus-server-conf"
  kind      = "ConfigMap"
  namespace = "${k8s_manifest.monitoring_namespace.name}"
  content   = "${file("${path.module}/prometheus-resources/prometheus-config-map.yaml")}"
}

########## prometheus Deployment #####
resource "k8s_manifest" "prometheus_deploy" {
  depends_on = ["k8s_manifest.prometheus_ConfigMap"]

  status    = "${var.kubeconfig_path}"
  name      = "prometheus-deployment"
  kind      = "Deployment"
  namespace = "${k8s_manifest.monitoring_namespace.name}"
  content   = "${file("${path.module}/prometheus-resources/prometheus-deployment.yaml")}"
}

########## prometheus Service #####
resource "k8s_manifest" "prometheus_svc" {
  depends_on = ["k8s_manifest.prometheus_deploy"]

  status    = "${var.kubeconfig_path}"
  name      = "prometheus-service"
  kind      = "Service"
  namespace = "${k8s_manifest.monitoring_namespace.name}"
  content   = "${file("${path.module}/prometheus-resources/prometheus-service.yaml")}"
}

