#!/bin/bash
ORG=$1
export CHANNEL_NAME=educhain-channel
export CORE_PEER_LOCALMSPID=MainOrg-devMSP
export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/admin_msp
export CORE_PEER_ADDRESS=mainorg-peer1-edu-peer.mainorg-peer.svc.cluster.local:7051
cd /artifacts
# peer channel fetch config config_block.pb -o orderer1.zx.kmindz.xyz:443 -c educhain-channel --tls --cafile /var/hyperledger/fabric_cfg/root.pem
peer channel fetch config config_block.pb -o educhain1-orderer.orderer.svc.cluster.local:7050 -c educhain-channel 
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"'$ORG'MSP":.[1]}}}}}' config.json ./$ORG.json > modified_config.json
configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id educhain-channel --original config.pb --updated modified_config.pb --output org_update.pb
configtxlator proto_decode --input  org_update.pb --type common.ConfigUpdate | jq . > org_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"educhain-channel", "type":2}},"data":{"config_update":'$(cat org_update.json)'}}}' | jq . > org_update_in_envelope.json
configtxlator proto_encode --input org_update_in_envelope.json --type common.Envelope --output org_update_in_envelope.pb
peer channel signconfigtx -f org_update_in_envelope.pb
# peer channel update -f org_update_in_envelope.pb -c educhain-channel -o orderer1.zx.kmindz.xyz:443  --tls --cafile /var/hyperledger/fabric_cfg/root.pem
peer channel update -f org_update_in_envelope.pb -c educhain-channel -o educhain1-orderer.orderer.svc.cluster.local:7050