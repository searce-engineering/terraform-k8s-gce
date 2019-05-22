#Gcloudbeta Module Variables.tf

variable module_enabled {
  description = ""
  default     = true
}

variable project {
  description = "The project to deploy to, if not set the default provider project is used."
  default     = ""
}

variable zone {
  description = "Zone for managed instance groups."
  default     = "us-central1-b"
}

variable network {
  description = "Name of the network to deploy instances to."
  default     = "default"
}

variable subnetwork {
  description = "The subnetwork to deploy to"
  default     = "default"
}

variable subnetwork_project {
  description = "The project the subnetwork belongs to. If not set, var.project is used instead."
  default     = ""
}

variable name {
  description = "Name of the managed instance group."
}

variable startup_script {
  description = "Content of startup-script metadata passed to the instance template."
  default     = ""
}

variable access_config {
  description = "The access config block for the instances. Set to [] to remove external IP."
  type        = "list"

  default = [
    {},
  ]
}

variable metadata {
  description = "Map of metadata values to pass to instances."
  type        = "map"
  default     = {}
}

variable can_ip_forward {
  description = "Allow ip forwarding."
  default     = false
}

variable network_ip {
  description = "Set the network IP of the instance in the template. Useful for instance groups of size 1."
  default     = ""
}

variable machine_type {
  description = "Machine type for the VMs in the instance group."
  default     = "f1-micro"
}

variable type {
  description = "The type of GPU accelerator to be added."
  default     = "nvidia-tesla-k80"
}

variable count {
  description = "The count of GPU accelerator to be added."
  default     = "0"
}

variable compute_image {
  description = "Image used for compute VMs."
  default     = "projects/debian-cloud/global/images/family/debian-9"
}

variable provider {
  default = "google-beta"
}

variable target_tags {
  description = "Tag added to instances for firewall and networking."
  type        = "list"
  default     = ["allow-service"]
}

variable instance_labels {
  description = "Labels added to instances."
  type        = "map"
  default     = {}
}

variable on_host_maintenance {
  description = "The host mainetenece."
  default     = "TERMINATE"
}

variable depends_id {
  description = "The ID of a resource that the instance group depends on."
  default     = ""
}

variable local_cmd_create {
  description = "Command to run on create as local-exec provisioner for the instance group manager."
  default     = ":"
}

variable local_cmd_destroy {
  description = "Command to run on destroy as local-exec provisioner for the instance group manager."
  default     = ":"
}

variable service_account_email {
  description = "The email of the service account for the instance template."
  default     = "default"
}

variable service_account_scopes {
  description = "List of scopes for the instance template service account"
  type        = "list"

  default = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/devstorage.full_control",
  ]
}

variable ssh_source_ranges {
  description = "Network ranges to allow SSH from"
  type        = "list"
  default     = ["74.125.0.0/16", "72.14.192.0/18", "108.177.8.0/21", "173.194.0.0/16"]
}

variable disk_auto_delete {
  description = "Whether or not the disk should be auto-deleted."
  default     = true
}

variable disk_type {
  description = "The GCE disk type. Can be either pd-ssd, local-ssd, or pd-standard."
  default     = "pd-ssd"
}

variable disk_size_gb {
  description = "The size of the image in gigabytes. If not specified, it will inherit the size of its base image."
  default     = 0
}

variable mode {
  description = "The mode in which to attach this disk, either READ_WRITE or READ_ONLY."
  default     = "READ_WRITE"
}

variable "preemptible" {
  description = "Use preemptible instances - lower price but short-lived instances. See https://cloud.google.com/compute/docs/instances/preemptible for more details"
  default     = "false"
}

variable distribution_policy_zones {
  description = "The distribution policy for this managed instance group when zonal=false. Default is all zones in given region."
  type        = "list"
  default     = []
}

variable region {
  description = "The region to create the cluster in."
  default     = "us-central1"
}

variable "automatic_restart" {
  description = "Automatically restart the instance if terminated by GCP - Set to false if using preemptible instances"
  default     = "true"
}

variable ssh_fw_rule {
  description = "Whether or not the SSH Firewall Rule should be created"
  default     = true
}
