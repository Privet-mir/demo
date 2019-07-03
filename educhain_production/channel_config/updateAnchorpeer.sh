#!/bin/bash

ORDERER_IP=$1


PEER_POD=$(kubectl get pods --namespace mainorg-peer -l "app=cli,release=mainorg-peercli" -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n mainorg-peer $PEER_POD -- peer channel update -o $ORDERER_IP:443 -c educhain-channel -f /hl_config/anchor/MainorgMSPanchors.tx --tls --cafile ./root.pem

org1_POD=$(kubectl get pods --namespace org1 -l "app=cli,release=org1cli" -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n org1 $org1_POD -- peer channel update -o $ORDERER_IP:443 -c educhain-channel -f /hl_config/anchor/Org1MSPanchors.tx --tls --cafile ./root.pem

org2_POD=$(kubectl get pods --namespace org2 -l "app=cli,release=org2cli" -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n org2 $org2_POD -- peer channel update -o $ORDERER_IP:443 -c educhain-channel -f /hl_config/anchor/Org2MSPanchors.tx --tls --cafile ./root.pem