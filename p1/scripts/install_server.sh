#!/bin/bash

apt-get update
apt-get install -y curl

echo "Updating packages..."

curl -sfL https://get.k3s.io | sudo INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --write-kubeconfig-mode=644" sh - 

echo "Checking K3s..."

which k3s

systemctl status k3s --no-pager

ls -l /var/lib/rancher/k3s/server/

echo "Waiting for K3s..."

until [ -f /var/lib/rancher/k3s/server/token ]
do
    sleep 2
done

cp /var/lib/rancher/k3s/server/token /vagrant/node-token
chmod 644 /vagrant/node-token

echo "K3s Server installed."