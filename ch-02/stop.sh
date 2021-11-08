#! /bin/bash
helm uninstall mysite

echo "Deleting mariadb pvc"
#Failure to mreove the pvc keeps old secrets around and prevents mariadb from starting subsequently
kubectl delete pvc data-mysite-mariadb-0

minikube stop
docker container rm minikube
