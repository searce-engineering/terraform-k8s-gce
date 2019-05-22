## Terraform installation

Install Terraform by following this [guide](https://www.terraform.io/downloads.html).

## Go installation

Purpose :- We are installing GO to support custom Kubernetes resource type ‘K8s_manifest’ for resources not supported by terraform.
Install GO using below commands. (GO version > 1.9 is required)
```
curl -O https://storage.googleapis.com/golang/go1.11.2.linux-amd64.tar.gz
tar -xvf go1.11.2.linux-amd64.tar.gz
sudo mv go /usr/local
```

Set Go’s root value, which tells Go where to look for its files.
```
sudo nano ~/.profile
```

Add the below environment variables at the bottom in the opened profile file
```
export GOPATH=$HOME/work
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
```

Run the below command as well to refresh your profile
```
source ~/.profile
```
Verify your installation by
```
go version
```
## Export env variables

This variables are required for terraform to authenticate with GCP project using ‘admin-sa’ service account.
You may require to export them with new terminal sessions.

```
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/admin-sa-key.json"
```
GOPATH variable is required for the installation directory of GO.
```
export GOPATH=$HOME/work
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
```

## K8s_manifest setup

Get this provider on your local system by running below command.
This will take significant time to get all dependencies required by go for terraform usage.

```
go get -u github.com/harishsearce/terraform-provider-k8s
```
Once done create/update the ‘~/.terraformrc’ file with below lines :

```
providers { k8s = "$GOPATH/bin/terraform-provider-k8s" }
```

## Terraform in action :

Set the Kubeconfig paths in main.tf providers as per local file system.
Generally /home/foo/.kube/config

```
provider "k8s" {
  kubeconfig = "/path/to/kubeconfig"
}

provider "kubernetes" {
  config_path = "/path/to/kubeconfig"
}
```

Once all the things are setup as mentioned in above steps, we can proceed with terraform init and apply.

# Applying individual Terraform modules

Change the yaml files specific to the module

## After changing the yaml files execute the below command

terraform get -update

## Applying to individual terraform module

terraform apply -target=module.postgre


