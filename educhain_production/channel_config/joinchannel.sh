#!/bin/bash

echo "Enter Orderer Address"
read ORDERER_IP

echo "Enter Channel Name"
read CHANNELNAME

echo "Enter NameSpace of Org"
read NS

# echo "Enter Release name"
# read RN

echo "Enter Peers Addresses Seprated By COMMA"
read ADD

PEER_POD=$(kubectl get pods --namespace $NS -l "app=cli,release="$NS"cli" -o jsonpath="{.items[0].metadata.name}")

kubectl  exec -n $NS $PEER_POD -- peer channel fetch 0 /var/hyperledger/educhain-channel.block -c $CHANNELNAME -o $ORDERER_IP:443 --tls --cafile ./root.pem

for i in $(echo $ADD | sed "s/,/ /g")
do
# kubectl  exec -n $NS $PEER_POD -- bash -c  'CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin_msp CORE_PEER_ADDRESS='$NS'peer'${i}':7051 peer channel join -b /var/hyperledger/educhain-channel.block'
kubectl  exec -n $NS $PEER_POD -- bash -c  'CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin_msp CORE_PEER_ADDRESS='${i}':7051 peer channel join -b /var/hyperledger/educhain-channel.block'

done