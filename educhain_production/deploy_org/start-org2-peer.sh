#!/bin/bash

NUM=$1

for i in $(seq 1 $NUM)
do
echo -e "\e[34m Fabric org2 \e[0m"

echo -e "\e[34m Install CouchDB chart \e[0m"
helm install -n org2-couchdb${i} ../educhain-couchdb/ --namespace org2 -f ./helm_values/cdb.yaml
sleep 70
CDB_POD=$(kubectl get pods -n org2 -l "app=couchdb,release=org2-couchdb${i}" -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n org2 $CDB_POD | grep 'Apache CouchDB has started on'
echo -e "\e[34m Install Fabric org2 Chart \e[0m"
helm install -n org2peer${i} ../educhain-peer --namespace org2 -f ./helm_values/org2peer${i}.yaml
sleep 60
org2_POD=$(kubectl get pods --namespace org2 -l "app=edu-peer,release=org2peer${i}" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n org2 $org2_POD | grep 'Starting peer'

done

echo -e "\e[34m Fabric Peer cli \e[0m"

helm install -n org2cli ../cli --namespace org2 -f ./helm_values/org2cli.yaml
sleep 60
org2_POD=$(kubectl get pods --namespace org2 -l "app=cli,release=org2cli" -o jsonpath="{.items[0].metadata.name}")

kubectl cp root.pem $org2_POD:/var/hyperledger/fabric_cfg -n org2

kubectl logs -n org2 $org2_POD | grep 'Starting peer'