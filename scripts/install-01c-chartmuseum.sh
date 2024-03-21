#!/bin/bash

# 0.12.0
CHARTMUSEUM=0.15.0

# USER_HOME=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
SCRIPT_DIR=$(cd `dirname -- $0` && pwd)


# For near-rt-ric
export RIC_CMDIR=$SCRIPT_DIR/../chartmuseum/charts-ric
mkdir -p $RIC_CMDIR
docker run --rm -d -u 0 --name chartmuseum-ric -p 8879:8080 -e DEBUG=1 \
    -e STORAGE=local -e STORAGE_LOCAL_ROOTDIR=/charts -e CONTEXT_PATH=/charts \
    -v $RIC_CMDIR:/charts ghcr.io/helm/chartmuseum:v$CHARTMUSEUM


# For xApps
export XAPP_CMDIR=$SCRIPT_DIR/../chartmuseum/charts-xapp
mkdir -p $XAPP_CMDIR
docker run --rm -d -u 0 --name chartmuseum-xapp -p 8090:8080 -e DEBUG=1 \
    -e STORAGE=local -e STORAGE_LOCAL_ROOTDIR=/charts \
    -v $XAPP_CMDIR:/charts ghcr.io/helm/chartmuseum:v$CHARTMUSEUM
