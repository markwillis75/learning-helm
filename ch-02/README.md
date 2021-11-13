# Chapter 2 - Using Helm

## Install Helm
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
---

## Add Chart Repo
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami  
```

---

## Search a repo
```bash
helm search repo drupal  

NAME            CHART VERSION   APP VERSION     DESCRIPTION
bitnami/drupal  10.4.2          9.2.8           One of the most versatile open source content m...
```

---

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

---

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

---

## Upgrade an Installation
Upgrading an installation can involve, either individually or at the same time
- upgrading the version of the chart
- upgrading the configuration of the installation

Executing an upgrade creates a new release of the installation

### Upgrade the configuration of an installation
```bash
export DRUPAL_PASSWORD=$(kubectl get secret --namespace "default" mysite-drupal -o jsonpath="{.data.drupal-password}" | base64 --decode)

# an upgrade of the configuration of the installation
helm upgrade mysite bitnami/drupal --set ingress.enabled=false --set drupalPassword=$DRUPAL_PASSWORD

Release "mysite" has been upgraded. Happy Helming!
NAME: mysite
LAST DEPLOYED: Wed Nov 10 15:53:18 2021
NAMESPACE: default
STATUS: deployed
REVISION: 2  # Note that the revision/release has changed
TEST SUITE: None
NOTES:
CHART NAME: drupal
CHART VERSION: 10.4.2
APP VERSION: 9.2.8** Please be patient while the chart is being deployed **
```

### Upgrade the version of the chart
```bash
# update the repo - assuming that updating the repo found a newer version of bitnami/drupal
helm repo update
helm upgrade mysite bitnami/drupal

# it's possible to pin to a version even if a new version is available
helm upgrade mysite bitnami/drupal --version 6.2.22
```

### Configuration values and upgrades
```bash
helm install mysite bitnami/drupal --values values.yaml

# the upgrade will create a new release, setting any override properties to their default
helm upgrade mysite bitnami/drupal

# recommended to perform install and upgrade with consistent configuration
helm upgrade mysite bitnami/drupal --values values.yaml
```

---

## Uninstall an Installation
```bash
helm uninstall mysite

# uninstall from a specific namespace
helm uninstall mysite --namespace other
```

---

## How Helm Stores Release Information
```bash
# Helm creates a record for each release.  Stored as k8s secret by default, but other backends are available
kubectl get secret

NAME                           TYPE                                  DATA   AGE
default-token-8zqdx            kubernetes.io/service-account-token   3      16d
mysite-drupal                  Opaque                                1      5h50m
mysite-mariadb                 Opaque                                2      5h50m
mysite-mariadb-token-cfcx7     kubernetes.io/service-account-token   3      5h50m
sh.helm.release.v1.mysite.v1   helm.sh/release.v1                    1      5h50m
sh.helm.release.v1.mysite.v2   helm.sh/release.v1                    1      5h14m
sh.helm.release.v1.mysite.v3   helm.sh/release.v1                    1      12m
sh.helm.release.v1.mysite.v4   helm.sh/release.v1                    1      12m

# Helm uninstall loads the release record for the most recent release and determines which objects should be removed from k8s
# It then deletes those objects before deleting all release records
# Release records can be retained if desired
helm uninstal mysite --keep-history
```