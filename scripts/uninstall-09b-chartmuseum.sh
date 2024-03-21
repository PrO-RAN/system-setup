#!/bin/bash


# USER_HOME=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
SCRIPT_DIR=$(cd `dirname -- $0` && pwd)

rm -rf $SCRIPT_DIR/../chartmuseum/charts-ric
rm -rf $SCRIPT_DIR/../chartmuseum/charts-xapp
rmdir $SCRIPT_DIR/../chartmuseum

docker rm -f chartmuseum-ric chartmuseum-xapp
