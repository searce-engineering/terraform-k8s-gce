#Gcloudbeta Module Outputs.tf

output name {
  description = "Pass through of input `name`."
  value       = "${var.name}"
}

output instance_template {
  description = "Link to the instance_template for the group"
  value       = "${google_compute_instance_template.default.*.self_link}"
}

output instance_group {
  description = "Link to the `instance_group` property of the instance group manager resource."
  value       = "${element(concat(google_compute_instance_group_manager.default.*.instance_group, list("")), 0)}"
}

output instances {
  description = "List of instances in the instance group. Note that this can change dynamically depending on the current number of instances in the group and may be empty the first time read."
  value       = "${data.google_compute_instance_group.zonal.*.instances}"
}

output region_instance_group {
  description = "Link to the `instance_group` property of the region instance group manager resource."
  value       = "${element(concat(google_compute_region_instance_group_manager.default.*.instance_group, list("")), 0)}"
}

output target_tags {
  description = "Pass through of input `target_tags`."
  value       = "${var.target_tags}"
}

output service_port {
  description = "Pass through of input `service_port`."
  value       = "${var.service_port}"
}

output service_port_name {
  description = "Pass through of input `service_port_name`."
  value       = "${var.service_port_name}"
}

output depends_id {
  description = "Id of the dummy dependency created used for intra-module dependency creation with zonal groups."
  value       = "${element(concat(null_resource.dummy_dependency.*.id, list("")), 0)}"
}

output region_depends_id {
  description = "Id of the dummy dependency created used for intra-module dependency creation with regional groups."
  value       = "${element(concat(null_resource.region_dummy_dependency.*.id, list("")), 0)}"
}

output network_ip {
  description = "Pass through of input `network_ip`."
  value       = "${var.network_ip}"
}

output health_check {
  description = "The healthcheck for the managed instance group"
  value       = "${element(concat(google_compute_health_check.mig-health-check.*.self_link, list("")), 0)}"
}
