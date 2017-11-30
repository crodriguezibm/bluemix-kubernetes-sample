#!/bin/bash

echo "Create Guestbook"
IP_ADDR=$(bx cs workers $CLUSTER_NAME | grep normal | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
exp=$(bx cs cluster-config $CLUSTER_NAME | grep export)
if [ $? -ne 0 ]; then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

echo -e "Downloading javaee7-simple-sample yml"
#curl --silent "https://raw.githubusercontent.com/kubernetes/kubernetes/master/examples/guestbook/all-in-one/guestbook-all-in-one.yaml" > guestbook.yml
curl --silent "https://raw.githubusercontent.com/kubernetes/kubernetes/master/examples/javaee/mysql-pod.yaml" > mysql-pod.yaml
curl --silent "https://raw.githubusercontent.com/kubernetes/kubernetes/master/examples/javaee/mysql-service.yaml" > mysql-service.yaml
curl --silent "https://raw.githubusercontent.com/kubernetes/kubernetes/master/examples/javaee/wildfly-rc.yaml" > wildfly-rc.yaml
#Find the line that has the comment about the load balancer and add the nodeport def after this
#let NU=$(awk '/^  # type: LoadBalancer/{ print NR; exit }' guestbook.yml)+3
#NU=$NU\i
#sed -i "$NU\ \ type: NodePort" guestbook.yml #For OSX: brew install gnu-sed; replace sed references with gsed

echo -e "Deleting previous version of javaee7-simple-sample if it exists"
kubectl delete --ignore-not-found=true   -f wildfly-rc.yaml
kubectl delete --ignore-not-found=true   -f mysql-service.yaml
kubectl delete --ignore-not-found=true   -f mysql-pod.yaml

echo -e "Creating pods"
kubectl create -f mysql-pod.yaml
kubectl create -f mysql-service.yaml
kubectl create -f wildfly-rc.yaml

PORT=$(kubectl get replicationcontroller | grep wildfly-rc | sed 's/.*:\([0-9]*\).*/\1/g')

echo ""
echo "View the wildfly-rc at http://$IP_ADDR:$PORT"
