#Master Module Output.tf

output master_ip {
  description = "The internal address of the master"
  value       = "${var.master_ip == "" ? lookup(var.region_params["${var.region}"], "master_ip") : var.master_ip}"
}

output depends_id {
  description = "Value that can be used for intra-module dependency creation."
  value       = "${module.master-instance.depends_id}"
}

output "tls-private-key-private_key_pem" {
  value     = "${tls_private_key.key.private_key_pem}"
  sensitive = true
}

output "pem_path" {
  value = "${local_file.master-pkey.filename}"
}

output "subnet_ip_cidr" {
  value = "${data.google_compute_subnetwork.subnet.ip_cidr_range}"
}

output "subnetwork" {
  value = "${var.subnetwork}"
}
