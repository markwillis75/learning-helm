#! /bin/bash
minikube start

printf "\nExecuting helm install\n"
helm install mysite bitnami/drupal

sleep 10 # give helm a chance

printf "\nWaiting for pods to be ready\n"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=drupal --timeout=150s

podsReady=$?
if [ ${podsReady} -eq 0 ]
then
    printf "\tPods ready\n"
else
    printf "\tFailed to start pods: ${podsReady}\n" >&2
    exit -1
fi

printf "\nPod details\n"
kubectl get pods

sleep 10 #give the service a chance to start
kubectl port-forward service/mysite-drupal 8080:80 &
printf "\nDrupal available on http://127.0.0.1:8080\n"
printf "\tUsername: user\n"
printf "\tPassword: $(kubectl get secret --namespace default mysite-drupal -o jsonpath="{.data.drupal-password}" | base64 --decode)\n\n"
