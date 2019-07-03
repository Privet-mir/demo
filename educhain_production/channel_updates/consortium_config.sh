#!/bin/bash
ORG=$1

export CORE_PEER_LOCALMSPID=OrdererMSP 
export CORE_PEER_MSPCONFIGPATH=/var/hyperledger/msp
cd /artifacts

# peer channel fetch config config_block.pb -o orderer1.zx.kmindz.xyz:443 -c testchainid --tls --cafile /var/hyperledger/fabric_cfg/root.pem
peer channel fetch config config_block.pb -o educhain1-orderer.orderer.svc.cluster.local:7050 -c testchainid
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
jq -s '.[0] * {"channel_group":{"groups":{"Consortiums":{"groups": {"EduchainConsortium": {"groups": {"'$ORG'MSP":.[1]}}}}}}}' config.json ./$ORG.json > modified_config.json
configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id testchainid --original config.pb --updated modified_config.pb --output org_update.pb
configtxlator proto_decode --input  org_update.pb --type common.ConfigUpdate | jq . > org_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"testchainid", "type":2}},"data":{"config_update":'$(cat org_update.json)'}}}' | jq . > org_update_in_envelope.json
configtxlator proto_encode --input org_update_in_envelope.json --type common.Envelope --output org_update_in_envelope.pb
peer channel signconfigtx -f org_update_in_envelope.pb
# peer channel update -f org_update_in_envelope.pb -c testchainid -o orderer1.zx.kmindz.xyz:443  --tls --cafile /var/hyperledger/fabric_cfg/root.pem
peer channel update -f org_update_in_envelope.pb -c testchainid -o educhain1-orderer.orderer.svc.cluster.local:7050