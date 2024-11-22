#!/usr/bin/env bash

trap 'exit 0' SIGINT SIGTERM

set -eo pipefail
if [[ -n "${INSTALL_K3S_VERSION:-}" ]]; then
  export INSTALL_K3S_VERSION
fi

if [[ -n "${INSTALL_K3S_EXEC:-}" ]]; then 
  export INSTALL_K3S_EXEC
fi

# delete old k3s if any and stop/remove k8s containers if they still remain
(/usr/local/bin/k3s-killall.sh || true) && (/usr/local/bin/k3s-uninstall.sh || true) && (docker rm $(docker ps --filter="label=io.kubernetes.pod.name" -aq) --force || true)
# install k3s
echo -e "\nHOME: $HOME\nUSER: $USER\n"
curl -sfL https://get.k3s.io | bash

chown "${USER}" /etc/rancher/k3s/k3s.yaml
chmod 0600 /etc/rancher/k3s/k3s.yaml
# ensure that ~/.kube directory has execute permission for us
chmod 0700 ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/k3s_config || true
KUBECONFIG=~/.kube/k3s_config kubectl config rename-context default k3s

echo -e "k3s has been installed!\nCheck if it works:\nKUBECONFIG=~/.kube/k3s_config kubectl get pods -A"
