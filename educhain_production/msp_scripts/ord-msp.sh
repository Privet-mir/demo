#!/bin/bash

CA_POD=$(kubectl get pods -n orderer -l "app=ca,release=oica" -o jsonpath="{.items[0].metadata.name}")

CA_INGRESS=$(kubectl get ingress -n orderer -l "app=ca,release=oica" -o jsonpath="{.items[0].spec.rules[0].host}")

echo -e "\e[34m Enroll admin for CA \e[0m"
kubectl exec -n orderer $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'

echo -e "\e[34m Register admin identiy for orderer on CA\e[0m"
kubectl exec -n orderer $CA_POD -- fabric-ca-client register --id.name ord-admin --id.secret OrdAdm1nPW --id.attrs 'admin=true:ecert'



echo -e "\e[34m Enroll admin identiy orderer on CA\e[0m"
FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -u https://ord-admin:OrdAdm1nPW@$CA_INGRESS -M ./OrdererMSP
mkdir -p ../config/OrdererMSP/admincerts
cp ../config/OrdererMSP/signcerts/* ../config/OrdererMSP/admincerts

echo -e "\e[34m Create a secret to hold the admin certificate:Orderer Organisation\e[0m"
ORG_CERT=$(ls ../config/OrdererMSP/admincerts/cert.pem)
kubectl create secret generic -n orderer hlf--ord-admincert --from-file=cert.pem=$ORG_CERT
echo -e "\e[34m Create a secret to hold the admin key:Orderer Organisation\e[0m"
ORG_KEY=$(ls ../config/OrdererMSP/keystore/*_sk)
kubectl create secret generic -n orderer hlf--ord-adminkey --from-file=key.pem=$ORG_KEY
echo -e "\e[34m Create a secret to hold the admin key CA certificate:Orderer Organisation\e[0m"
CA_CERT=$(ls ../config/OrdererMSP/cacerts/*.pem)
kubectl create secret generic -n orderer hlf--ord-ca-cert --from-file=cacert.pem=$CA_CERT
echo -e "\e[34m Create a secret to hold the Intermediate CA certificate:Orderer Organisation\e[0m"
INT_CERT=$(ls ../config/OrdererMSP/intermediatecerts/*.pem)
kubectl create secret generic -n orderer hlf--ord-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}


NUM=$1

for i in $(seq 1 $NUM)
do 

echo -e "\e[34m Generating MSP for Orderer${i} \e[0m"

kubectl exec -n orderer $CA_POD -- fabric-ca-client register --id.name ord${i} --id.secret ord${i}_pw --id.type orderer

FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -d -u https://ord${i}:ord${i}_pw@$CA_INGRESS -M ord${i}_MSP
echo -e "\e[34m Save the Orderer certificate in a secret\e[0m"
NODE_CERT=$(ls ../config/ord${i}_MSP/signcerts/*.pem)
kubectl create secret generic -n orderer hlf--ord${i}-idcert --from-file=cert.pem=${NODE_CERT}
echo -e "\e[34m Save the Orderer private key in another secret \e[0m"
NODE_KEY=$(ls ../config/ord${i}_MSP/keystore/*_sk)
kubectl create secret generic -n orderer hlf--ord${i}-idkey --from-file=key.pem=${NODE_KEY}
echo -e "\e[34m Create a secret to hold the Intermediate CA certificate:Orderer Organisation\e[0m"
INT_CERT=$(ls ../config/ord${i}_MSP/intermediatecerts/*.pem)
kubectl create secret generic -n orderer hlf--ord${i}-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}
done