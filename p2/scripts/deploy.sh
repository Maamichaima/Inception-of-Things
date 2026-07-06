#!/bin/bash
set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

kubectl apply -f /vagrant/confs/

echo "All apps deployed. Test with:"
echo "  curl -H 'Host: app1.com' http://192.168.56.110"
echo "  curl -H 'Host: app2.com' http://192.168.56.110"
echo "  curl http://192.168.56.110"