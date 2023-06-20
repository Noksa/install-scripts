#!/usr/bin/env bash

set -eo pipefail
if [[ -z "${INSTALL_K3S_VERSION:-}" ]]; then
  export INSTALL_K3S_VERSION
fi

if [[ -z "${INSTALL_K3S_EXEC:-}" ]]; then 
  export INSTALL_K3S_EXEC
fi
# delete old k3s if any and stop/remove k8s containers if they still remain
(/usr/local/bin/k3s-killall.sh || true) && (/usr/local/bin/k3s-uninstall.sh || true) && (docker rm $(docker ps --filter="label=io.kubernetes.pod.name" -aq) --force || true)
# install k3s
curl -sfL https://get.k3s.io | bash
chown $USER ~/.kube/k3s_config
chmod 0600 ~/.kube/k3s_config
# ensure that ~/.kube directory has execute permission for us
chmod 0700 ~/.kube
KUBECONFIG=~/.kube/k3s_config kubectl config rename-context default k3s

echo -e "k3s has been installed!\nCheck if it works:\nKUBECONFIG=~/.kube/k3s_config kubectl get pods -A"
