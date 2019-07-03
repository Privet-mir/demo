#!/bin/bash

NUM=$1

for i in $(seq 1 $NUM)
do
echo -e "\e[34m Fabric org2 \e[0m"

echo -e "\e[34m Install CouchDB chart \e[0m"
helm install -n org2-couchdb${i} hyperledger-charts/couchdb --namespace org2 -f ../helm_values/cdb.yaml
# sleep 70
CDB_POD=$(kubectl get pods -n org2 -l "app=couchdb,release=org2-couchdb${i}" -o jsonpath="{.items[*].metadata.name}")
kubectl wait --for=condition=ready --timeout=360s -n org2  pod/$CDB_POD

kubectl logs -n org2 $CDB_POD | grep 'Apache CouchDB has started on'

CA_POD=$(kubectl get pods -n org2 -l "app=ca,release=org2ica" -o jsonpath="{.items[0].metadata.name}")

CA_INGRESS=$(kubectl get ingress -n org2 -l "app=ca,release=org2ica" -o jsonpath="{.items[0].spec.rules[0].host}")


echo -e "\e[34m Register org2 with CA \e[0m"
kubectl exec -n org2 $CA_POD -- fabric-ca-client register --id.name org2peer${i} --id.secret org2peer${i}_pw --id.type peer
FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -d -u https://org2peer${i}:org2peer${i}_pw@$CA_INGRESS -M org2peer${i}_MSP
echo -e "\e[34m Save the org2 certificate in a secret \e[0m"
NODE_CERT=$(ls ../config/org2peer${i}_MSP/signcerts/*.pem)
kubectl create secret generic -n org2 hlf--org2peer${i}-idcert --from-file=cert.pem=${NODE_CERT}
echo -e "\e[34m Save the org2 private key in another secret \e[0m"
NODE_KEY=$(ls ../config/org2peer${i}_MSP/keystore/*_sk)
kubectl create secret generic -n org2 hlf--org2peer${i}-idkey --from-file=key.pem=${NODE_KEY}
INT_CERT=$(ls ../config/org2peer${i}_MSP/intermediatecerts/*.pem)
kubectl create secret generic -n org2 hlf--org2peer${i}-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}

echo -e "\e[34m Install Fabric org2 Chart \e[0m"
helm install -n org2-peer${i} hyperledger-charts/edu-peer --namespace org2 -f ../helm_values/org2peer${i}.yaml
# sleep 60
org2_POD=$(kubectl get pods --namespace org2 -l "app=edu-peer,release=org2-peer${i}" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=330s -n org2  pod/$org2_POD
kubectl logs -n org2 $org2_POD | grep 'Starting peer'

done

echo -e "\e[34m Fabric Peer cli \e[0m"

helm install -n org2cli ../../cli --namespace org2 -f ../helm_values/org2cli.yaml
# sleep 60
org2_POD=$(kubectl get pods --namespace org2 -l "app=cli,release=org2cli" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=340s -n org2  pod/$org2_POD

kubectl cp ../configk8s/root.pem $org2_POD:/var/hyperledger/fabric_cfg -n org2

kubectl logs -n org2 $org2_POD | grep 'Starting peer'