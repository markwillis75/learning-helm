#! /bin/bash
echo "Installing Helm"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

echo "adding bitnami repo"
helm repo add bitnami https://charts.bitnami.com/bitnami  

echo "repo configured"
helm repo ls