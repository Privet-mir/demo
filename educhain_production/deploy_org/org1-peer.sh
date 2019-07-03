#!/bin/bash

NUM=$1

for i in $(seq 1 $NUM)
do
echo -e "\e[34m Fabric org1 \e[0m"

echo -e "\e[34m Install CouchDB chart \e[0m"
helm install -n org1-couchdb${i} hyperledger-charts/couchdb --namespace org1 -f ../helm_values/cdb.yaml
# sleep 70
CDB_POD=$(kubectl get pods -n org1 -l "app=couchdb,release=org1-couchdb${i}" -o jsonpath="{.items[*].metadata.name}")
kubectl wait --for=condition=ready --timeout=420s -n org1  pod/$CDB_POD

kubectl logs -n org1 $CDB_POD | grep 'Apache CouchDB has started on'

CA_POD=$(kubectl get pods -n org1 -l "app=ca,release=org1ica" -o jsonpath="{.items[0].metadata.name}")

CA_INGRESS=$(kubectl get ingress -n org1 -l "app=ca,release=org1ica" -o jsonpath="{.items[0].spec.rules[0].host}")


echo -e "\e[34m Register org1 with CA \e[0m"
kubectl exec -n org1 $CA_POD -- fabric-ca-client register --id.name org1peer${i} --id.secret org1peer${i}_pw --id.type peer
FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -d -u https://org1peer${i}:org1peer${i}_pw@$CA_INGRESS -M org1peer${i}_MSP
echo -e "\e[34m Save the org1 certificate in a secret \e[0m"
NODE_CERT=$(ls ../config/org1peer${i}_MSP/signcerts/*.pem)
kubectl create secret generic -n org1 hlf--org1peer${i}-idcert --from-file=cert.pem=${NODE_CERT}
echo -e "\e[34m Save the org1 private key in another secret \e[0m"
NODE_KEY=$(ls ../config/org1peer${i}_MSP/keystore/*_sk)
kubectl create secret generic -n org1 hlf--org1peer${i}-idkey --from-file=key.pem=${NODE_KEY}
INT_CERT=$(ls ../config/org1peer${i}_MSP/intermediatecerts/*.pem)
kubectl create secret generic -n org1 hlf--org1peer${i}-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}

echo -e "\e[34m Install Fabric org1 Chart \e[0m"
helm install -n org1-peer${i} hyperledger-charts/edu-peer --namespace org1 -f ../helm_values/org1peer${i}.yaml
# sleep 60
org1_POD=$(kubectl get pods --namespace org1 -l "app=edu-peer,release=org1-peer${i}" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=430s -n org1  pod/$org1_POD
kubectl logs -n org1 $org1_POD | grep 'Starting peer'

done

echo -e "\e[34m Fabric Peer cli \e[0m"

helm install -n org1cli ../../cli --namespace org1 -f ../helm_values/org1cli.yaml

# sleep 60
org1_POD=$(kubectl get pods --namespace org1 -l "app=cli,release=org1cli" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=430s -n org1  pod/$org1_POD

kubectl cp ../configk8s/root.pem $org1_POD:/var/hyperledger/fabric_cfg -n org1

kubectl logs -n org1 $org1_POD | grep 'Starting peer'