#!/bin/bash


echo  -e "\e[34mEnter Batch Size\e[0m"
read SIZE


ORD_POD=$(kubectl get pods --namespace orderer -l "app=orderer,release=ordcli" -o jsonpath="{.items[0].metadata.name}")

kubectl cp updateBatchSize.sh $ORD_POD:/ -n orderer

kubectl exec -n orderer $ORD_POD -- bash -c './updateBatchSize.sh '$SIZE''