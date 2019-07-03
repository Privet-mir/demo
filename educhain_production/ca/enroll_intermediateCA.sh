#!/bin/bash

# echo "Enter DNS for intermediate CA"
# read DNS

# echo "Enter CA Name"
# read NAME

NAME=$2

# echo "Enter the NameSpace to create"
# echo "Note this NameSpace will be used to deploy your ICA and organzation peers"
# read NS
NS=$1
kubectl create ns $NS

echo "Enter Intermediate CA User"
read ICA_USER

cat  <<EOF > ../helm_values/$NAME.yaml
image:
  tag: 1.4.1


ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    certmanager.k8s.io/cluster-issuer: "letsencrypt-production"
  path: /
  hosts:
    # TODO: Change this to your Domain Name
    - $NAME.zx.kmindz.xyz
  tls:
    - secretName: $NAME--tls
      hosts:
        # TODO: Change this to your Domain Name
        - $NAME.zx.kmindz.xyz

persistence:
  accessMode: ReadWriteOnce
  size: 1Gi

caName: $NAME

secrets:
  rootca: rootca--tls

postgresql:
  enabled: false

config:
  hlfToolsVersion: 1.4.1
  csr:
    names:
      c: IN
      st: MH
      l:
      o: "Kmindz"
      ou: Blockchain
  intermediate:
    parent:
      chart: rootca
      url: rootca.zx.kmindz.xyz
      port: 7054
  affiliations:
    kmindz: []

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 95
        podAffinityTerm:
          topologyKey: "kubernetes.io/hostname"
          labelSelector:
            matchLabels:
              app: ca
EOF

CA_POD=$(kubectl get pods -n root-ca -l "app=rootca,release=rca" -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n root-ca $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'
kubectl exec -n root-ca $CA_POD -- bash -c 'fabric-ca-client register --id.name '$ICA_USER' --id.secret Q2SkoklmmqloDefEvv --id.attrs 'hf.IntermediateCA=true''
kubectl exec -n root-ca $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://'$ICA_USER':Q2SkoklmmqloDefEvv@$SERVICE_DNS:7054 --enrollment.attrs "hf.IntermediateCA"'

secret_user=$(echo -n "$ICA_USER" | base64)

cat <<EOF > ../helm_values/ca-user-secret/$NAME--ca
apiVersion: v1
kind: Secret
metadata:
  name: rootca--ca
type: Opaque
data:
  CA_ADMIN: $secret_user
  CA_PASSWORD: UTJTa29rbG1tcWxvRGVmRXZ2
EOF

kubectl create -f ../helm_values/ca-user-secret/$NAME--ca -n $NS


kubectl get secret rootca--tls --namespace=root-ca --export -o yaml |\
   kubectl apply --namespace=$NS -f -  --validate=false

echo -e "\e[34m Install CA\e[0m"
helm install ../../ca -n $NAME --namespace $NS -f ../helm_values/$NAME.yaml

# sleep 60

CA_POD=$(kubectl get pods -n $NS -l "app=ca,release=$NAME" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready --timeout=420s  -n $NS pod/$CA_POD

kubectl logs -n $NS $CA_POD | grep "Listening on"

CA_INGRESS=$(kubectl get ingress -n $NS -l "app=ca,release=$NAME" -o jsonpath="{.items[0].spec.rules[0].host}")
sleep 5
echo -e "\e[34m Curl CAINFO\e[0m"
curl https://$CA_INGRESS/cainfo