#!/bin/bash

# USER_HOME=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
SCRIPT_DIR=$(cd `dirname -- $0` && pwd)
DOWN_DIR=$SCRIPT_DIR/../extra-downloads

mkdir -p $DOWN_DIR

HOST_IP=`hostname -I | awk '{print $1}'`


if [ ! -d "$DOWN_DIR/oam" ]; then
  cd $DOWN_DIR
  git clone https://github.com/o-ran-sc/oam/ -b g-release
  cd -
fi


# cd $DOWN_DIR/oam/solution/
# sed -i "s|directory_path = .*|directory_path = os.path.dirname(os.path.abspath(__file__))|g" ./adopt_to_environment.py
# python3 adopt_to_environment.py -i $HOST_IP
# cd -


# cd $DOWN_DIR/oam/solution/smo/common
# # sed -i "s|O_RAN_SC_TOPOLOGY_IMAGE=.*|O_RAN_SC_TOPOLOGY_IMAGE=nexus3.o-ran-sc.org:10002/o-ran-sc/smo-nts-ng-topology-server:1.5.0|g" ./.env
# docker compose up -d
# cd -
cd $DOWN_DIR/oam/solution/integration/smo/common
sed -i "s|O_RAN_SC_TOPOLOGY_IMAGE=.*|O_RAN_SC_TOPOLOGY_IMAGE=nexus3.o-ran-sc.org:10002/o-ran-sc/smo-nts-ng-topology-server:1.5.0|g" ./.env
docker compose up -d
cd -

# cd $DOWN_DIR/oam/solution/smo/oam
# docker compose up -d
# cd -
cd $DOWN_DIR/oam/solution/integration/smo/oam
docker compose up -d
cd -



# Information Coordination Service
if [ ! -d "$DOWN_DIR/nonrtric-rapp-ransliceassurance" ]; then
  cd $DOWN_DIR
  git clone https://github.com/o-ran-sc/nonrtric-rapp-ransliceassurance -b g-release
  cd -
fi

cd $DOWN_DIR/nonrtric-rapp-ransliceassurance/docker-compose/icsversion/
sed -i "s|NONRTRIC_GATEWAY_IMAGE_BASE=.*|NONRTRIC_GATEWAY_IMAGE_BASE=\"nexus3.o-ran-sc.org:10002/o-ran-sc/nonrtric-gateway\"|g" ./.env
sed -i "s|NONRTRIC_GATEWAY_IMAGE_TAG=.*|NONRTRIC_GATEWAY_IMAGE_TAG=\"1.2.0\"|g" ./.env
sed -i "s|ICS_IMAGE_BASE=.*|ICS_IMAGE_BASE=\"nexus3.o-ran-sc.org:10002/o-ran-sc/nonrtric-information-coordinator-service\"|g" ./.env
docker compose up nonrtric-control-panel nonrtric-gateway ics dmaap-adaptor-service dmaap-mediator-service -d
cd -
