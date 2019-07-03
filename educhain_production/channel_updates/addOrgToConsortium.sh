#!/bin/bash
# echo "Enter name of organization you want to add"
# read ORG

ORG=$1
ORD_POD=$(kubectl get pods --namespace orderer -l "app=orderer,release=ordcli" -o jsonpath="{.items[0].metadata.name}")
cp ../NewOrgConfig/temp_config.yaml ../NewOrgConfig/configtx.yaml 
sed -i 's/@@@/'$ORG'/g'  ../NewOrgConfig/configtx.yaml
cd ../NewOrgConfig
configtxgen -printOrg "$ORG"MSP > $ORG.json

kubectl  exec -n orderer $ORD_POD -- bash -c 'mkdir artifacts'
kubectl  cp $ORG.json -n orderer $ORD_POD:/artifacts
kubectl  cp ../channel_updates/consortium_config.sh -n orderer $ORD_POD:/artifacts
kubectl  exec -n orderer $ORD_POD -- bash -c 'cd artifacts && sh consortium_config.sh '$ORG' '