# Chapter 2 - Using Helm

## Install Helm
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

## Add Chart Repo
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami  
```

## Search a repo
```bash
helm search repo drupal  

NAME            CHART VERSION   APP VERSION     DESCRIPTION
bitnami/drupal  10.4.2          9.2.8           One of the most versatile open source content m...
```

## Install a package
```bash
# By default, helm will install to the default namespace
helm install mysite bitnami/drupal

NAME: mysite
LAST DEPLOYED: Wed Nov 10 15:18:00 2021
NAMESPACE: default  # default namespace
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: drupal
CHART VERSION: 10.4.2
APP VERSION: 9.2.8** Please be patient while the chart is being deployed **

# When working with helm, use --namespace or -n flag to specify the namespace
kubectl create ns other
helm install --namespace other mysite bitnami/drupal
```

### Override using values.yaml

```yaml
//values.yaml

drupalUsername: admin
drupalEmail: admin@example.com
mariadb:
  db:
    name: my-database
```
```bash
helm install mysite bitnami/drupal --values ./values.yaml
```

### Using inline overrides
```bash
helm install mysite bitnami/drupal --set drupalUsername=admin mariadb.db.name=my-database
```

## Listing Installations
```bash
# By default, helm will list only installations in the default keyspace
helm list

NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
mysite  default         1               2021-11-10 15:18:00.615115516 +0000 UTC deployed        drupal-10.4.2   9.2.8

# List installations in ALL namespaces
helm list --all-namespaces

NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
mysite  default         1               2021-11-10 15:18:00.615115516 +0000 UTC deployed        drupal-10.4.2   9.2.8
mysite  other           1               2021-11-10 15:29:51.822350106 +0000 UTC deployed        drupal-10.4.2   9.2.8
```

## Upgrade an Installation
```bash
export DRUPAL_PASSWORD=$(kubectl get secret --namespace "default" mysite-drupal -o jsonpath="{.data.drupal-password}" | base64 --decode)

helm upgrade mysite bitnami/drupal --set ingress.enabled=false --set drupalPassword=$DRUPAL_PASSWORD

Release "mysite" has been upgraded. Happy Helming!
NAME: mysite
LAST DEPLOYED: Wed Nov 10 15:53:18 2021
NAMESPACE: default
STATUS: deployed
REVISION: 2  # Note that the revision has changed
TEST SUITE: None
NOTES:
CHART NAME: drupal
CHART VERSION: 10.4.2
APP VERSION: 9.2.8** Please be patient while the chart is being deployed **
```