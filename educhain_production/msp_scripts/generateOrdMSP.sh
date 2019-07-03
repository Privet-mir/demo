#!/bin/bash

NUM=$1
CA_POD=$(kubectl get pods -n orderer -l "app=ca,release=oica" -o jsonpath="{.items[0].metadata.name}")

CA_INGRESS=$(kubectl get ingress -n orderer -l "app=ca,release=oica" -o jsonpath="{.items[0].spec.rules[0].host}")

for i in $NUM
do 

echo -e "\e[34m Generating MSP for Orderer${i} \e[0m"

kubectl exec -n orderer $CA_POD -- fabric-ca-client register --id.name ord${i} --id.secret ord${i}_pw --id.type orderer

FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -d -u https://ord${i}:ord${i}_pw@$CA_INGRESS -M ord${i}_MSP
echo -e "\e[34m Save the Orderer certificate in a secret\e[0m"
NODE_CERT=$(ls ./config/ord${i}_MSP/signcerts/*.pem)
kubectl create secret generic -n orderer hlf--ord${i}-idcert --from-file=cert.pem=${NODE_CERT}
echo -e "\e[34m Save the Orderer private key in another secret \e[0m"
NODE_KEY=$(ls ./config/ord${i}_MSP/keystore/*_sk)
kubectl create secret generic -n orderer hlf--ord${i}-idkey --from-file=key.pem=${NODE_KEY}
echo -e "\e[34m Create a secret to hold the Intermediate CA certificate:Orderer Organisation\e[0m"
INT_CERT=$(ls ./config/ord${i}_MSP/intermediatecerts/*.pem)
kubectl create secret generic -n orderer hlf--ord${i}-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}
done