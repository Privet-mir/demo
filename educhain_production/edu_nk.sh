#!/bin/bash

printHelp()
{
    echo -e "\e[34m HELP \e[0m"
    echo -e "To Configure k8s "
    echo -e "\e[34m./edu_nk.sh configk8s \e[0m"
    echo -e "To bootstrap complete network "
    echo -e "\e[34m ./edu_nk.sh bootstrap\e[0m"
    echo -e " Deploy CA cluster"
    echo -e "\e[34m ./edu_nk.sh ca\e[0m"
    echo -e " Generate MSP "
    echo -e "\e[34m ./edu_nk.sh msp\e[0m"
    echo -e " Generate channel and genesis block"
    echo -e "\e[34m ./edu_nk.sh config\e[0m"
    echo -e " Deploy Orderer Cluster"
    echo -e "\e[34m ./edu_nk.sh orderer\e[0m"
    echo -e " Deploy Organizations with 2 peers "
    echo -e "\e[34m ./edu_nk.sh organization\e[0m"
    echo -e " Create Channel "
    echo -e "\e[34m ./edu_nk.sh create-channel\e[0m"
    echo -e " Join Channel "
    echo -e "\e[34m ./edu_nk.sh join-channel\e[0m"
    echo -e " Update anchor peer for mainorg-peer org1 and org2 "
    echo -e "\e[34m ./edu_nk.sh update\e[0m"
    echo -e " Install Chaincode "
    echo -e "\e[34m ./edu_nk.sh installcc \e[0m"
    echo -e " Instantiate Chaincode "
    echo -e "\e[34m ./edu_nk.sh instantiatecc\e[0m" 
    echo -e " Add New Org "
    echo -e "\e[34m ./edu_nk.sh addOrg\e[0m"
    echo -e " Add New Orderer "
    echo -e "\e[34m ./edu_nk.sh add-orderer\e[0m"
    echo -e " Update Batch Size"
    echo -e "\e[34m ./edu_nk.sh batch-size\e[0m"
    echo -e " Update Batch Timeout "
    echo -e "\e[34m ./edu_nk.sh batch-timeout\e[0m"
    echo -e " Bring Down Complete Network "
    echo -e "\e[34m ./edu_nk.sh down\e[0m"

}

deployCA()
{
    # Deploying CA
    cd ca
    echo -e "\e[34m Deploying Root CA\e[0m"
    ./rca.sh
    if [ $? != 0 ]; then
        echo -e "\e[34m Curl has failed Please verify endpoint manually \e[0m"
        echo -e "\e[34m Type cont to continue, type exit or type redo to configure network again\e[0m"
        read ANS
        if [ "$ANS" == "cont" ]; then
            echo -e "\e[34m Deploymeny migth Fail please becuase CA has encountered some error\e[0m"
        elif [ "$ANS" == "exit" ]; then
            exit 
        elif [ "$ANS" == "redo" ]; then
            cd ..
            ./edu_nk.sh down
            echo -e "\e[34m Enter your current DNS\e[0m"
            read CURR_DNS
            echo -e "\e[34m Enter your new DNS\e[0m"
            read NEW_DNS
            cd ..
            grep -rl $CURR_DNS educhain_production/ | xargs sed -i 's/'$CURR_DNS'/'$NEW_DNS'/g'
            exit
        else
            echo -e "\e[34m Type correct ANSwer\e[0m"
            exit
        fi
    fi
    echo -e "\e[34m Deploying Orderer Intermediate CA\e[0m"
    ./ocauser.sh
    ./oca.sh
    echo -e "\e[34m Deploying Mainorg Intermediate CA\e[0m"
    ./mainorgcauser.sh
    ./mopca.sh
    echo -e "\e[34m Deploying Org1 Intermediate CA\e[0m"
    ./org1causer.sh
    ./org1ca.sh
    echo -e "\e[34m Deploying Org2 Intermediate CA\e[0m"
    ./org2causer.sh
    ./org2ca.sh
    cd ..
}

generateMSP()
{
    #Generate MSP for 3 Orderers, MainOrg-peer, Org1 and Org2
    cd msp_scripts
    # generate orderer MSP
    ./ord-msp.sh 3
    # generate msp for mainorg-peer org1 and org2
    ./peer-msp.sh
    cd ..
}

networkConfig()
{
    # Generate genesis block and channel file and anchor peer file
    cd config
    ./generate.sh
    cd ..
}

deployOrderer()
{
    # This will deploy kafka zookeeper cluster and 3 orderer
    cd deploy_org
    ./orderer.sh 3
    cd ..
}

addOrderer()
{
    cd deploy_org
    ./new_ord.sh
}

deployOrg()
{
    # This will deploy kafka zookeeper cluster and 3 orderer
    cd deploy_org
    ./mainorg-peer.sh 2
    ./org1-peer.sh 2
    ./org2-peer.sh 2
    cd ..
}

bootstrapNetwork()
{
    # Deploy Complete Network
    deployCA
    generateMSP
    networkConfig
    deployOrderer
    deployOrg
    check
}

configK8s()
{
    # configure k8s
    cd configk8s
    ./configk8s.sh
    cd ..
}

createChannel()
{
    cd channel_config
    echo -e "\e[34m Enter Orderer Address\e[0m"
    read ORDERER_ADD
    ./createchannel.sh $ORDERER_ADD
}

joinChannel()
{
    cd channel_config
    ./joinchannel.sh
}

updateChannel()
{
    cd channel_config
    echo -e "\e[34m Enter Orderer Address\e[0m"
    read ORDERER_ADD
    ./updateAnchorpeer.sh $ORDERER_ADD
}


installChaincode()
{
    cd channel_config
    ./install_chaincode.sh
}

instantiateChaincode()
{
    cd channel_config
    ./instantiate_chaincode.sh
}

newOrg()
{
    echo -e "\e[34mEnter the of Organization you want to deploy\e[0m"
    echo -e "\e[34mNote: NameSpace will be created with Org Name and will be used\n to deploy your ICA and organzation peers\e[0m"
    read NS
    echo -e "\e[34mEnter CA Name\e[0m"
    read NAME
    # echo -e "\e[34mEnter the Name of organization you want to deploy\e[0m"
    # read 
    ORGNAME=$NS
    cd ca
    ./enroll_intermediateCA.sh $NS $NAME
    cd ..
    cd msp_scripts
    ./generateMSPnewOrg.sh $NS $ORGNAME $NAME
    cd ..
    cd channel_updates
    ./addOrgToConsortium.sh $ORGNAME
    ./addOrgToChannel.sh $ORGNAME
    cd ..
    cd channel_updates
    ./addOrg.sh $NS $ORGNAME $NAME
    ./addOrgAnchor.sh $ORGNAME
    echo -e "\e[34m Organization has been added successfully and its anchor peer has been updated\e[0m"
    echo -e "\e[34m Note: $ORGNAME peer1 has joined educhain-channel \n peer1 has been updated as anchor peer\e[0m"
    cat peer_address
    rm peer_address
}

batchSize()
{
    cd channel_updates
    ./batchSize.sh
}

batchTimeout()
{
    cd channel_updates
    ./batchTimeout.sh
}

networkDown()
{
    # if [ -d "./config/*MSP" ]; then
    rm -r ./config/*MSP 
    rm  ./config/*.tx
    rm  ./config/genesis.block
    rm -r ./NewOrgConfig/*MSP
    rm -r ./NewOrgConfig/*.json
    # fi
    helm ls --short > helm_rel
    HELM=$(cat helm_rel | grep -Ev "cert-manager|nginx-ingress")
        for i in $HELM
            do
                helm del --purge $i
            done

        sleep 10
    NAMESPACE=$(kubectl get ns -o jsonpath="{.items[*].metadata.name}")
    TEAR=$(echo $NAMESPACE | sed 's/\(kube-public\|kube-system\|default\|ingress-controller\|cert-manager\)//g')
    kubectl delete ns $TEAR
    rm helm_rel
}

check()
{
    cd extra
    ./health.sh educhain1-orderer orderer 2> /dev/null
    if [ $? == 0 ]; then
    echo -e "\xE2\x9C\x94 Orderer1 is Deployed. "
    else
    echo -e "\xE2\x9D\x8C Orderer1 Failed"
    fi
    ./health.sh educhain2-orderer orderer 2> /dev/null
    if [ $? == 0 ]; then
    echo -e "\xE2\x9C\x94 Orderer2 is Deployed. "
    else
    echo -e "\xE2\x9D\x8C Orderer2 Failed"
    fi
    ./health.sh educhain3-orderer orderer 2> /dev/null
    if [ $? == 0 ]; then
    echo -e "\xE2\x9C\x94 Orderer3 is Deployed. "
    else
    echo -e "\xE2\x9D\x8C Orderer3 Failed"
    fi
    ./health.sh mainorg-peer1-edu-peer  mainorg-peer 2> /dev/null
    if [ $? == 0 ]; then
    echo -e "\xE2\x9C\x94 Mainorg-Peer1 is Deployed. "
    else
    echo -e "\xE2\x9D\x8C Mainorg-Peer1 Failed"
    fi
    ./health.sh mainorg-peer2-edu-peer mainorg-peer 2> /dev/null
    if [ $? == 0 ]; then
    echo -e "\xE2\x9C\x94 Mainorg-Peer2 is Deployed. "
    else
    echo -e "\xE2\x9D\x8C Mainorg-Peer2 Failed"
    fi
    ./health.sh org1-peer1-edu-peer org1 2> /dev/null
    if [ $? == 0 ]; then
    echo -e "\xE2\x9C\x94 Org1-Peer1 is Deployed. "
    else
    echo -e "\xE2\x9D\x8C Org1-Peer1 Failed"
    fi
    ./health.sh org1-peer2-edu-peer org1 2> /dev/null
    if [ $? == 0 ]; then
    echo -e "\xE2\x9C\x94 Org1-Peer2 is Deployed. "
    else
    echo -e "\xE2\x9D\x8C Org1-Peer2 Failed"
    fi
    ./health.sh org2-peer1-edu-peer org2 2> /dev/null
    if [ $? == 0 ]; then
    echo -e "\xE2\x9C\x94 Org2-Peer1 is Deployed. "
    else
    echo -e "\xE2\x9D\x8C Org2-Peer1 Failed"
    fi
    ./health.sh org2-peer2-edu-peer org2 2> /dev/null
    if [ $? == 0 ]; then
    echo -e "\xE2\x9C\x94 Org2-Peer2 is Deployed. "
    else
    echo -e "\xE2\x9D\x8C Org2-Peer2 Failed"
    fi
}

MODE=$1

if [ "$MODE" == "ca" ]; then
    deployCA
elif [ "$MODE" == "msp" ]; then
    generateMSP
elif [ "$MODE" == "orderer" ]; then
    deployOrderer
elif [ "$MODE" == "config" ]; then
    networkConfig
elif [ "$MODE" == "organization" ]; then
    deployOrg
elif [ "$MODE" == "bootstrap" ]; then
    bootstrapNetwork
elif [ "$MODE" == "configk8s" ]; then
    configK8s
elif [ "$MODE" == "create-channel" ]; then
    createChannel
elif [ "$MODE" == "join-channel" ]; then
    joinChannel
elif [ "$MODE" == "update" ]; then
    updateChannel
elif [ "$MODE" == "addOrg" ]; then
    newOrg
elif [ "$MODE" == "installcc" ]; then
    installChaincode
elif [ "$MODE" == "instantiatecc" ]; then
    instantiateChaincode
elif [ "$MODE" == "add-orderer" ]; then
    addOrderer
elif [ "$MODE" == "batch-size" ]; then
    batchSize
elif [ "$MODE" == "batch-timeout" ]; then
    batchTimeout
elif [ "$MODE" == "down" ]; then
    networkDown
else
    printHelp
fi