#!/bin/bash

# echo "Enter the NameSpace where CA is deployed for this organization"
# read NS
NS=$1
# echo "Enter the Name of organization you want to deploy"
# read ORGNAME
ORGNAME=$2
# echo -e "\e[34mEnter the Name of organization MSP\e[0m"
# read ORGNAMEMSP
# echo "Enter CA Name"
# read NAME
NAME=$3
echo -e "\e[34mEnter number of peers you want to deploy\e[0m"
read NUM

## Mainorg $ORGNAME
CA_POD=$(kubectl get pods -n $NS -l "app=ca,release=$NAME" -o jsonpath="{.items[0].metadata.name}")
CA_INGRESS=$(kubectl get ingress -n $NS -l "app=ca,release=$NAME" -o jsonpath="{.items[0].spec.rules[0].host}")




for i in $(seq 1 $NUM)
do
 echo -e "\e[34m Fabric Peer$i \e[0m"
  # echo -e "\e[34m Enter DNS for Peer$i \e[0m"
  # read DNS
 echo -e "\e[34m Install CouchDB chart \e[0m"
 helm install -n "$ORGNAME"-couchdb${i} hyperledger-charts/couchdb --namespace $NS -f ../helm_values/cdb.yaml
 sleep 70
 CDB_POD=$(kubectl get pods -n $NS -l "app=couchdb,release="$ORGNAME"-couchdb${i}" -o jsonpath="{.items[*].metadata.name}")
 kubectl logs -n $NS $CDB_POD | grep 'Apache CouchDB has started on'

 echo -e "\e[34m Register peer with CA \e[0m"
 kubectl exec -n $NS $CA_POD -- fabric-ca-client register --id.name "$ORGNAME"-peer${i} --id.secret "$ORGNAME"-peer${i}_pw --id.type peer
 FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -d -u https://"$ORGNAME"-peer${i}:"$ORGNAME"-peer${i}_pw@$CA_INGRESS -M "$ORGNAME"-peer${i}_MSP
 echo -e "\e[34m Save the Peer certificate in a secret \e[0m"
 NODE_CERT=$(ls ../config/"$ORGNAME"-peer${i}_MSP/signcerts/*.pem)
 kubectl create secret generic -n $NS hlf--peer${i}-idcert --from-file=cert.pem=${NODE_CERT}
 echo -e "\e[34m Save the Peer private key in another secret \e[0m"
 NODE_KEY=$(ls ../config/"$ORGNAME"-peer${i}_MSP/keystore/*_sk)
 kubectl create secret generic -n $NS hlf--peer${i}-idkey --from-file=key.pem=${NODE_KEY}
 INT_CERT=$(ls ../config/"$ORGNAME"-peer${i}_MSP/intermediatecerts/*.pem)
 kubectl create secret generic -n $NS hlf--peer${i}-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}

cat <<EOF > ../helm_values/$ORGNAME-peer${i}.yaml
image:
  tag: 1.4.1

persistence:
  accessMode: ReadWriteOnce
  size: 1Gi

ingress:
  enabled: true
  annotations: 
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
    certmanager.k8s.io/cluster-issuer: "letsencrypt-production"
  path: /
  hosts:
   - ${ORGNAME}peer${i}.zx.kmindz.xyz
  tls: 
   - secretName: peer-tls
     hosts:
       - ${ORGNAME}peer${i}.zx.kmindz.xyz


peer:
  databaseType: CouchDB
  couchdbInstance: $ORGNAME-couchdb${i}
  mspID: ${ORGNAME}MSP


secrets:
  peer:
    cert: hlf--peer1-idcert
    key: hlf--peer1-idkey
    caCert: hlf--$ORGNAME-ca-cert
    intCaCert: hlf--peer1-caintcert
#  channel: hlf--channel
  adminCert: hlf--$ORGNAME-admincert
  adminKey: hlf--$ORGNAME-adminkey

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 95
        podAffinityTerm:
          topologyKey: "kubernetes.io/hostname"
          labelSelector:
            matchLabels:
              app: educhain
EOF


echo -e "\e[34m Install Fabric Peer Chart \e[0m"
helm install -n "$ORGNAME"-peer${i} hyperledger-charts/edu-peer --namespace $NS -f ../helm_values/"$ORGNAME"-peer${i}.yaml
# sleep 60
PEER_POD=$(kubectl get pods --namespace $NS -l "app=edu-peer,release="$ORGNAME"-peer${i}" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=250s -n $NS  pod/$PEER_POD
kubectl logs -n $NS $PEER_POD | grep 'Starting peer'

PEER_ADD=$(echo -e "\e[34m Your peer address \n $ORGNAME-peer${i}-edu-peer.$ORGNAME.svc.cluster.local \e[0m")
echo "$PEER_ADD" >> peer_address

done

cat <<EOF >> ../helm_values/$ORGNAME-cli.yaml
image:
  tag: 1.4.1

persistence:
  accessMode: ReadWriteOnce
  size: 1Gi


peer:
  mspID: ${ORGNAME}MSP


secrets:
  peer:
    cert: hlf--peer1-idcert
    key: hlf--peer1-idkey
    caCert: hlf--$ORGNAME-ca-cert
    intCaCert: hlf--peer1-caintcert
#  channel: hlf--channel
  adminCert: hlf--$ORGNAME-admincert
  adminKey: hlf--$ORGNAME-adminkey

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 95
        podAffinityTerm:
          topologyKey: "kubernetes.io/hostname"
          labelSelector:
            matchLabels:
              app: cli
EOF

echo -e "\e[34m Fabric Peer cli \e[0m"

helm install -n "$ORGNAME"cli ../../cli --namespace $NS -f ../helm_values/$ORGNAME-cli.yaml
# sleep 60
PEER_POD=$(kubectl get pods --namespace $NS -l "app=cli,release="$ORGNAME"cli" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=320s -n $NS  pod/$PEER_POD
kubectl cp ../configk8s/root.pem $PEER_POD:/var/hyperledger/fabric_cfg -n $NS
kubectl logs -n $NS $PEER_POD | grep 'Starting peer'