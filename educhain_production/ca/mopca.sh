#!/bin/bash
echo -e "\e[34m Create NameSpace for Mainorg-Peer\e[0m"

kubectl create ns mainorg-peer

echo -e "\e[34m Create secret consisting of User Name and Password which is registered on Root CA \e[0m"
echo -e "\e[34m This User will be used to enroll Intermediate CA for Orderer\e[0m"

kubectl create -f ../helm_values/ca-user-secret/mopca--ca -n mainorg-peer

echo -e "\e[34m Import TLS certificate of Root CA into current NameSpace this TLS certificate is imported as secret and mounted on Intermediate CA\e[0m"
kubectl get secret rootca--tls --namespace=root-ca --export -o yaml |\
   kubectl apply --namespace=mainorg-peer -f -  --validate=false

echo -e "\e[34m Install Intermediate CA for Mainorg-Peer\e[0m"
helm install ../../ca -n mpica --namespace mainorg-peer -f ../helm_values/mopca.yaml

echo -e "\e[34m Please be Patient CA is getting installed it migth take upto 1-2 min\e[0m"

# sleep 80

CA_POD=$(kubectl get pods -n mainorg-peer -l "app=ca,release=mpica" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=520s -n mainorg-peer pod/$CA_POD

kubectl logs -n mainorg-peer $CA_POD | grep "Listening on"

CA_INGRESS=$(kubectl get ingress -n mainorg-peer -l "app=ca,release=mpica" -o jsonpath="{.items[0].spec.rules[0].host}")

echo -e "\e[34m Curl CAINFO\e[0m"
sleep 5
curl https://$CA_INGRESS/cainfo