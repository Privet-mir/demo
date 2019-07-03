#!/bin/bash

echo "Enter namespace where CA is deployed"
read NS

echo "Enter app name of CA"
read APP

echo "Enter release name of CA"
read REL

echo "Enter user name you want to revoke"
read USER

echo "Enter reason for revoke"
read REASON

CA_POD=$(kubectl get pods -n $NS -l "app=$APP,release=$REL" -o jsonpath="{.items[0].metadata.name}")

CA_INGRESS=$(kubectl get ingress -n $NS -l "app=$APP,release=$REL" -o jsonpath="{.items[0].spec.rules[0].host}")

# kubectl exec -n $NS $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'

FABRIC_CA_CLIENT_HOME=./$USER fabric-ca-client revoke --revoke.name $USER -r "$REASON" -u https://$CA_INGRESS 