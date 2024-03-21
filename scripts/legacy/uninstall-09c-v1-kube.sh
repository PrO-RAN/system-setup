#!/bin/bash

USER_HOME=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)

kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/v0.24.1/Documentation/kube-flannel.yml

sudo rm -rf /opt/config
APTOPTS="--allow-downgrades --allow-change-held-packages --allow-unauthenticated --ignore-hold "
for PKG in kubeadm; do
  INSTALLED_VERSION=$(dpkg --list |grep ${PKG} |tr -s " " |cut -f3 -d ' ')
  if [ ! -z ${INSTALLED_VERSION} ]; then
    if [ "${PKG}" == "kubeadm" ]; then
      sudo kubeadm reset -f
      rm -rf $USER_HOME/.kube
      sudo apt-get -y $APTOPTS remove kubeadm kubelet kubectl kubernetes-cni
      sudo apt-get -y purge kube*
      sudo apt-get -y autoremove
    else
      sudo apt-get -y $APTOPTS remove "${PKG}"
    fi
  fi
done
sudo apt-get -y autoremove


cleanupdirs="$USER_HOME/.kube /.kube /var/lib/kubelet/ /root/.kube /home/.kube /var/lib/etcd /etc/kubernetes /etc/cni /opt/cni /var/lib/cni /var/run/calico /opt/rke"
for dir in $cleanupdirs; do
  echo "Removing $dir"
  sudo rm -rf $dir
done

rm $USER_HOME/config.yaml
sudo rm /root/config.yaml
sudo rm /etc/containerd/config.toml /etc/sysctl.d/99-kubernetes-cri.conf /etc/systemd/system/cri-docker.socket /etc/systemd/system/cri-docker.service
sudo rm /usr/local/bin/cri-dockerd /etc/docker/daemon.json /usr/share/keyrings/google-keyring.gpg
sudo rm -rf /opt/data/dashboard-data

sudo systemctl daemon-reload
sudo sysctl --system

# swap will be off
echo "WARN: swap will stay off"
echo "WARN: will not get uninstall apt-transport-https curl jq netcat make ipset moreutils virt-what"

sed -i '/export KUBECONFIG=/d' $USER_HOME/.bashrc
var1=$(hostname -I)
var2=$(hostname)
sudo sed -i "/${var1}[ ]*${var2}/d" /etc/hosts
unset KUBECONFIG


# remove dependency packages related to docker
sudo apt autoremove -y
sudo apt autoclean -y

# Remove the repository to Apt sources:
sudo rm /etc/apt/sources.list.d/kubernetes.list /etc/apt/sources.list.d/kubernetes.list.save
# /etc/apt/apt.conf.d/80-retries
