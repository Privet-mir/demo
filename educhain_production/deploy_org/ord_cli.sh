helm install -n ordcli ../../educhain-ordcli --namespace orderer -f ../helm_values/ordcli.yaml


ORD_POD=$(kubectl get pods --namespace orderer -l "app=orderer,release=ordcli" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready -n orderer  pod/$ORD_POD

kubectl logs -n orderer $ORD_POD | grep 'Starting orderer'
