#!/bin/bash

sudo apt install -y nfs-common

if ! kubectl get ns ${INFRANAMESPACE:-ricinfra}> /dev/null 2>&1; then
  kubectl create ns ${INFRANAMESPACE:-ricinfra}
fi
helm install nfs-release-1 stable/nfs-server-provisioner --namespace ricinfra
kubectl patch storageclass nfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
