# Chapter 3 - Beyond the basics

## Templating and Dry Runs

### 5 Phases of helm install or helm upgrade
1. Load the Chart
2. Parse the values
3. Execute the templates, generating YAML
4. Parse the YAML into k8s objects to validate
5. Send the template to k8s

Some templates require information about the cluster and _may_ contact the k8s API server during rendering

### Values order of precedence
1. --set values
2. -f yaml files
3. values.yaml

### The `--dry-run` Flag
```bash
helm install mysite bitnami/drupal --dry-run
```
Executes all steps with exception of sending rendered YAML to k8s  
`***`  Note that `--dry-run` contacts the k8s API server for validation, so has to have k8s credentials

```bash
# output
LAST DEPLOYED: Sat Nov 13 12:06:34 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
HOOKS:
MANIFEST:
---
# Source: drupal/charts/mariadb/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mysite-mariadb
  namespace: default
  labels:
    app.kubernetes.io/name: mariadb
    helm.sh/chart: mariadb-9.7.0
    app.kubernetes.io/instance: mysite
    app.kubernetes.io/managed-by: Helm
  annotations:
```

### The `helm template` command
```bash
helm template bitnami/drupal
```
Differs from `--dry-run`:
- Never contacts k8s API server
- Always acts like an installation
- Templates and functions which would normally require access to k8s API server, instead return default data
- Chart only has access to k8s default kinds i.e. it does not have access to CRDs (Custom Resource Definitions)
- Does not perform validation 

---

## Learning about a Release
### Release Records
When we install a chart or upgrade an instalation, helm creates a release record in the k8s secret store  
Helm tracks up to 10 revisions of each installation, deleting old release records when necessary
```
kubectl get secret

NAME                           TYPE                                  DATA   AGE
default-token-8zqdx            kubernetes.io/service-account-token   3      18d
mysite-drupal                  Opaque                                1      3m38s
mysite-mariadb                 Opaque                                2      3m38s
mysite-mariadb-token-f9r5p     kubernetes.io/service-account-token   3      3m38s
sh.helm.release.v1.mysite.v1   helm.sh/release.v1                    1      3m38s  # initial install
sh.helm.release.v1.mysite.v2   helm.sh/release.v1                    1      3s     # a subsequent upgrade
```

Reading the release record reveals metadata about the release  
The base64 blob is a gzip of the chart and release
```bash
kubectl get secret -o yaml

apiVersion: v1
data:
  release: <base64-encoded-blob>
  kind: Secret
metadata:
  creationTimestamp: "2021-11-13T12:41:33Z"
  labels:
    modifiedAt: "1636807293"
    name: mysite
    owner: helm
    status: deployed
    version: "2"
  name: sh.helm.release.v1.mysite.v2
  namespace: default
  resourceVersion: "36024"
  uid: 0cba37ec-6781-4eb2-9f51-e1a4fe32ea0d
```

### Listing Releases
```bash
helm list

NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
mysite  default         2               2021-11-13 12:41:33.295875438 +0000 UTC deployed        drupal-10.4.2   9.2.8
```

### More details with `helm get`
Use `helm get` to show more details than helm list  
```bash
Usage:
  helm get [command]

Available Commands:
  all         download all information for a named release
  hooks       download all hooks for a named release
  manifest    download the manifest for a named release
  notes       download the notes for a named release
  values      download the values file for a named release

# the current revision
helm get [command] [installation]

# a specific revision
helm get [command] [installation] --revision 2
```
#### `get notes`
```bash
helm get notes mysite

NOTES:
CHART NAME: drupal
CHART VERSION: 10.4.2
APP VERSION: 9.2.8** Please be patient while the chart is being deployed **

1. Get the Drupal URL:

  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        Watch the status with: 'kubectl get svc --namespace default -w mysite-drupal'

  export SERVICE_IP=$(kubectl get svc --namespace default mysite-drupal --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
  echo "Drupal URL: http://$SERVICE_IP/"

2. Get your Drupal login credentials by running:

  echo Username: user
  echo Password: $(kubectl get secret --namespace default mysite-drupal -o jsonpath="{.data.drupal-password}" | base64 --decode)
```

#### `get values`
```bash
helm get values mysite

USER-SUPPLIED VALUES:
drupalPassword: 4LHlYuUj6C

# get ALL values
helm get values mysite --all

COMPUTED VALUES:
affinity: {}
allowEmptyPassword: true
args: []
certificates:
  args: []
  command: []
  customCAs: []
  customCertificate:
    certificateLocation: /etc/ssl/certs/ssl-cert-snakeoil.pem
...
```

#### `get manifest`
`***`  Returns the manifest generated from the template - *does not return the current state of resources*  
Use ```kubectl get``` to see current state of resources

```bash
helm get manifest mysite

---
# Source: drupal/charts/mariadb/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mysite-mariadb
  namespace: default
  labels:
    app.kubernetes.io/name: mariadb
    helm.sh/chart: mariadb-9.7.0
    app.kubernetes.io/instance: mysite
    app.kubernetes.io/managed-by: Helm
  annotations:
---
# Source: drupal/charts/mariadb/templates/secrets.yaml
apiVersion: v1
kind: Secret
...
```
---

## History and Rollbacks

```bash
helm history mysite

REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
1               Sat Nov 13 12:37:58 2021        superseded      drupal-10.4.2   9.2.8           Install complete
2               Sat Nov 13 12:41:33 2021        deployed        drupal-10.4.2   9.2.8           Upgrade complete
```

```bash
helm rollback mysite 1

Rollback was a success! Happy Helming!
```

Note that `rollback` does not restore a previous snapshot - it submits the configuration used to deploy a particular revision

```bash
helm history mysite
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
1               Sat Nov 13 12:37:58 2021        superseded      drupal-10.4.2   9.2.8           Install complete
2               Sat Nov 13 12:41:33 2021        superseded      drupal-10.4.2   9.2.8           Upgrade complete
3               Sat Nov 13 14:12:59 2021        deployed        drupal-10.4.2   9.2.8           Rollback to 1
```

`***`  On rollback, helm will try to preserve any edits applied to the resources outside helm (e.g via `kubectl`)  
In some cases this can result in merge or overwriting, leading to inconsistency.  
For this reason, hand-editing resources is discouraged

### Keeping History and Rolling Back
`uninstall`
```bash
helm uninstall mysite --keep-history

release "mysite" uninstalled
```

`history`
```bash
helm history mysite

REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
1               Sat Nov 13 12:37:58 2021        superseded      drupal-10.4.2   9.2.8           Install complete
2               Sat Nov 13 12:41:33 2021        superseded      drupal-10.4.2   9.2.8           Upgrade complete
3               Sat Nov 13 14:12:59 2021        uninstalled     drupal-10.4.2   9.2.8           Uninstallation complete
```

`rollback`
```bash
helm rollback mysite 3

Rollback was a success! Happy Helming!
```

`history`
```bash 
helm history mysite

REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
1               Sat Nov 13 12:37:58 2021        superseded      drupal-10.4.2   9.2.8           Install complete
2               Sat Nov 13 12:41:33 2021        superseded      drupal-10.4.2   9.2.8           Upgrade complete
3               Sat Nov 13 14:12:59 2021        uninstalled     drupal-10.4.2   9.2.8           Uninstallation complete
4               Sat Nov 13 14:27:42 2021        deployed        drupal-10.4.2   9.2.8           Rollback to 3
```

---

## Deep Dive into Install and Uninstall

### The `--generate-name` flag
The `--generate-name` flag allows helm to generate a unique name for an installation, based on chart name and timestamp
```bash
helm install bitnami/drupal --generate-name
helm list

NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
drupal-1636814104       default         1               2021-11-13 14:35:06.36180646 +0000 UTC  deployed        drupal-10.4.2   9.2.8
mysite                  default         4               2021-11-13 14:27:42.855665867 +0000 UTC deployed        drupal-10.4.2   9.2.8
```

### The `--name-template` flag
The `--name-template` flag gives control of the unique name generated
```bash
helm install bitnami/drupal --name-template "mysite-{{randAlpha 9 | lower}}"
helm list

NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
drupal-1636814104       default         1               2021-11-13 14:35:06.36180646 +0000 UTC  deployed        drupal-10.4.2   9.2.8
mysite                  default         4               2021-11-13 14:27:42.855665867 +0000 UTC deployed        drupal-10.4.2   9.2.8
mysite-tmtkjnmco        default         1               2021-11-13 14:39:09.696882747 +0000 UTC deployed        drupal-10.4.2   9.2.8
```

### The `--create-namespace` flag
In k8s, no two objects of the same kind within the same namespace can have the same name  
`***`  By default, helm assumes that if you specify a namespace that it already exists

```bash
helm install mysite bitnami/drupal --namespace bob

Error: INSTALLATION FAILED: create: failed to create: namespaces "bob" not found
```

Can override this behaviour with the `--create-namespace` command
```bash
helm install mysite bitnami/drupal --namespace bob --create-namespace

helm list --all-namespaces
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
drupal-1636814104       default         1               2021-11-13 14:35:06.36180646 +0000 UTC  deployed        drupal-10.4.2   9.2.8
mysite                  bob             1               2021-11-13 14:49:01.635213241 +0000 UTC deployed        drupal-10.4.2   9.2.8
mysite                  default         4               2021-11-13 14:27:42.855665867 +0000 UTC deployed        drupal-10.4.2   9.2.8
mysite-tmtkjnmco        default         1               2021-11-13 14:39:09.696882747 +0000 UTC deployed        drupal-10.4.2   9.2.8
```

### The `upgrade --install` flag
The `upgrade --install` flag will install a release if it does not already exist

```bash
helm upgrade --install wordpress bitnami/wordpress

Release "wordpress" does not exist. Installing it now.
```

### The `--wait` and `--atomic` flags
#### `--wait`
By default helm marks a release successful when the k8s API Server accepts the manifests.  
It does not wait until the pods reach `running` state

With the `--wait` flag a release is successful only when
 - k8s accepts the manifest
 - The pods reach `running` state before the helm timeout expires

`--wait` introduces a potential problem
 - Transient issues such a slow image pull may result in a helm release being marked as failed only for k8s to complete the retrieval a few minutes later and successfuly start the app
 - Best practice in CI is to combine `--wait` with a long `--timeout` value of 5-10 minutes

#### `--atomic`
Same behaviour as `--wait` except that it performs rollback to last successful state
 - No assurance that rollback will be successful
 - Also susceptible to transient issues and may trigger unnecessary rollback

### Upgrading with `--force` and `--cleanup-on-fail` flags
#### `--force`
Modifies the k8s behaviour when upgrading a resource that manages pods
 - by default k8s will only restart pods if certain fields have changed
 - `--force` causes k8s to delete pods and create new ones

`***` Will cause downtime, so not recommended for production

#### `--cleanup-on-fail`
Will request deletion of every object that was _newly created_ during the upgrade