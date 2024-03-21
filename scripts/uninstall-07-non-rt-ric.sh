#!/bin/bash

# USER_HOME=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
SCRIPT_DIR=$(cd `dirname -- $0` && pwd)
DOWN_DIR=$SCRIPT_DIR/../extra-downloads

mkdir -p $DOWN_DIR


# Information Coordination Service
if [ ! -d "$DOWN_DIR/nonrtric-rapp-ransliceassurance" ]; then
  cd $DOWN_DIR
  git clone https://github.com/o-ran-sc/nonrtric-rapp-ransliceassurance -b g-release
  cd -
fi

cd $DOWN_DIR/nonrtric-rapp-ransliceassurance/docker-compose/icsversion/
echo "$(pwd)"
docker compose down
cd -



if [ ! -d "$DOWN_DIR/oam" ]; then
  cd $DOWN_DIR
  git clone https://github.com/o-ran-sc/oam/ -b g-release
  cd -
fi


# cd $DOWN_DIR/oam/solution/smo/oam
cd $DOWN_DIR/oam/solution/integration/smo/oam
echo "$(pwd)"
docker compose down
cd -


# cd $DOWN_DIR/oam/solution/smo/common
cd $DOWN_DIR/oam/solution/integration/smo/common
# sed -i "s|O_RAN_SC_TOPOLOGY_IMAGE=.*|O_RAN_SC_TOPOLOGY_IMAGE=nexus3.o-ran-sc.org:10002/o-ran-sc/smo-nts-ng-topology-server:1.5.0|g" ./.env
echo "$(pwd)"
docker compose down
cd -

# cd $DOWN_DIR/oam/solution/
# python3 adopt_to_environment.py -i aaa.bbb.ccc.ddd -r
# cd -
