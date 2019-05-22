#Master Module Main.tf

data "google_client_config" "current" {
  provider = "google-beta"
}

data "template_file" "core-init" {
  template = "${file("${format("%s/scripts/k8s-core.sh.tpl", path.module)}")}"

  vars {
    dns_ip               = "${var.dns_ip}"
    docker_version       = "${var.docker_version}"
    k8s_version          = "${replace(var.k8s_version, "^v", "")}"
    k8s_version_override = "${var.k8s_version_override == "" ? replace(var.k8s_version, "^v", "") : replace(var.k8s_version_override, "^v", "")}"
    cni_version          = "${var.cni_version}"
    tags                 = "${local.name}"
    instance_prefix      = "${local.name}"
    pod_network_type     = "${var.pod_network_type}"
    project_id           = "${data.google_client_config.current.project}"
    network_name         = "${var.network}"
    subnetwork_name      = "${var.network}"
    gce_conf_add         = "${var.gce_conf_add}"
    add_labels           = "${join(",", var.node_labels)}"
  }
}

data "template_file" "master-bootstrap" {
  template = "${file("${format("%s/scripts/master.sh.tpl", path.module)}")}"

  vars {
    k8s_version       = "${var.k8s_version_override == "" ? replace(var.k8s_version, "^v", "") : replace(var.k8s_version_override, "^v", "")}"
    dashboard_version = "${var.dashboard_version}"
    calico_version    = "${var.calico_version}"
    pod_cidr          = "${var.pod_cidr}"
    service_cidr      = "${var.service_cidr}"
    token             = "${var.token-part-1}.${var.token-part-2}"
    cluster_uid       = "${var.cluster_uid == "" ? var.cluster-uid : var.cluster_uid}"
    instance_prefix   = "${local.name}"
    pod_network_type  = "${var.pod_network_type}"
    feature_gates     = "${var.feature_gates}"
  }
}

data "template_file" "iptables" {
  template = "${file("${format("%s/scripts/iptables.sh.tpl", path.module)}")}"
}

data "template_file" "shutdown-script" {
  // Used for clean shutdown and helps with autoscaling.
  template = "${file("${format("%s/scripts/shutdown.sh.tpl", path.module)}")}"
}

data "template_cloudinit_config" "master" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "scripts/per-instance/10-k8s-core.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.core-init.rendered}"
  }

  part {
    filename     = "scripts/per-instance/20-master.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.master-bootstrap.rendered}"
  }

  // per boot
  part {
    filename     = "scripts/per-boot/10-iptables.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.iptables.rendered}"
  }
}

locals {
  name = "k8s-${var.cluster_name}-${var.name}"
}

resource "random_id" "instance-prefix" {
  byte_length = 4
  prefix      = "k8s-${var.name}-"
}

# Add a ssh key for prow to clone from private repos.
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "master-key" {
  content  = "${tls_private_key.key.public_key_openssh}"
  filename = "${path.module}/keys/master-key-${random_id.instance-prefix.hex}.pub"
}

resource "local_file" "master-pkey" {
  content  = "${tls_private_key.key.private_key_pem}"
  filename = "${path.module}/keys/master-pkey-${random_id.instance-prefix.hex}.pem"
}

module "master-instance" {
  source              = "../terraform-master-instance"
  version             = "1.1.14"
  name                = "${local.name}"
  zone                = "${var.zone}"
  network             = "${var.network}"
  subnetwork          = "${var.network}"
  network_ip          = "${var.master_ip == "" ? lookup(var.region_params["${var.region}"], "master_ip") : var.master_ip}"
  access_config       = [{}]
  can_ip_forward      = true
  compute_image       = "${var.compute_image}"
  machine_type        = "${var.machine_type}"
  disk_size_gb        = "${var.disk_size_gb}"
  target_tags         = ["${concat(list("${local.name}"), var.add_tags)}"]
  on_host_maintenance = "TERMINATE"

  metadata {
    user-data          = "${data.template_cloudinit_config.master.rendered}"
    user-data-encoding = "base64"

    ssh-keys = "root:${file("${local_file.master-key.filename}")}"
  }

  depends_id = "${var.depends_id}"
}

resource "google_compute_firewall" "k8s-all" {
  name    = "${local.name}-all"
  network = "${var.network}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "esp"
  }

  allow {
    protocol = "ah"
  }

  allow {
    protocol = "sctp"
  }

  source_ranges = ["${var.pod_cidr}"]
}

resource "google_compute_firewall" "vms" {
  name    = "${local.name}-vms"
  network = "${var.network}"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["${compact(list("10.128.0.0/9","${var.subnetwork != "default" ? data.google_compute_subnetwork.subnet.ip_cidr_range : ""}"))}"]
}

data "google_compute_subnetwork" "subnet" {
  name   = "${var.network}"
  region = "${var.region}"
}
