#!/bin/bash

# remove volume , network , container and image files
sudo docker volume prune -f
sudo docker network prune -f
sudo docker container prune -f
sudo docker image prune -a -f

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -a -q)
docker rm $(docker ps -a -f status=exited -q)

for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

sudo rm -rf /var/lib/docker \
            /etc/docker \
            ~/.docker \
            /etc/apparmor.d/docker \
            /var/run/docker.sock \
            /usr/share/keyrings/docker-archive-keyring.gpg \
            /usr/bin/docker-compose
sudo groupdel docker

# remove dependency packages related to docker
sudo apt autoremove -y
sudo apt autoclean -y

# Remove the repository to Apt sources:
sudo rm /etc/apt/sources.list.d/docker.list

# Remove Docker's official GPG key:
# ca-certificates curl will not get uninstall
sudo rm /etc/apt/keyrings/docker.asc
sudo rmdir /etc/apt/keyrings
