#!/bin/bash

# echo "Enter name of organization you want to add"
# read ORG

ORG=$1
PEER_POD=$(kubectl get pods --namespace mainorg-peer -l "app=cli,release=mainorg-peercli" -o jsonpath="{.items[0].metadata.name}")
cp ../NewOrgConfig/temp_config.yaml ../NewOrgConfig/configtx.yaml 
sed -i 's/@@@/'$ORG'/g'  ../NewOrgConfig/configtx.yaml
cd ../NewOrgConfig
configtxgen -printOrg "$ORG"MSP > $ORG.json

kubectl  exec -n mainorg-peer $PEER_POD -- bash -c 'mkdir artifacts'

kubectl  cp $ORG.json -n mainorg-peer $PEER_POD:/artifacts

kubectl  cp ../channel_updates/channel_config.sh -n mainorg-peer $PEER_POD:/artifacts
kubectl  exec -n mainorg-peer $PEER_POD -- bash -c 'cd artifacts && sh channel_config.sh '$ORG' '