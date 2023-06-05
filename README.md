# install-scripts


## k3s
```shell
# FRESH install k3s. It will remove old k3s if it exists
# Pods CIDR
CLUSTER_CIDR="192.168.44.0/23"
# Services CIDR
SERVICES_CIDR="192.168.46.0/23"
curl -s https://raw.githubusercontent.com/Noksa/install-scripts/main/k3s.sh | INSTALL_K3S_VERSION="v1.25.8+k3s1" INSTALL_K3S_EXEC="server --docker --disable=traefik --cluster-cidr=${CLUSTER_CIDR} --service-cidr=${SERVICES_CIDR} --write-kubeconfig-mode 0600 --kube-apiserver-arg service-node-port-range=1-65000 -o ~/.kube/k3s_config" sudo -E HOME=$HOME USER=$USER bash
```