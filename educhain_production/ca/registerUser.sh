#!/bin/bash

echo "Enter namespace where CA is deployed"
read NS

echo "Enter app name of CA"
read APP

echo "Enter release name of CA"
read REL

echo "Enter user name you want to create"
read USER

echo "Enter password for user"
read PASS

echo "Enter common name"
read CN

echo "Enter host name"
read HOST

echo "Enter country name"
read COUNTRY

echo "Enter state name"
read STATE

echo "Enter org name"
read ORGNAME

CA_POD=$(kubectl get pods -n $NS -l "app=$APP,release=$REL" -o jsonpath="{.items[0].metadata.name}")

CA_INGRESS=$(kubectl get ingress -n $NS -l "app=$APP,release=$REL" -o jsonpath="{.items[0].spec.rules[0].host}")

# kubectl exec -n $NS $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'

kubectl exec -n $NS $CA_POD -- fabric-ca-client register --id.name $USER --id.secret $PASS --id.attrs 'admin=true:ecert'

mkdir $USER
cp config/Lets_Encrypt_Authority_X3.pem $USER/
cp config/fabric-ca-client-config.yaml $USER/
FABRIC_CA_CLIENT_HOME=./$USER fabric-ca-client enroll -u https://$USER:$PASS@$CA_INGRESS  --csr.cn $CN --csr.hosts $HOST --csr.names C=$COUNTRY,O=$ORGNAME,ST=$STATE