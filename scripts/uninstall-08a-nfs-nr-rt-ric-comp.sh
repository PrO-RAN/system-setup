#!/bin/bash

SCRIPT_DIR=$(cd `dirname -- $0` && pwd)
DOWN_DIR=$SCRIPT_DIR/../extra-downloads

mkdir -p $DOWN_DIR

if [ ! -d "$DOWN_DIR/ric-plt-ric-dep" ]; then
  cd $DOWN_DIR
  git clone https://github.com/o-ran-sc/ric-plt-ric-dep/ -b h-release
  cd -
fi

cd $DOWN_DIR/ric-plt-ric-dep/bin

helm uninstall nfs-release-1 -n ricinfra
./uninstall

cd -
