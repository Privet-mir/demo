#!/bin/bash
echo -e "\e[34m Create NameSpace for Orderer\e[0m"

kubectl create ns orderer

echo -e "\e[34m Create secret consisting of User Name and Password which is registered on Root CA this User will be used to enroll Intermediate CA for Orderer\e[0m"
kubectl create -f ../helm_values/ca-user-secret/ord--ca -n orderer

echo -e "\e[34m Import TLS certificate of Root CA into current NameSpace this TLS certificate is imported as secret and mounted on Intermediate CA\e[0m"
kubectl get secret rootca--tls --namespace=root-ca --export -o yaml |\
   kubectl apply --namespace=orderer -f -  --validate=false

echo -e "\e[34m Install Intermediate CA for Orderer\e[0m"
helm install ../../ca -n oica --namespace orderer -f ../helm_values/oca.yaml

echo -e "\e[34m Please be Patient CA is getting installed it migth take upto 1-2 min\e[0m"
# sleep 60

CA_POD=$(kubectl get pods -n orderer -l "app=ca,release=oica" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=230s -n orderer pod/$CA_POD

kubectl logs -n orderer $CA_POD | grep "Listening on"

CA_INGRESS=$(kubectl get ingress -n orderer -l "app=ca,release=oica" -o jsonpath="{.items[0].spec.rules[0].host}")

echo -e "\e[34m Curl CAINFO\e[0m"
sleep 5
curl https://$CA_INGRESS/cainfo
