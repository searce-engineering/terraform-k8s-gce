#Gcloudbeta Module Outputs.tf

output name {
  description = "Pass through of input `name`."
  value       = "${var.name}"
}

output target_tags {
  description = "Pass through of input `target_tags`."
  value       = "${var.target_tags}"
}

output network_ip {
  description = "Pass through of input `network_ip`."
  value       = "${var.network_ip}"
}

output depends_id {
  description = "Id of the dummy dependency created used for intra-module dependency creation with zonal groups."
  value       = "${element(concat(null_resource.dummy_dependency.*.id, list("")), 0)}"
}
