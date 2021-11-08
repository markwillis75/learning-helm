# Chapter 2 - Using Helm

## Install Helm
`
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh`

## Add Chart Repo
`
helm repo add bitnami https://charts.bitnami.com/bitnami  
`

## Search a repo
`
helm search repo drupal  
`

NAME            CHART VERSION   APP VERSION     DESCRIPTION
bitnami/drupal  10.4.2          9.2.8           One of the most versatile open source content m...
