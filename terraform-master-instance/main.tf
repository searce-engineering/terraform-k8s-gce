#Gcloudbeta Module Main.tf

data "google_compute_zones" "available" {
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_instance" "default" {
  count                     = "${var.module_enabled ? 1 : 0}"
  project                   = "${var.project}"
  allow_stopping_for_update = true

  name         = "${var.name}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  tags = ["${concat(list("allow-ssh"), var.target_tags)}"]

  labels = "${var.instance_labels}"

  boot_disk {
    initialize_params {
      image = "${var.compute_image}"
    }
  }

  network_interface {
    network            = "${var.subnetwork == "" ? var.network : ""}"
    subnetwork         = "${var.subnetwork}"
    access_config      = ["${var.access_config}"]
    network_ip         = "${var.network_ip}"
    subnetwork_project = "${var.subnetwork_project == "" ? var.project : var.subnetwork_project}"
  }

  guest_accelerator = {
    type  = "${var.type}"
    count = "${var.count}"
  }

  metadata = "${merge(
    map("startup-script", "${var.startup_script}", "tf_depends_id", "${var.depends_id}"),
    var.metadata
  )}"

  scheduling {
    preemptible         = "${var.preemptible}"
    automatic_restart   = "${var.automatic_restart}"
    on_host_maintenance = "${var.on_host_maintenance}"
  }

  # metadata_startup_script = "echo hi > /test.txt"

  service_account {
    email  = "${var.service_account_email}"
    scopes = ["${var.service_account_scopes}"]
  }
}

resource "null_resource" "dummy_dependency" {
  count      = "${var.module_enabled}"
  depends_on = ["google_compute_instance.default"]
}

locals {
  distribution_zones = {
    default = ["${data.google_compute_zones.available.names}"]
    user    = ["${var.distribution_policy_zones}"]
  }

  dependency_id = "${element(concat(null_resource.region_dummy_dependency.*.id, list("disabled")), 0)}"
}

resource "google_compute_firewall" "default-ssh" {
  count   = "${var.module_enabled && var.ssh_fw_rule ? 1 : 0}"
  project = "${var.subnetwork_project == "" ? var.project : var.subnetwork_project}"
  name    = "${var.name}-vm-ssh"
  network = "${var.network}"

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }

  source_ranges = ["${var.ssh_source_ranges}"]
  target_tags   = ["allow-ssh"]
}

# data "google_compute_instance_group" "zonal" {
#   count    = "${var.zonal ? 1 : 0}"
#   zone     = "${var.zone}"
#   project  = "${var.project}"
#   provider = "google-beta"
#
#   // Use the dependency id which is recreated whenever the instance template changes to signal when to re-read the data source.
#   name = "${element(split("|", "${local.dependency_id}|${element(concat(google_compute_instance_group_manager.default.*.name, list("unused")), 0)}"), 1)}"
# }

