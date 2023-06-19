#!/bin/bash

# Latest docker engine for ubuntu installation script


echo "removing any old versions if present to avoid conflict"
if  apt-get purge -y  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null; then
	rm -rf /var/lib/docker
	rm -rf /var/lib/containerd
	echo "old insatllation of docker is removed successfully"
else
	echo "no old installations of docker found"
fi

#installing dependencies
apt-get update
echo "installing ca-certificates curl gnupg"
apt-get install -y ca-certificates curl gnupg

#Add Docker’s official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

#command to set up the repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
   tee /etc/apt/sources.list.d/docker.list > /dev/null


#install docker engine
apt-get update
echo "installing docker engine latest version"
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


#post installation steps
echo "adding $USER to docker group"
if grep -q "^docker" /etc/group; then
	echo "Group 'docker' already exists"
else
	groupadd docker
	echo "Group 'docker' created"
fi
usermod -aG docker $USER

echo "Verify that the Docker Engine installation is successful by running the hello-world image"
echo "docker run hello-world"
