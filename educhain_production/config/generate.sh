
configtxgen -profile ComposerOrdererGenesis -outputBlock ./genesis.block
configtxgen -profile EduchainChannel -channelID educhain-channel -outputCreateChannelTx ./educhain-channel.tx
configtxgen -profile EduchainChannel -outputAnchorPeersUpdate MainorgMSPanchors.tx -channelID educhain-channel -asOrg MainOrg-dev
configtxgen -profile EduchainChannel -outputAnchorPeersUpdate Org1MSPanchors.tx -channelID educhain-channel -asOrg Org1
configtxgen -profile EduchainChannel -outputAnchorPeersUpdate Org2MSPanchors.tx -channelID educhain-channel -asOrg Org2
echo -e "\e[34m Save them as secret \e[0m"
kubectl create secret generic -n orderer hlf--genesis --from-file=genesis.block
kubectl create secret generic -n mainorg-peer hlf--channel --from-file=educhain-channel.tx
kubectl create secret generic -n mainorg-peer hlf--anchor --from-file=MainorgMSPanchors.tx
kubectl create secret generic -n org1 hlf--anchor --from-file=Org1MSPanchors.tx
kubectl create secret generic -n org2 hlf--anchor --from-file=Org2MSPanchors.tx