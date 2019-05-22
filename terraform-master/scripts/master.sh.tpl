#!/bin/bash -xe

cat <<EOF > /etc/kubernetes/kubeadm.conf
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
kubernetesVersion: v${k8s_version}
cloudProvider: gce
token: ${token}
tokenTTL: "0"
networking:
  serviceSubnet: ${service_cidr}
  podSubnet: ${pod_cidr}
authorizationModes:
- Node
- RBAC
apiServerCertSANs:
- 127.0.0.1
controllerManagerExtraArgs:
  cluster-name: ${instance_prefix}
  allocate-node-cidrs: "true"
  cidr-allocator-type: "RangeAllocator"
  configure-cloud-routes: "false"
  cloud-config: /etc/kubernetes/pki/gce.conf
  cluster-cidr: ${pod_cidr}
  service-cluster-ip-range: ${service_cidr}
  feature-gates: ${feature_gates}
schedulerExtraArgs:
  feature-gates: ${feature_gates}
apiServerExtraArgs:
  feature-gates: ${feature_gates}
EOF
chmod 0600 /etc/kubernetes/kubeadm.conf

echo "checkpoint kubeadm created"

kubeadm init --config /etc/kubernetes/kubeadm.conf

echo "checkpoint kubeadm configured"

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "KUBELET_EXTRA_ARGS= --cloud-provider=gce" > /etc/default/kubelet

echo "checkpoint kubconfig set"

if [ "${pod_network_type}" == "calico" ]; then
  manifest_version=
  [[ ${calico_version} =~ ^2.4 ]] && manifest_version=1.6
  [[ ${calico_version} =~ ^3.5 ]] && manifest_version=1.7
  [[ -z $${manifest_version} ]] && echo "ERROR: Unsupported calico version: ${calico_version}" && exit 1

  kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
  kubectl apply -f https://docs.projectcalico.org/v3.5/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
fi

echo "checkpoint calico installed"

# ClusterRoleBiding for persistent volume provisioner.
kubectl create clusterrolebinding system:controller:persistent-volume-provisioner \
  --clusterrole=system:persistent-volume-provisioner \
  --user system:serviceaccount:kube-system:pvc-protection-controller

echo "checkpoint cluster role binding created"

# kubeadm manages the manifests directory, so add configmap after the init returns.
kubectl create -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-uid
  namespace: kube-system
data:
  provider-uid: ${cluster_uid}
  uid: ${cluster_uid}
EOF

echo "checkpoint config map created"

kubectl label ns kube-system role=master

echo "checkpoint label kube-system applied"
