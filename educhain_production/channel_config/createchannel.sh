#!/bin/bash

# echo "Enter Orderer Address"
# read ORDERER_IP

ORDERER_IP=$1

PEER_POD=$(kubectl get pods --namespace mainorg-peer -l "app=cli,release=mainorg-peercli" -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n mainorg-peer $PEER_POD -- peer channel create -o $ORDERER_IP:443 -c educhain-channel -f /hl_config/channel/educhain-channel.tx --tls --cafile ./root.pem

