#Worker Module Outputs.tf

output worker_name {
  description = "The worker name"
  value       = "${module.worker-mig.name}"
}

output worker_ca_min {
  description = "The worker zone"
  value       = "${var.cluster_autoscalar_min}"
}

output worker_ca_max {
  description = "The worker zone"
  value       = "${var.cluster_autoscalar_max}"
}

output worker_zone {
  description = "The worker zone"
  value       = "${var.zone}"
}
