#!/bin/bash

echo "Enter namespace where CA is deployed"
read NS

echo "Enter app name of CA"
read APP

echo "Enter release name of CA"
read REL

CA_POD=$(kubectl get pods -n $NS -l "app=$APP,release=$REL" -o jsonpath="{.items[0].metadata.name}")

CA_INGRESS=$(kubectl get ingress -n $NS -l "app=$APP,release=$REL" -o jsonpath="{.items[0].spec.rules[0].host}")

# kubectl exec -n $NS $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'

kubectl exec -n $NS $CA_POD -- bash -c 'fabric-ca-client gencrl -u http://$SERVICE_DNS:7054'

# FABRIC_CA_CLIENT_HOME=./$USER fabric-ca-client identity list -u https://$CA_INGRESS 