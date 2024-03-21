#!/bin/bash

# 3.11.2
HELMVERSION=3.14.0

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
sudo ./get_helm.sh -v ${HELMVERSION}
rm get_helm.sh


helm repo add stable https://charts.helm.sh/stable

helm repo add local http://127.0.0.1:8879/charts

helm repo update
