#!/bin/bash

echo "Enter Orderer Address"
read ORDERER

echo "Enter Channel Name"
read CHANNEL

echo "Enter Chaincode Name"
read CCNAME

echo "Enter Chaincode Version"
read CC_VER

echo "Enter NameSpace of Org"
read NS

# echo "Enter Release name"
# read RN

echo "Enter Peers Addresse"
read ADD

PEER_POD=$(kubectl get pods --namespace $NS -l "app=cli,release="$NS"cli" -o jsonpath="{.items[0].metadata.name}")

kubectl  exec -n $NS $PEER_POD -- bash -c  "CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin_msp CORE_PEER_ADDRESS=$ADD:7051 peer chaincode instantiate -o $ORDERER:7050 -C $CHANNEL -n $CCNAME -v $CC_VER -c '{\"Args\":[\"\"]}'"