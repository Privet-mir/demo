#!/bin/bash

###Org1
CA_POD=$(kubectl get pods -n org1 -l "app=ca,release=org1ica" -o jsonpath="{.items[0].metadata.name}")
CA_INGRESS=$(kubectl get ingress -n org1 -l "app=ca,release=org1ica" -o jsonpath="{.items[0].spec.rules[0].host}")

kubectl exec -n org1 $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'

echo -e "\e[34m Register peer identiy on CA\e[0m"
kubectl exec -n org1 $CA_POD -- fabric-ca-client register --id.name peer-admin --id.secret PeerAdm1nPW --id.attrs 'admin=true:ecert'


echo -e "\e[34m Enroll peer organization admin identiy on CA\e[0m"
FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -u https://peer-admin:PeerAdm1nPW@$CA_INGRESS -M ./Org1MSP
mkdir -p ../config/Org1MSP/admincerts
cp ../config/Org1MSP/signcerts/* ../config/Org1MSP/admincerts


echo -e "\e[34m Create a secret to hold the admincert:Peer Organisation\e[0m"
ORG_CERT=$(ls ../config/Org1MSP/admincerts/cert.pem)
kubectl create secret generic -n org1 hlf--peer-admincert --from-file=cert.pem=$ORG_CERT
echo -e "\e[34m Create a secret to hold the admin key:Peer Organisation\e[0m"
ORG_KEY=$(ls ../config/Org1MSP/keystore/*_sk)
kubectl create secret generic -n org1 hlf--peer-adminkey --from-file=key.pem=$ORG_KEY
echo -e "\e[34m Create a secret to hold the CA certificate:Peer Organisation\e[0m"
CA_CERT=$(ls ../config/Org1MSP/cacerts/*.pem)
kubectl create secret generic -n org1 hlf--peer-ca-cert --from-file=cacert.pem=$CA_CERT
INT_CERT=$(ls ../config/Org1MSP/intermediatecerts/*.pem)
kubectl create secret generic -n org1 hlf--peer1-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}



### Org2

CA_POD=$(kubectl get pods -n org2 -l "app=ca,release=org2ica" -o jsonpath="{.items[0].metadata.name}")
CA_INGRESS=$(kubectl get ingress -n org2 -l "app=ca,release=org2ica" -o jsonpath="{.items[0].spec.rules[0].host}")

kubectl exec -n org2 $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'

echo -e "\e[34m Register peer identiy on CA\e[0m"
kubectl exec -n org2 $CA_POD -- fabric-ca-client register --id.name peer-admin --id.secret PeerAdm1nPW --id.attrs 'admin=true:ecert'

echo -e "\e[34m Enroll peer organization admin identiy on CA\e[0m"
FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -u https://peer-admin:PeerAdm1nPW@$CA_INGRESS -M ./Org2MSP
mkdir -p ../config/Org2MSP/admincerts
cp ../config/Org2MSP/signcerts/* ../config/Org2MSP/admincerts


echo -e "\e[34m Create a secret to hold the admincert:Peer Organisation\e[0m"
ORG_CERT=$(ls ../config/Org2MSP/admincerts/cert.pem)
kubectl create secret generic -n org2 hlf--peer-admincert --from-file=cert.pem=$ORG_CERT
echo -e "\e[34m Create a secret to hold the admin key:Peer Organisation\e[0m"
ORG_KEY=$(ls ../config/Org2MSP/keystore/*_sk)
kubectl create secret generic -n org2 hlf--peer-adminkey --from-file=key.pem=$ORG_KEY
echo -e "\e[34m Create a secret to hold the CA certificate:Peer Organisation\e[0m"
CA_CERT=$(ls ../config/Org2MSP/cacerts/*.pem)
kubectl create secret generic -n org2 hlf--peer-ca-cert --from-file=cacert.pem=$CA_CERT
INT_CERT=$(ls ../config/Org2MSP/intermediatecerts/*.pem)
kubectl create secret generic -n org2 hlf--peer-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}




## Mainorg Peer
CA_POD=$(kubectl get pods -n mainorg-peer -l "app=ca,release=mpica" -o jsonpath="{.items[0].metadata.name}")
CA_INGRESS=$(kubectl get ingress -n mainorg-peer -l "app=ca,release=mpica" -o jsonpath="{.items[0].spec.rules[0].host}")

kubectl exec -n mainorg-peer $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'


echo -e "\e[34m Register peer identiy on CA\e[0m"
kubectl exec -n mainorg-peer $CA_POD -- fabric-ca-client register --id.name peer-admin --id.secret PeerAdm1nPW --id.attrs 'admin=true:ecert'

echo -e "\e[34m Enroll peer organization admin identiy on CA\e[0m"
FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -u https://peer-admin:PeerAdm1nPW@$CA_INGRESS -M ./PeerMSP
mkdir -p ../config/PeerMSP/admincerts
cp ../config/PeerMSP/signcerts/* ../config/PeerMSP/admincerts

echo -e "\e[34m Create a secret to hold the admincert:Peer Organisation\e[0m"
ORG_CERT=$(ls ../config/PeerMSP/admincerts/cert.pem)
kubectl create secret generic -n mainorg-peer hlf--peer-admincert --from-file=cert.pem=$ORG_CERT
echo -e "\e[34m Create a secret to hold the admin key:Peer Organisation\e[0m"
ORG_KEY=$(ls ../config/PeerMSP/keystore/*_sk)
kubectl create secret generic -n mainorg-peer hlf--peer-adminkey --from-file=key.pem=$ORG_KEY
echo -e "\e[34m Create a secret to hold the CA certificate:Peer Organisation\e[0m"
CA_CERT=$(ls ../config/PeerMSP/cacerts/*.pem)
kubectl create secret generic -n mainorg-peer hlf--peer-ca-cert --from-file=cacert.pem=$CA_CERT
INT_CERT=$(ls ../config/PeerMSP/intermediatecerts/*.pem)
kubectl create secret generic -n mainorg-peer hlf--peer-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}
