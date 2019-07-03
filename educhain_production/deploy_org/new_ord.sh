#!/bin/bash



echo "Enter Number of Orderer"
read NUM
echo "Enter Orderer Ingress"
read INGRESS
for i in $(seq $NUM $NUM)
do 
echo -e "\e[34m Deploy Orderer$i \e[0m"

cat <<EOF > ./helm_values/ord${i}.yaml

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
   - $INGRESS
  tls: 
   - secretName: orderer${i}-tls
     hosts:
       - $INGRESS


ord:
  type: kafka
  mspID: OrdererMSP

secrets:
  ord:
    cert: hlf--ord${i}-idcert
    key: hlf--ord${i}-idkey
    caCert: hlf--ord-ca-cert
    intCaCert: hlf--ord${i}-caintcert
  genesis: hlf--genesis
  adminCert: hlf--ord-admincert  

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 95
        podAffinityTerm:
          topologyKey: "kubernetes.io/hostname"
          labelSelector:
            matchLabels:
              app: orderer

EOF

echo -e "\e[34m Deploy Orderer$i helm chart \e[0m"
helm install -n educhain${i} hyperledger-charts/orderer --namespace orderer -f ./helm_values/ord${i}.yaml
sleep 30
ORD_POD=$(kubectl get pods --namespace orderer -l "app=orderer,release=educhain${i}" -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n orderer $ORD_POD | grep 'Starting orderer'
done