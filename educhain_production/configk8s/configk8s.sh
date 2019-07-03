#!/bin/bash

kubectl create -f ./helm-rbac.yaml

helm init --service-account tiller

helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/

helm repo add hyperledger-charts https://kmindz.github.io/hyperledger-charts

helm repo update

kubectl apply   -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml

helm install stable/nginx-ingress -n nginx-ingress --namespace ingress-controller
sleep 5
helm install stable/cert-manager -n cert-manager --namespace cert-manager

sleep 20

kubectl create -f ../extra/certManagerCI_staging.yaml

sleep 10

kubectl create -f ../extra/certManagerCI_production.yaml

IP=$(kubectl get service nginx-ingress-controller --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}" -n ingress-controller)

echo "Your NGINX Ingress External IP is"
echo -e "\e[34m $IP \e[0m"