#!/bin/bash


echo  "Enter Batch TimeOut"
read TIMEOUT


ORD_POD=$(kubectl get pods --namespace orderer -l "app=orderer,release=ordcli" -o jsonpath="{.items[0].metadata.name}")

kubectl cp updateBatchTimeout.sh $ORD_POD:/ -n orderer

kubectl exec -n orderer $ORD_POD -- bash -c 'sed -i s/seconds/'$TIMEOUT'/g updateBatchTimeout.sh'

kubectl exec -n orderer $ORD_POD -- bash -c './updateBatchTimeout.sh'