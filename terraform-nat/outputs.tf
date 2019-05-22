#Nat Module Outputs.tf

output depends_id {
  description = "Value that can be used for intra-module dependency creation."
  value       = "${module.nat-gateway.depends_id}"
}

output gateway_ip {
  description = "The internal IP address of the NAT gateway instance."
  value       = "${module.nat-gateway.network_ip}"
}

output instance {
  description = "The self link to the NAT gateway instance."
  value       = "${flatten(module.nat-gateway.instances)}"
}

output external_ip {
  description = "The external IP address of the NAT gateway instance."
  value       = "${element(concat(google_compute_address.default.*.address, data.google_compute_address.default.*.address, list("")), 0)}"
}

output routing_tag_regional {
  description = "The tag that any other instance will need to have in order to get the regional routing rule"
  value       = "${local.regional_tag}"
}

output routing_tag_zonal {
  description = "The tag that any other instance will need to have in order to get the zonal routing rule"
  value       = "${local.zonal_tag}"
}
