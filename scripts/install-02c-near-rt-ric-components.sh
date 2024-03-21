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

cd $DOWN_DIR/ric-plt-ric-dep/

rm -rf helm
cp -r $SCRIPT_DIR/../helm $DOWN_DIR/ric-plt-ric-dep/

sed -E -i '/a1mediator/{:a;N;/rmr_timeout_config:/!ba s/tag: .*\n/tag: 3.2.2\n/}' ./RECIPE_EXAMPLE/example_recipe_oran_h_release.yaml

cd -

cd $DOWN_DIR/ric-plt-ric-dep/bin
# ./install -f ../RECIPE_EXAMPLE/example_recipe_oran_h_release.yaml -c "influxdb jaegeradapter"
./install -f ../RECIPE_EXAMPLE/example_recipe_oran_h_release.yaml
cd -
