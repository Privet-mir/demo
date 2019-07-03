#!/bin/bash

NUM=$1

for i in $(seq 1 $NUM)
do
echo -e "\e[34m Fabric Peer$i \e[0m"

echo -e "\e[34m Install CouchDB chart \e[0m"
helm install -n mainorg-couchdb${i} hyperledger-charts/couchdb --namespace mainorg-peer -f ../helm_values/cdb.yaml
# sleep 70
CDB_POD=$(kubectl get pods -n mainorg-peer -l "app=couchdb,release=mainorg-couchdb${i}" -o jsonpath="{.items[*].metadata.name}")
kubectl wait --for=condition=ready --timeout=320s -n mainorg-peer  pod/$CDB_POD
kubectl logs -n mainorg-peer $CDB_POD | grep 'Apache CouchDB has started on'

CA_POD=$(kubectl get pods -n mainorg-peer -l "app=ca,release=mpica" -o jsonpath="{.items[0].metadata.name}")
CA_INGRESS=$(kubectl get ingress -n mainorg-peer -l "app=ca,release=mpica" -o jsonpath="{.items[0].spec.rules[0].host}")

echo -e "\e[34m Register peer with CA \e[0m"
kubectl exec -n mainorg-peer $CA_POD -- fabric-ca-client register --id.name peer${i} --id.secret peer${i}_pw --id.type peer
FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -d -u https://peer${i}:peer${i}_pw@$CA_INGRESS -M peer${i}_MSP
echo -e "\e[34m Save the Peer certificate in a secret \e[0m"
NODE_CERT=$(ls ../config/peer${i}_MSP/signcerts/*.pem)
kubectl create secret generic -n mainorg-peer hlf--peer${i}-idcert --from-file=cert.pem=${NODE_CERT}
echo -e "\e[34m Save the Peer private key in another secret \e[0m"
NODE_KEY=$(ls ../config/peer${i}_MSP/keystore/*_sk)
kubectl create secret generic -n mainorg-peer hlf--peer${i}-idkey --from-file=key.pem=${NODE_KEY}
INT_CERT=$(ls ../config/peer${i}_MSP/intermediatecerts/*.pem)
kubectl create secret generic -n mainorg-peer hlf--peer${i}-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}

echo -e "\e[34m Install Fabric Peer Chart \e[0m"
helm install -n mainorg-peer${i} hyperledger-charts/edu-peer --namespace mainorg-peer -f ../helm_values/peer${i}.yaml
# sleep 60
PEER_POD=$(kubectl get pods --namespace mainorg-peer -l "app=edu-peer,release=mainorg-peer${i}" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=330s -n mainorg-peer  pod/$PEER_POD
kubectl logs -n mainorg-peer $PEER_POD | grep 'Starting peer'

done

echo -e "\e[34m Fabric Peer cli \e[0m"

helm install -n mainorg-peercli ../../cli --namespace mainorg-peer -f ../helm_values/mainorg-cli.yaml
# sleep 60
PEER_POD=$(kubectl get pods --namespace mainorg-peer -l "app=cli,release=mainorg-peercli" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=320s -n mainorg-peer  pod/$PEER_POD
kubectl cp ../configk8s/root.pem $PEER_POD:/var/hyperledger/fabric_cfg -n mainorg-peer
kubectl logs -n mainorg-peer $PEER_POD | grep 'Starting peer'