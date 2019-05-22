output kubeconfig_path {
  description = "The kubeconfig_path"
  value       = "${k8s_manifest.cluster_autoscaler_crb.status}"
}
