#!/bin/bash

# 1.1.1
CNIVERSION=1.1.1
# 1.25.13
KUBEVERSION=1.25.13



export DEBIAN_FRONTEND=noninteractive
USER_HOME=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)



#  add to etc/hosts
if grep -Fxq "$(hostname -I) $(hostname)" /etc/hosts  > /dev/null
then
  # code if found
  :
else
  # code if not found
  echo "$(hostname -I) $(hostname)" >> /etc/hosts
fi
sudo cat /etc/hosts
printenv


# Enable iptables Bridged Traffic on all the Nodes
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter





# disable swap
sudo swapoff -a

# keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y

SWAPFILES=$(sudo grep swap /etc/fstab | sed '/^[ \t]*#/ d' | sed 's/[\t ]/ /g' | tr -s " " | cut -f1 -d' ')
if [ ! -z $SWAPFILES ]; then
  for SWAPFILE in $SWAPFILES
  do
    if [ ! -z $SWAPFILE ]; then
      echo "disabling swap file $SWAPFILE"
      if [[ $SWAPFILE == UUID* ]]; then
        UUID=$(echo $SWAPFILE | cut -f2 -d'=')
        sudo swapoff -U $UUID
      else
        sudo swapoff $SWAPFILE
      fi
      sudo sed -i "\%$SWAPFILE%d" /etc/fstab
    fi
  done
fi


# (deprecated)
# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/google-keyring.gpg
# echo "deb [signed-by=/usr/share/keyrings/google-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


KUBEV=v$(echo $KUBEVERSION | cut -d '.' -f 1,2)
sudo mkdir -p /usr/share/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBEV}/deb/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBEV}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y

sudo mkdir -p /etc/apt/apt.conf.d
echo "APT::Acquire::Retries \"3\";" | sudo tee /etc/apt/apt.conf.d/80-retries

sudo apt update
sudo apt install -y apt-transport-https curl jq netcat make ipset moreutils \
    virt-what software-properties-common ca-certificates

sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker


CNI_VI=$(apt-cache madison kubernetes-cni | grep $CNIVERSION | head -1 | awk -F' \\| ' '{print $2}' | awk '{$1=$1;print}')
ADM_VI=$(apt-cache madison kubeadm | grep $KUBEVERSION | head -1 | awk -F' \\| ' '{print $2}' | awk '{$1=$1;print}')
LET_VI=$(apt-cache madison kubelet | grep $KUBEVERSION | head -1 | awk -F' \\| ' '{print $2}' | awk '{$1=$1;print}')
CTL_VI=$(apt-cache madison kubectl | grep $KUBEVERSION | head -1 | awk -F' \\| ' '{print $2}' | awk '{$1=$1;print}')

printf "\nTo be installed: $CNI_VI $ADM_VI $LET_VI $CTL_VI\n"

APTOPTS="--allow-downgrades --allow-change-held-packages --allow-unauthenticated --ignore-hold "
printf "\n\nsudo apt install -y $APTOPTS kubernetes-cni=$CNI_VI kubeadm=$ADM_VI kubelet=$LET_VI kubectl=$CTL_VI"
sudo apt install -y $APTOPTS kubernetes-cni=$CNI_VI kubeadm=$ADM_VI kubelet=$LET_VI kubectl=$CTL_VI
sudo apt-mark hold kubernetes-cni kubelet kubeadm kubectl

LOCAL_IP=$(echo $(hostname -I) | cut -d " " -f1)
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$LOCAL_IP
EOF



# CRI-docker setup (required if dont want to use containerd)
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.10/cri-dockerd-0.3.10.amd64.tgz
tar -xvf cri-dockerd-0.3.10.amd64.tgz
cd cri-dockerd/
sudo mkdir -p /usr/local/bin
sudo install -o root -g root -m 0755 ./cri-dockerd /usr/local/bin/cri-dockerd
cd ..
rm -rf cri-dockerd cri-dockerd-0.3.10.amd64.tgz*

sudo tee /etc/systemd/system/cri-docker.service << EOF
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network-online.target firewalld.service docker.service
Wants=network-online.target
Requires=cri-docker.socket
[Service]
Type=notify
ExecStart=/usr/local/bin/cri-dockerd --container-runtime-endpoint fd:// --network-plugin=
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/cri-docker.socket << EOF
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service
[Socket]
ListenStream=%t/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker
[Install]
WantedBy=sockets.target
EOF

#Daemon reload
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sudo kubeadm config images pull --kubernetes-version=${KUBEVERSION} --cri-socket unix:///var/run/cri-dockerd.sock

cat <<EOF >$USER_HOME/config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///var/run/cri-dockerd.sock"
  imagePullPolicy: IfNotPresent
---
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v${KUBEVERSION}
kind: ClusterConfiguration
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
EOF
# apiServer:
#   extraArgs:
#     feature-gates: SCTPSupport=true
sudo kubeadm init --config $USER_HOME/config.yaml

mkdir -p $USER_HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $USER_HOME/.kube/config
sudo chown -R $(id -u ${SUDO_USER:-$USER}):$(id -g ${SUDO_USER:-$USER}) $USER_HOME/.kube/
export KUBECONFIG=$USER_HOME/.kube/config

if grep -Fxq "export KUBECONFIG=~/.kube/config" $USER_HOME/.bashrc  > /dev/null
then
  # code if found
  :
else
  # code if not found
  echo "export KUBECONFIG=~/.kube/config" >> $USER_HOME/.bashrc
fi

sudo ufw disable

# kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.24.1/Documentation/kube-flannel.yml

wait_for_pods_running () {
  NS="$2"
  CMD="kubectl get pods --all-namespaces "
  if [ "$NS" != "all-namespaces" ]; then
    CMD="kubectl get pods -n $2 "
  fi
  KEYWORD="Running"
  if [ "$#" == "3" ]; then
    KEYWORD="${3}.*Running"
  fi

  CMD2="$CMD | grep \"$KEYWORD\" | wc -l"
  NUMPODS=$(eval "$CMD2")
  echo "waiting for $NUMPODS/$1 pods running in namespace [$NS] with keyword [$KEYWORD]"
  while [  $NUMPODS -lt $1 ]; do
    sleep 5
    NUMPODS=$(eval "$CMD2")
    echo "> waiting for $NUMPODS/$1 pods running in namespace [$NS] with keyword [$KEYWORD]"
  done
}
wait_for_pods_running 7 kube-system
wait_for_pods_running 1 kube-flannel

kubectl get pods --all-namespaces


# kubectl get po -n kube-system | grep kube-proxy | awk '{print $1}' | xargs kubectl logs "${@}" -n kube-system | grep "Using ipvs Proxier"


echo "Preparing a master node (lowser ID) for using local FS for PV"
PV_NODE_NAME=$(kubectl get nodes |grep $(hostname) | cut -f1 -d' ' | sort | head -1)
kubectl label --overwrite nodes $PV_NODE_NAME local-storage=enable
if [ "$PV_NODE_NAME" == "$(hostname)" ]; then
  sudo mkdir -p /opt/data/dashboard-data
fi
