#!/bin/bash

echo "Enter Chaincode PATH"
read CC_PATH

echo "Enter Chaincode Name"
read CCNAME

echo "Enter Chaincode Version"
read CC_VER

echo "Enter NameSpace of Org"
read NS

# echo "Enter Release name"
# read RN

echo "Enter Peers Addresses Seprated By COMMA"
read ADD

PEER_POD=$(kubectl get pods --namespace $NS -l "app=cli,release="$NS"cli" -o jsonpath="{.items[0].metadata.name}")

echo $PEER_POD
kubectl cp $CC_PATH $PEER_POD:/ -n $NS
# kubectl  exec -n $NS $PEER_POD -- peer channel fetch 0 /var/hyperledger/educhain-channel.block -c $CHANNELNAME -o $ORDERER_IP:443 --tls --cafile ./root.pem
kubectl  exec -n $NS $PEER_POD -- bash -c  'mkdir '$CCNAME''
kubectl cp $CC_PATH $PEER_POD:/$CCNAME -n $NS
kubectl  exec -n $NS $PEER_POD -- bash -c  'mv '$CCNAME' /opt/gopath/src'

for i in $(echo $ADD | sed "s/,/ /g")
do
# kubectl  exec -n $NS $PEER_POD -- bash -c  'CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin_msp CORE_PEER_ADDRESS='$NS'peer'${i}':7051 peer channel join -b /var/hyperledger/educhain-channel.block'
kubectl  exec -n $NS $PEER_POD -- bash -c  'CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin_msp CORE_PEER_ADDRESS='${i}':7051 peer chaincode install -n '$CCNAME' -v '$CC_VER' -p '$CCNAME' '

done