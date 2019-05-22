#Worker Module Main.tf

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

data "template_file" "node-bootstrap" {
  template = "${file("${format("%s/scripts/node.sh.tpl", path.module)}")}"

  vars {
    master_ip = "${var.master_ip == "" ? lookup(var.region_params["${var.region}"], "master_ip") : var.master_ip}"
    token     = "${var.token-part-1}.${var.token-part-2}"
  }
}

data "template_file" "iptables" {
  template = "${file("${format("%s/scripts/iptables.sh.tpl", path.module)}")}"
}

data "template_file" "shutdown-script" {
  // Used for clean shutdown and helps with autoscaling.
  template = "${file("${format("%s/scripts/shutdown.sh.tpl", path.module)}")}"
}

locals {
  name = "k8s-${var.cluster_name}-${var.name}"
}

data "template_cloudinit_config" "node" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "scripts/per-instance/10-k8s-core.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.core-init.rendered}"
  }

  part {
    filename     = "scripts/per-instance/20-node.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.node-bootstrap.rendered}"
  }

  // per boot
  part {
    filename     = "scripts/per-boot/10-iptables.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.iptables.rendered}"
  }
}

module "worker-mig" {
  source            = "../terraform-gcloudbeta"
  version           = "1.1.14"
  name              = "${local.name}"
  name_prefix       = "${var.cluster_name}-${var.name}"
  region            = "${var.region}"
  zonal             = true
  network           = "${var.network}"
  subnetwork        = "${var.network}"
  access_config     = "${var.access_config}"
  can_ip_forward    = true
  zone              = "${var.zone}"
  size              = "${var.num_nodes}"
  compute_image     = "${var.compute_image}"
  machine_type      = "${var.machine_type}"
  type              = "${var.gpu_type}"
  count             = "${var.gpu_count}"
  disk_size_gb      = "${var.disk_size_gb}"
  target_tags       = ["${concat(list("${local.name}"), var.add_tags)}"]
  service_port      = 80
  service_port_name = "http"
  http_health_check = false
  instance_labels   = "${map("ig", "${local.name}-worker")}"

  metadata {
    user-data          = "${data.template_cloudinit_config.node.rendered}"
    user-data-encoding = "base64"
    shutdown-script    = "${data.template_file.shutdown-script.rendered}"
    kube-env           = "${join("\n", list(join("", concat(list("NODE_LABELS: "), list(join(",", var.node_labels))))), var.kube_env)}"
  }

  depends_id = "${var.depends_id}"
}
