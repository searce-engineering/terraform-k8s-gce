#Nat Module Main.tf

data "template_file" "nat-startup-script" {
  template = "${file("${format("%s/config/startup.sh", path.module)}")}"

  vars {
    squid_enabled   = "${var.squid_enabled}"
    squid_config    = "${var.squid_config}"
    master_ip       = "${var.master_ip}"
    master_pem_path = "${var.master_pem_path}"
    module_path     = "${path.module}"
  }
}

data "google_compute_network" "network" {
  name    = "${var.network}"
  project = "${var.network_project == "" ? var.project : var.network_project}"
}

data "google_compute_address" "default" {
  count   = "${var.ip_address_name == "" ? 0 : 1}"
  name    = "${var.ip_address_name}"
  project = "${var.network_project == "" ? var.project : var.network_project}"
  region  = "${var.region}"
}

locals {
  zone          = "${var.zone == "" ? lookup(var.region_params["${var.region}"], "zone") : var.zone}"
  name          = "k8s-${var.cluster_name}-${var.name}"
  instance_tags = ["inst-${local.zonal_tag}", "inst-${local.regional_tag}"]
  zonal_tag     = "${var.name}-${var.cluster_name}-${local.zone}"
  regional_tag  = "${var.name}-${var.region}"
}

# Add a ssh key for prow to clone from private repos.
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "nat-key" {
  content  = "${tls_private_key.key.public_key_openssh}"
  filename = "${path.module}/keys/nat-key-${local.name}.pub"
}

resource "local_file" "nat-pkey" {
  content  = "${tls_private_key.key.private_key_pem}"
  filename = "${path.module}/keys/nat-pkey-${local.name}.pem"
}

module "nat-gateway" {
  source                = "../terraform-gcloudbeta"
  version               = "1.1.15"
  module_enabled        = "${var.module_enabled}"
  name_prefix           = "${var.cluster_name}-${var.name}"
  project               = "${var.project}"
  region                = "${var.region}"
  zone                  = "${local.zone}"
  network               = "${var.network}"
  subnetwork            = "${var.network}"
  target_tags           = ["${local.instance_tags}"]
  instance_labels       = "${var.instance_labels}"
  service_account_email = "${var.service_account_email}"
  machine_type          = "${var.machine_type}"
  name                  = "${local.name}"
  compute_image         = "${var.compute_image}"
  size                  = 1
  network_ip            = "${var.ip}"
  can_ip_forward        = "true"
  service_port          = "80"
  service_port_name     = "http"
  startup_script        = "${data.template_file.nat-startup-script.rendered}"
  wait_for_instances    = true
  metadata              = "${var.metadata}"
  ssh_fw_rule           = "${var.ssh_fw_rule}"
  ssh_source_ranges     = "${var.ssh_source_ranges}"
  http_health_check     = "${var.autohealing_enabled}"

  access_config = [
    {
      nat_ip = "${element(concat(google_compute_address.default.*.address, data.google_compute_address.default.*.address, list("")), 0)}"
    },
  ]
}

resource "google_compute_route" "nat-gateway" {
  count                  = "${var.module_enabled ? 1 : 0}"
  name                   = "${local.zonal_tag}"
  project                = "${var.project}"
  dest_range             = "${var.dest_range}"
  network                = "${data.google_compute_network.network.self_link}"
  next_hop_instance      = "${element(split("/", element(module.nat-gateway.instances[0], 0)), 10)}"
  next_hop_instance_zone = "${local.zone}"
  tags                   = ["${compact(concat(list("${local.zonal_tag}"), var.tags))}"]
  priority               = "${var.route_priority}"
}

resource "google_compute_firewall" "nat-gateway" {
  count   = "${var.module_enabled ? 1 : 0}"
  name    = "${local.zonal_tag}"
  network = "${var.network}"
  project = "${var.project}"

  allow {
    protocol = "all"
  }

  source_tags = ["${compact(concat(list("${local.regional_tag}", "${local.zonal_tag}"), var.tags))}"]
  target_tags = ["${compact(concat(local.instance_tags, var.tags))}"]
}

resource "google_compute_address" "default" {
  count   = "${var.module_enabled && var.ip_address_name == "" ? 1 : 0}"
  name    = "${local.zonal_tag}"
  project = "${var.project}"
  region  = "${var.region}"
}
