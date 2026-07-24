#!/bin/bash
set -e

echo "Updating packages..."
apt-get update -y

echo "Installing curl..."
apt-get install -y curl

echo "Installing K3s..."
curl -sfL https://get.k3s.io | sh -

echo "Waiting for K3s to start..."
until kubectl get nodes >/dev/null 2>&1; do
    sleep 2
done


echo "K3s is ready!"

# Allow the vagrant user to use kubectl
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Replace localhost with the VM IP
sed -i "s/127.0.0.1/192.168.56.110/g" /home/vagrant/.kube/config

echo "Installation complete!"