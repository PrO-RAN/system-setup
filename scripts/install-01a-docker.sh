#!/bin/bash

# 20.04.1
UBUNTU_RELEASE=$(lsb_release -r | sed 's/^[a-zA-Z:\t ]\+//g')


# 25.0.3, 20.10.21
DOCKERV="25.0.3"

# ==============================================================================

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install docker and related items
VERSION_STRING=$(apt-cache madison docker-ce | awk '{ print $3 }' | grep $DOCKERV | head -n 1)
echo "VERSION_STRING=$VERSION_STRING"
sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-mark hold docker.io docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create the docker group
sudo groupadd docker
# Add your user to the docker group
sudo usermod -aG docker $USER

# enable service
sudo systemctl enable docker.service
sudo systemctl start docker.service

# restart machine/logout-in
echo "docker installed, restart machine/logout-in or run 'newgrp docker'"
