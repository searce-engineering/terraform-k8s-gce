#Outputs.tf

output master_ip {
  description = "The internal address of the master"
  value       = "${module.master-1.master_ip}"
}

output external_ip {
  description = "The external IP address of the NAT gateway instance."
  value       = "${module.nat.external_ip}"
}
