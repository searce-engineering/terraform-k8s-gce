# Main.tf

resource "random_id" "token-part-1" {
  byte_length = 3
}

resource "random_id" "token-part-2" {
  byte_length = 8
}

resource "random_id" "cluster-uid" {
  byte_length = 8
}

# Add a ssh key for prow to clone from private repos.
resource "tls_private_key" "nat_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Firewall rule to allow ipip protocol,comment if it exists already
resource "google_compute_firewall" "default" {
  name    = "k8s-calico-ipip1"
  network = "${var.network}"

  allow {
    protocol = "ipip"
  }

  source_ranges = ["${compact(list("10.128.0.0/9","${module.master-1.subnetwork != "default" ? module.master-1.subnet_ip_cidr : ""}"))}"]
}

# Firewall rule to allow http and https protocol, comment if it exists already
resource "google_compute_firewall" "allow-http-https" {
  name    = "allow-http-https1"
  network = "${var.network}"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

module "master-1" {
  source           = "terraform-master"
  token-part-1     = "${random_id.token-part-1.hex}"
  token-part-2     = "${random_id.token-part-2.hex}"
  cluster-uid      = "${random_id.cluster-uid.hex}"
  master_ip        = "${var.master_ip}"
  name             = "master-1"
  cluster_name     = "${var.cluster_name}"
  network          = "${var.network}"
  region           = "${var.region}"
  zone             = "${var.zone}"
  disk_size_gb     = "30"
  type             = ""
  count            = "0"
  node_labels      = ["kubernetes.io/role=master"]
  access_config    = []
  k8s_version      = "${var.k8s_version}"
  add_tags         = ["nat-${var.cluster_name}-${var.zone}"]
  pod_network_type = "${var.pod_network_type}"
  calico_version   = "${var.calico_version}"
  num_nodes        = "1"
  depends_id       = "${join(",", list(module.nat.depends_id, null_resource.route_cleanup.id, null_resource.disk_cleanup.id))}"
}

module "nat" {
  source            = "terraform-nat"
  name              = "nat"
  region            = "${var.region}"
  zone              = "${var.zone}"
  network           = "${var.network}"
  cluster_name      = "${var.cluster_name}"
  master_ip         = "${var.master_ip}"
  master_pem_path   = "${module.master-1.pem_path}"
  ssh_source_ranges = "${var.ssh_source_ranges}"
}

module "gcp-worker-core" {
  source                 = "terraform-worker"
  name                   = "gcp-worker-core"
  project_id             = "${var.project_id}"
  kubeconfig_path        = "${local_file.kubeconfig.filename}"
  cluster_autoscalar_min = 0
  cluster_autoscalar_max = 5
  token-part-1           = "${random_id.token-part-1.hex}"
  token-part-2           = "${random_id.token-part-2.hex}"
  cluster_name           = "${var.cluster_name}"
  master_ip              = "${var.master_ip}"
  network                = "${var.network}"
  region                 = "${var.region}"
  zone                   = "${var.zone}"
  disk_size_gb           = "30"
  machine_type           = "n1-standard-4"
  node_labels            = ["kubernetes.io/role=core", "onepanel.io/machine-type=cpu"]
  access_config          = []
  k8s_version            = "${var.k8s_version}"
  add_tags               = ["nat-${var.cluster_name}-${var.zone}"]
  pod_network_type       = "${var.pod_network_type}"
  calico_version         = "${var.calico_version}"
  num_nodes              = "1"
  depends_id             = "${join(",", list(module.master-1.depends_id, null_resource.route_cleanup.id, null_resource.disk_cleanup.id))}"
}

module "gcp-worker-gpu" {
  source                 = "terraform-worker"
  name                   = "gcp-worker-gpu"
  project_id             = "${var.project_id}"
  kubeconfig_path        = "${local_file.kubeconfig.filename}"
  cluster_autoscalar_min = 0
  cluster_autoscalar_max = 5
  token-part-1           = "${random_id.token-part-1.hex}"
  token-part-2           = "${random_id.token-part-2.hex}"
  cluster_name           = "${var.cluster_name}"
  master_ip              = "${var.master_ip}"
  network                = "${var.network}"
  region                 = "${var.region}"
  zone                   = "${var.zone}"
  disk_size_gb           = "30"
  machine_type           = "n1-standard-4"
  gpu_type               = "nvidia-tesla-k80"
  gpu_count              = "1"
  node_labels            = ["kubernetes.io/role=node", "onepanel.io/machine-type=gpu"]
  access_config          = []
  k8s_version            = "${var.k8s_version}"
  add_tags               = ["nat-${var.cluster_name}-${var.zone}"]
  pod_network_type       = "${var.pod_network_type}"
  calico_version         = "${var.calico_version}"
  num_nodes              = "0"
  depends_id             = "${join(",", list(module.master-1.depends_id, null_resource.route_cleanup.id, null_resource.disk_cleanup.id))}"
}

resource "null_resource" "route_cleanup" {
  // Cleanup the routes after the managed instance groups have been deleted.
  provisioner "local-exec" {
    when    = "destroy"
    command = "gcloud compute routes list --filter='name~k8s-${var.cluster_name}.*' --format='get(name)' | tr '\n' ' ' | xargs -I {} sh -c 'echo Y|gcloud compute routes delete {}' || true"
  }
}

resource "null_resource" "disk_cleanup" {
  // Cleanup the routes after the managed instance groups have been deleted.
  provisioner "local-exec" {
    when    = "destroy"
    command = "gcloud compute disks list --filter='name~k8s-${var.cluster_name}.*' --format='get(name)' | tr '\n' ' ' | xargs -I {} sh -c 'echo Y|gcloud compute disks delete --zone=${var.zone} {}' || true"
  }
}

# Wait for cluster availability
resource "null_resource" "wait-for-cluster-availability" {
  depends_on = ["module.nat"]

  provisioner "local-exec" {
    command = <<EOF
bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://${module.nat.external_ip}:8080)" != "200" ]]; do echo "Waiting for cluster availability!!!"; sleep 10; done'
echo "Wait finished, Create kubeconfig file!!!"
exit 0
EOF
  }
}

resource "local_file" "kubeconfig" {
  depends_on = ["null_resource.wait-for-cluster-availability"]
  filename   = "${path.root}/generated/kubeconfig"

  content = <<EOF
apiVersion: v1
clusters:
- cluster:
    server: http://${module.nat.external_ip}:8080
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
EOF
}

module "kubernetes_dashboard" {
  source          = "kubernetes-dashboard"
  kubeconfig_path = "${local_file.kubeconfig.filename}"
}

module "metric_server" {
  source          = "metric-server"
  kubeconfig_path = "${local_file.kubeconfig.filename}"
}

module "cluster-autoscalar" {
  source          = "cluster-autoscalar"
  kubeconfig_path = "${local_file.kubeconfig.filename}"
}

module "prometheus" {
  source          = "prometheus"
  kubeconfig_path = "${local_file.kubeconfig.filename}"
}

########## Deployment of cluster-autoscaler #####

# Manually add ig's to the below list
# Example - Adding IG to Cluster Autoscaler(CA)
# Add below value in the ig_names list and change module_name with the name you provided to the new IG creation
# - --nodes=${module.module_name.worker_ca_min}:${module.module_name.worker_ca_max}:${var.google_apis_url}/${var.project_id}/zones/${module.module_name.worker_zone}/instanceGroups/${module.module_name.worker_name}
# For removing any IG from CA just remove the respective items from ig_names list

locals {
  ig_names = [
    "- --nodes=${module.gcp-worker-core.worker_ca_min}:${module.gcp-worker-core.worker_ca_max}:${var.google_apis_url}/${var.project_id}/zones/${module.gcp-worker-core.worker_zone}/instanceGroups/${module.gcp-worker-core.worker_name}",
    "- --nodes=${module.gcp-worker-gpu.worker_ca_min}:${module.gcp-worker-gpu.worker_ca_max}:${var.google_apis_url}/${var.project_id}/zones/${module.gcp-worker-gpu.worker_zone}/instanceGroups/${module.gcp-worker-gpu.worker_name}",
  ]
}

data "template_file" "cluster_autoscaler_deploy" {
  template = "${file("deployment.yaml")}"

  vars {
    project_id = "${var.project_id}"

    #to maintain YAML indentation added space, DON'T EDIT
    ig_names = "${join("\n            ", local.ig_names)}"
  }
}

resource "k8s_manifest" "cluster_autoscaler_deploy" {
  status    = "${local_file.kubeconfig.filename}"
  name      = "cluster-autoscaler"
  kind      = "Deployment"
  namespace = "kube-system"
  content   = "${data.template_file.cluster_autoscaler_deploy.rendered}"
}
