#!/bin/bash


#Forwarding IPv4 and letting iptables see bridged traffic

if [ $1 ]; then
	CRD_VERSION=$1
else
	CRD_VERSION=1.7.2
fi


if [ $2 ]; then
	RUNC_VERSION=$2
else
	RUNC_VERSION=1.1.7
fi


if [ $3 ]; then
	CNI_VERSION=$3
else
	CNI_VERSION=1.3.0
fi


if [$4 ]; then
	CRICTL_VERSION=$4
else
	CRICTL_VERSION="v1.27.0"
fi

#swapoff
swapoff -a

#Forwarding IPv4 and letting iptables see bridged traffic
echo "Forwarding IPv4 and letting iptables see bridged traffic"

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system


#installing containerd

wget https://github.com/containerd/containerd/releases/download/v${CRD_VERSION}/containerd-${CRD_VERSION}-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-${CRD_VERSION}-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mkdir -p /usr/local/lib/systemd/system/
cp containerd.service /usr/local/lib/systemd/system/
systemctl daemon-reload
systemctl enable --now containerd

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml  
sed -i 's#registry.k8s.io/pause:3.8#registry.k8s.io/pause:3.9#' /etc/containerd/config.toml
systemctl restart containerd


# installing runc

wget https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

#installing cni

wget https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v${CNI_VERSION}.tgz

#installing crictl
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-amd64.tar.gz
tar zxvf crictl-$CRICTL_VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$CRICTL_VERSION-linux-amd64.tar.gz

cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 2
debug: true
pull-image-on-create: false
EOF


#installing kubeadm kubectl kubelet
apt-get update
apt-get install -y apt-transport-https ca-certificates curl
sudo mkdir -p -m 755 /etc/apt/keyrings
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet


