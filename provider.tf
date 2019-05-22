#Provider.tf

provider google {
  region  = "${var.region}"
  project = "${var.project_id}"
}

provider google-beta {
  region  = "${var.region}"
  project = "${var.project_id}"
}

provider "k8s" {
  kubeconfig = "${path.root}/generated/kubeconfig"
}
