# Educhain

## Educhain Hyperledger Fabric Network on K8's

** Prerequsite **

 * Ubuntu 16.04 (as proxy / jump / admin server from where we will administer k8s cluster)
 * Hyplerledger Fabric 1.4.1 Binaries (installed on ubuntu)
 * Helm & Tiller
 * GKE (Google Kubernetes Engine)
 * Nginx Ingress
 * Cert Manager
 * DNS

** Configure GKE Cluster **

We need to install helm, tiller, cert manager and nginx ingress on cluster for this run configk8s.sh script.

First clone repository 

```
$: git clone https://kMindz-blockchain@bitbucket.org/kMindz-blockchain/kmindz-k8s.git
```
Open terminal and goto directory educhain_production follow the commands below.

```
$: cd kmindz-k8s/educhain_production
$: ./edu_nk.sh configk8s
```
The following script will print your Nginx Ingress External IP

Copy External IP and goto your DNS provider dashboard and open DNS manage panel there add record of type A and in host field add *.aa and in points to filed paste External IP of Ingress.

Then Save

## Bootstrap Network 

Initially we are going to Bootstrap Network with 3 orderer using kafka consensus, 3 Organizations each having 2 peers and 1 couchdb associated with each of them as well as one CLI per 

** Bootstrap **

```
$: ./edu_nk.sh bootstrap
```
Complete Network startup will take atleast 20 mins.

### Create Channel

```
$: ./edu_nk.sh create-channel
  > Enter orderer ADDRESS
    orderer1.md.fabtoken.club (Enter your orderer ingress)
```

### Join Channel

```
$: ./edu_nk.sh join-channel
  > Enter orderer address
    orderer1.md.fabtoken.club (Enter your orderer ingress)
  > Enter channel name
    educhain-channel
  > Enter Namespace of Org
    mainorg-peer (your org name)
  > Enter Peers Addresses Seprated By COMMA
    mainorg-peer1-edu-peer.mainorg-peer.svc.cluster.local,mainorg-peer2-edu-peer.mainorg-peer.svc.cluster.local (change this as per your organization)
```

### Install and Instantiate Chaincode

```
$: ./edu_nk.sh installcc
  > Enter Chaincode PATH
  /home/ubuntu/chaincode (Provide path to chaincode files)
  > Enter Chaincode Name
  samplecc
  > Enter Chaincode Version
  1.0
  > Enter Namespace of Org
  mainorg-peer
  > Enter Peers Addresses Seprated By COMMA
  mainorg-peer1-edu-peer.mainorg-peer.svc.cluster.local,mainorg-peer2-edu-peer.mainorg-peer.svc.cluster.local
```

```
$: ./edu_nk.sh instantiatecc
  > Enter Orderer Address
  educhain1-orderer.orderer.svc.cluster.local
  > Enter channel name
  educhain-channel
  > Enter Chaincode Name
  samplecc
  > Enter Chaincode Version
  1.0
  > Enter Namespace of Org
  mainorg-peer
  > Enter Peers Address
  mainorg-peer1-edu-peer.mainorg-peer.svc.cluster.local
```

### Add a New Org to Educhain Channel

```
$: ./edu_nk.sh addOrg
    > Enter the of Organization you want to deploy
    >Note: NameSpace will be created with Org Name and will be used\n to deploy your ICA and organzation peers
      org3      
    > Enter CA Name
      org3ca
    > Enter Intermediate CA User
      org3admin
```

### Change Block Size

```
$: ./edu_nk.sh batch-size
  > Enter Batch Size
    10
```

### Change Batch Time Out

```
$: ./edu_nk.sh batch-timeout
  > Enter Batch time out
    20s
```

### Bring Down Network

```
$: ./edu_nk.sh down
```

### Print Help

```
$: ./edu_nk.sh
```

### Running Sample Application

Register user with CA using CA External IP Address
```
kubectl get service -o wide -n <your-org-namespace>
```

Make sure correct path is pass for root.pem file 
```
let serverCert = fs.readFileSync(path.join(__dirname, './root.pem'));
var peer = fabric_client.newPeer('grpcs://<PEER_DNS>', {'pem': Buffer.from(serverCert).toString()});
var order = fabric_client.newOrderer('grpcs://<ORDERER_DNS>', {'pem': Buffer.from(serverCert).toString()});
```
make these changes wherever necessary and replace all ip's with your DNS

### Pem File

Let's encrypt root.pem file

https://letsencrypt.org/certs/trustid-x3-root.pem.txt

### Update service CA for to expose as load Balancer

```
$: kubectl get service -n mainorg-peer
  (copy name of service for CA)
$: kubectl edit service <CA Service name> -n mainorg-peer

Now a file will open in this file replace ClusterIP with LoadBalancer
then press ESC :wq
```
Get CA admin Password please modify these commands as per organization
```
$: CA_POD=$(kubectl get pods -n mainorg-peer -l "app=ca,release=mpica" -o jsonpath="{.items[0].metadata.name}")
$: kubectl exec $CA_POD -n mainorg-peer -- bash -c 'echo $CA_PASSWORD'
```

Replace the CA_IP with you external IP of CA
```
fabric_ca_client = new Fabric_CA_Client('http://CA_IP', tlsOptions , 'mainorg-peer', crypto_suite)
```

Replace mspid with your org mspid which can be found in yaml file in helm_values 
```
     return fabric_client.createUser(
              {username: 'admin',
                  mspid: 'MainOrg-devMSP',
                  cryptoContent: { privateKeyPEM: enrollment.key.toBytes(), signedCertPEM: enrollment.certificate }
              });
```