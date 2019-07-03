#!/bin/bash

echo -e "\e[34m Install Kafka chart \e[0m"
helm install incubator/kafka -n kafka-hlf --namespace orderer -f ../helm_values/kafka-hlf.yaml
echo -e "\e[34m Please be patient Kafka chart is getting install it migth take upto 10 min\e[0m"
# sleep 500
kubectl wait --for=condition=ready --timeout=800s -n orderer pod/kafka-hlf-0 
kubectl wait --for=condition=ready --timeout=800s -n orderer  pod/kafka-hlf-1


NUM=$1
for i in $(seq 1 $NUM)
do 
echo -e "\e[34m Deploy Orderer$i \e[0m"

echo -e "\e[34m Deploy Orderer$i helm chart \e[0m"
helm install -n educhain${i} hyperledger-charts/orderer --namespace orderer -f ../helm_values/ord${i}.yaml
# sleep 30
ORD_POD=$(kubectl get pods --namespace orderer -l "app=orderer,release=educhain$i" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=220s -n orderer pod/$ORD_POD 
kubectl logs -n orderer $ORD_POD | grep 'Starting orderer'
done

helm install -n ordcli ../../educhain-ordcli --namespace orderer -f ../helm_values/ordcli.yaml

ORD_POD=$(kubectl get pods --namespace orderer -l "app=orderer,release=ordcli" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=220s -n orderer  pod/$ORD_POD

kubectl logs -n orderer $ORD_POD | grep 'Starting orderer'
