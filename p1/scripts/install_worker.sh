#!/bin/bash
set -e

echo "Updating packages..."
apt-get update
apt-get install -y curl

echo "Waiting for server token..."

until [ -f /vagrant/node-token ]
do
    sleep 2
done

TOKEN=$(cat /vagrant/node-token)

echo "Installing K3s agent..."

curl -sfL https://get.k3s.io | \
K3S_URL="https://192.168.56.110:6443" \
K3S_TOKEN="$TOKEN" \
INSTALL_K3S_EXEC="agent --node-ip=192.168.56.111" \
sh -

echo "K3s Agent installed."