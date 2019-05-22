### Steps for setting up prometheus and demo application:-

kubectl create namespace monitoring

kubectl get pods -n monitoring

kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)

kubectl apply -f clusterRole.yml

kubectl apply -f prometheus-config-map.yml

kubectl apply -f prometheus-deployment.yaml

kubectl apply -f helloworld.yaml

### URL for Prometheus will be found here:

kubectl get svc -n monitoring

http://35.199.157.29:8080

### Search queries that you can use:

{container_name="k8s=demo"}

container_spec_cpu_period{container_name="k8s-demo"}

container_spec_memory_limit_bytes{container_name="k8s-demo"}

