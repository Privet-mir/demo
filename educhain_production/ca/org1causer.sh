CA_POD=$(kubectl get pods -n root-ca -l "app=rootca,release=rca" -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n root-ca $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://$CA_ADMIN:$CA_PASSWORD@$SERVICE_DNS:7054'

kubectl exec -n root-ca $CA_POD -- bash -c 'fabric-ca-client register --id.name org1ca --id.secret Q2SkoklmmqloDefEvv --id.attrs 'hf.IntermediateCA=true''


kubectl exec -n root-ca $CA_POD -- bash -c 'fabric-ca-client enroll -d -u http://org1ca:Q2SkoklmmqloDefEvv@$SERVICE_DNS:7054 --enrollment.attrs "hf.IntermediateCA"'
