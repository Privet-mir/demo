#!/bin/bash

helm ls --short > helm_rel

HELM=$(cat helm_rel | grep -Ev "cert-manager|nginx-ingress")

for i in $HELM
do
helm del --purge $i
done

sleep 10

NAMESPACE=$(kubectl get ns -o jsonpath="{.items[*].metadata.name}")

TEAR=$(echo $NAMESPACE | sed 's/\(kube-public\|kube-system\|default\|ingress-controller\|cert-manager\)//g')

kubectl delete ns $TEAR
