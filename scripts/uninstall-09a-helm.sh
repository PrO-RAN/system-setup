#!/bin/bash

helm repo remove stable local

# helm plugin list | grep -v NAME | cut -d' ' -f1 | xargs helm plugin  uninstall

eval $(helm env |grep HELM_CACHE_HOME)
eval $(helm env |grep HELM_CONFIG_HOME)
eval $(helm env |grep HELM_DATA_HOME)

rm -rf HELM_CACHE_HOME
rm -rf HELM_CONFIG_HOME
rm -rf HELM_DATA_HOME

sudo rm $(which helm)
