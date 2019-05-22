#!/bin/bash -xe

# Enable ip forwarding and nat
sysctl -w net.ipv4.ip_forward=1

echo "checkpoint ip forwarding enabled"


# Make forwarding persistent.
sed -i= 's/^[# ]*net.ipv4.ip_forward=[[:digit:]]/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "checkpoint ip forwarding made persistent"

#add kubectl repo
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list


echo "checkpoint added kubectl repo"

sudo apt-get update


echo "checkpoint apt-get update complete"

#install kubectl for proxy
sudo apt-get install -y kubectl

echo "checkpoint kubectl installed"


# Install nginx for instance http health check
apt-get install -y nginx


echo "checkpoint nginx for health check installed"

ENABLE_SQUID="${squid_enabled}"

if [[ "$$ENABLE_SQUID" == "true" ]]; then
  apt-get install -y squid3

  cat - > /etc/squid/squid.conf <<'EOM'
${file("${squid_config == "" ? "${format("%s/config/squid.conf", module_path)}" : squid_config}")}
EOM

  systemctl reload squid
fi

#transfer master pem filename
touch ~/master.pem
cat - > ~/master.pem <<'EOM'
${file("${master_pem_path}")}
EOM

echo "checkpoint master.pem added"

chmod 400 ~/master.pem

sleep 150

mkdir ~/.ssh

ssh-keyscan -H "${master_ip}" >> ~/.ssh/known_hosts


echo "checkpoint ssh-keyscan in master"

#wait for master to be ready
while :; do
    (scp -i ~/master.pem root@"${master_ip}":/etc/kubernetes/admin.conf ~/ &> /dev/null) && break
    sleep 2
done

echo "checkpoint admin.conf copied to nat"

export KUBECONFIG=~/admin.conf


echo "checkpoint KUBECONFIG Set"

# setup kube proxy
kubectl proxy --address='0.0.0.0' --port=8080 --accept-hosts='.*' &

echo "checkpoint kube proxy enabled"
