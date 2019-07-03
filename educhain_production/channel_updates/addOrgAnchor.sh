#!/bin/bash

# echo "Enter name of organization you want to add"
# read ORG

ORG=$1
PEER_POD=$(kubectl get pods --namespace $ORG -l "app=cli,release="$ORG"cli" -o jsonpath="{.items[0].metadata.name}")
cp temp_anchorpeer.json anchorpeer.json
sed -i 's/@@@/'$ORG'/g'  anchorpeer.json
kubectl  exec -n $ORG $PEER_POD -- bash -c 'mkdir artifacts'

kubectl  cp anchorpeer.json -n $ORG $PEER_POD:/artifacts

kubectl  cp anchorpeer.sh -n $ORG $PEER_POD:/artifacts
kubectl  exec -n $ORG $PEER_POD -- bash -c 'cd artifacts && sh anchorpeer.sh '$ORG' '

