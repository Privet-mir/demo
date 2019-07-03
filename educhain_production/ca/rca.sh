#!/bin/bash
echo -e "\e[34m Creating Namespaces\e[0m"
kubectl create ns root-ca

echo -e "\e[34m Install CA\e[0m"
helm install ../../root-ca -n rca --namespace root-ca -f ../helm_values/rca.yaml
echo -e "\e[34m Please be Patient CA is getting installed it migth take upto 1-2 min\e[0m"
CA_POD=$(kubectl get pods -n root-ca  -l "app=rootca,release=rca" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=330s -n root-ca pod/$CA_POD
# sleep 80
kubectl logs -n root-ca $CA_POD | grep "Listening on"

CA_INGRESS=$(kubectl get ingress -n root-ca -l "app=rootca,release=rca" -o jsonpath="{.items[0].spec.rules[0].host}")

echo -e "\e[34m Curl CAINFO\e[0m"
sleep 5
curl https://$CA_INGRESS/cainfo
