# echo "Enter the NameSpace where CA is deployed for this organization"
# read NS
NS=$1
# echo "Enter the Name of organization you want to deploy"
# read ORGNAME
ORGNAME=$2
# echo "Enter CA Name"
# read NAME
NAME=$3

## Mainorg $ORGNAME
CA_POD=$(kubectl get pods -n $NS -l "app=ca,release=$NAME" -o jsonpath="{.items[0].metadata.name}")
CA_INGRESS=$(kubectl get ingress -n $NS -l "app=ca,release=$NAME" -o jsonpath="{.items[0].spec.rules[0].host}")

kubectl exec -n $NS $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'


echo -e "\e[34m Register $ORGNAME identiy on CA\e[0m"
kubectl exec -n $NS $CA_POD -- fabric-ca-client register --id.name "$ORGNAME"-admin --id.secret "$ORGNAME"Adm1nPW --id.attrs 'admin=true:ecert'

echo -e "\e[34m Enroll $ORGNAME organization admin identiy on CA\e[0m"
FABRIC_CA_CLIENT_HOME=../config fabric-ca-client enroll -u https://"$ORGNAME"-admin:"$ORGNAME"Adm1nPW@$CA_INGRESS -M ./"$ORGNAME"MSP
mkdir -p ../config/"$ORGNAME"MSP/admincerts
cp ../config/"$ORGNAME"MSP/signcerts/* ../config/"$ORGNAME"MSP/admincerts

echo -e "\e[34m Create a secret to hold the admincert:"$ORGNAME" Organisation\e[0m"
ORG_CERT=$(ls ../config/"$ORGNAME"MSP/admincerts/cert.pem)
kubectl create secret generic -n $NS hlf--"$ORGNAME"-admincert --from-file=cert.pem=$ORG_CERT
echo -e "\e[34m Create a secret to hold the admin key:"$ORGNAME" Organisation\e[0m"
ORG_KEY=$(ls ../config/"$ORGNAME"MSP/keystore/*_sk)
kubectl create secret generic -n $NS hlf--"$ORGNAME"-adminkey --from-file=key.pem=$ORG_KEY
echo -e "\e[34m Create a secret to hold the CA certificate:"$ORGNAME" Organisation\e[0m"
CA_CERT=$(ls ../config/"$ORGNAME"MSP/cacerts/*.pem)
kubectl create secret generic -n $NS hlf--"$ORGNAME"-ca-cert --from-file=cacert.pem=$CA_CERT
INT_CERT=$(ls ../config/"$ORGNAME"MSP/intermediatecerts/*.pem)
kubectl create secret generic -n $NS hlf--"$ORGNAME"-caintcert --from-file=intermedicatecacert.pem=${INT_CERT}


mv ../config/"$ORGNAME"MSP/ ../NewOrgConfig