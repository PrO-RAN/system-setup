#!/bin/bash

# USER_HOME=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
SCRIPT_DIR=$(cd `dirname -- $0` && pwd)
DOWN_DIR=$SCRIPT_DIR/../extra-downloads

mkdir -p $DOWN_DIR


if [ ! -d "$DOWN_DIR/ric-plt-ric-dep" ]; then
  cd $DOWN_DIR
  git clone https://github.com/o-ran-sc/ric-plt-ric-dep/ -b h-release
  cd -
fi

cd $DOWN_DIR/ric-plt-ric-dep/bin
export COMMON_CHART_VERSION=$(cat ../ric-common/Common-Template/helm/ric-common/Chart.yaml | grep version | awk '{print $2}')
helm package -d /tmp ../ric-common/Common-Template/helm/ric-common

echo "Hoping chartmuseum charts are in $SCRIPT_DIR/../chartmuseum/charts-ric"
cp /tmp/ric-common-${COMMON_CHART_VERSION}.tgz $SCRIPT_DIR/../chartmuseum/charts-ric
rm /tmp/ric-common-${COMMON_CHART_VERSION}.tgz
cd -

echo "checking that ric-common templates were added"
helm repo update
helm search repo local/ric-common
