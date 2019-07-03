#!/bin/bash

NUM=$1

for i in $(seq 1 $NUM)
do
echo -e "\e[34m Fabric Peer$i \e[0m"

echo -e "\e[34m Install CouchDB chart \e[0m"
helm install -n mainorg-couchdb${i} ../educhain-couchdb/ --namespace mainorg-peer -f ./helm_values/cdb.yaml
sleep 70
CDB_POD=$(kubectl get pods -n mainorg-peer -l "app=couchdb,release=mainorg-couchdb${i}" -o jsonpath="{.items[*].metadata.name}")
kubectl logs -n mainorg-peer $CDB_POD | grep 'Apache CouchDB has started on'

echo -e "\e[34m Install Fabric Peer Chart \e[0m"
helm install -n mainorg-peer${i} ../edu-peer --namespace mainorg-peer -f ./helm_values/peer${i}.yaml
sleep 60
PEER_POD=$(kubectl get pods --namespace mainorg-peer -l "app=edu-peer,release=mainorg-peer${i}" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n mainorg-peer $PEER_POD | grep 'Starting peer'

done

echo -e "\e[34m Fabric Peer cli \e[0m"

helm install -n mainorg ../cli --namespace mainorg-peer -f ./helm_values/mainorg-cli.yaml
sleep 60
PEER_POD=$(kubectl get pods --namespace mainorg-peer -l "app=cli,release=mainorg" -o jsonpath="{.items[0].metadata.name}")
kubectl cp root.pem $PEER_POD:/var/hyperledger/fabric_cfg -n mainorg-peer
kubectl logs -n mainorg-peer $PEER_POD | grep 'Starting peer'