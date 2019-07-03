#!/bin/bash
echo -e "\e[34m Create NameSpace for Org1\e[0m"

kubectl create ns org1

echo -e "\e[34m Create secret consisting of User Name and Password which is registered on Root CA \e[0m"
echo -e "\e[34m This User will be used to enroll Intermediate CA for Orderer\e[0m"

kubectl create -f ../helm_values/ca-user-secret/org1--ca -n org1

echo -e "\e[34m Import TLS certificate of Root CA into current NameSpace this TLS certificate is imported as secret and mounted on Intermediate CA\e[0m"
kubectl get secret rootca--tls --namespace=root-ca --export -o yaml |\
   kubectl apply --namespace=org1 -f -  --validate=false

echo -e "\e[34m Install Intermediate CA for Org1\e[0m"
helm install ../../ca -n org1ica --namespace org1 -f ../helm_values/org1ca.yaml

echo -e "\e[34m Please be Patient CA is getting installed it migth take upto 1-2 min\e[0m"

# sleep 80

CA_POD=$(kubectl get pods -n org1 -l "app=ca,release=org1ica" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=330s -n org1 pod/$CA_POD

kubectl logs -n org1 $CA_POD | grep "Listening on"

CA_INGRESS=$(kubectl get ingress -n org1 -l "app=ca,release=org1ica" -o jsonpath="{.items[0].spec.rules[0].host}")

echo -e "\e[34m Curl CAINFO\e[0m"
sleep 5
curl https://$CA_INGRESS/cainfo
