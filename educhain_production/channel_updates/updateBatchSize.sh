#!/bin/bash

cd artifacts

export CORE_PEER_LOCALMSPID=OrdererMSP
export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/msp


peer channel fetch config config_block.pb -o educhain1-orderer.orderer.svc.cluster.local:7050 -c testchainid

configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json

export MAXBATCHSIZEPATH=".channel_group.groups.Orderer.values.BatchSize.value.max_message_count"

echo -e "\e[34mCurrent Batch size\e[0m"
jq "$MAXBATCHSIZEPATH" config.json

jq "$MAXBATCHSIZEPATH="$1"" config.json > modified_config.json
echo -e "\e[34m Batch size Updated Value\e[0m"
jq "$MAXBATCHSIZEPATH" modified_config.json 

configtxlator proto_encode --input config.json --type common.Config --output config.pb

configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

configtxlator compute_update --channel_id testchainid --original config.pb --updated modified_config.pb --output batchsize_update.pb

configtxlator proto_decode --input batchsize_update.pb --type common.ConfigUpdate | jq . > batchsize_update.json

echo '{"payload":{"header":{"channel_header":{"channel_id":"testchainid", "type":2}},"data":{"config_update":'$(cat batchsize_update.json)'}}}' | jq . > batchsize_update_in_envelope.json

configtxlator proto_encode --input batchsize_update_in_envelope.json --type common.Envelope --output batchsize_update_in_envelope.pb

peer channel signconfigtx -f batchsize_update_in_envelope.pb

peer channel update -f batchsize_update_in_envelope.pb -c testchainid -o educhain1-orderer.orderer.svc.cluster.local:7050
