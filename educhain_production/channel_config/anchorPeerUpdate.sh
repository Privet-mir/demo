#!/bin/bash

echo "Enter Channel Name"
read CHANNELNAME

echo "Enter NameSpace of Org"
read NS

echo "Enter Release name"
read RN


PEER_POD=$(kubectl get pods --namespace $NS -l "app=educhain,release=$RN" -o jsonpath="{.items[0].metadata.name}")

kubectl  exec -n $NS $PEER_POD -- peer channel fetch 0 /var/hyperledger/educhain-channel.block -c $CHANNELNAME -o educhain1-orderer.orderer.svc.cluster.local:7050

kubectl  exec -n $NS $PEER_POD -- bash -c 'CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer channel join -b /var/hyperledger/educhain-channel.block'

