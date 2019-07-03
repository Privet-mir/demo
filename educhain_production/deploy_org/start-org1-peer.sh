#!/bin/bash

NUM=$1

for i in $(seq 1 $NUM)
do
echo -e "\e[34m Fabric org1 \e[0m"

echo -e "\e[34m Install CouchDB chart \e[0m"
helm install -n org1-couchdb${i} ../educhain-couchdb/ --namespace org1 -f ./helm_values/cdb.yaml
sleep 70
CDB_POD=$(kubectl get pods -n org1 -l "app=couchdb,release=org1-couchdb${i}" -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n org1 $CDB_POD | grep 'Apache CouchDB has started on'

echo -e "\e[34m Install Fabric org1 Chart \e[0m"
helm install -n org1peer${i} ../educhain-peer --namespace org1 -f ./helm_values/org1peer${i}.yaml
sleep 60
org1_POD=$(kubectl get pods --namespace org1 -l "app=edu-peer,release=org1peer${i}" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n org1 $org1_POD | grep 'Starting peer'

done

echo -e "\e[34m Fabric Peer cli \e[0m"

helm install -n org1cli ../cli --namespace org1 -f ./helm_values/org1cli.yaml

sleep 60
org1_POD=$(kubectl get pods --namespace org1 -l "app=cli,release=org1cli" -o jsonpath="{.items[0].metadata.name}")
kubectl cp root.pem $org1_POD:/var/hyperledger/fabric_cfg -n org1

kubectl logs -n org1 $org1_POD | grep 'Starting peer'