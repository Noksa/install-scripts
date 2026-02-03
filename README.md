# install-scripts

## k3s-docker-compat

Check if a k3s version is compatible with your local Docker daemon.

```shell
# Check compatibility for a specific k3s version
curl -s "https://raw.githubusercontent.com/Noksa/install-scripts/main/k3s-docker-compat.sh" | bash -s -- -k v1.29.15+k3s1

# Show more Docker versions in the matrix (±3 instead of default ±2)
curl -s "https://raw.githubusercontent.com/Noksa/install-scripts/main/k3s-docker-compat.sh" | bash -s -- -k v1.29.15+k3s1 -r 3

# List recent k3s releases
curl -s "https://raw.githubusercontent.com/Noksa/install-scripts/main/k3s-docker-compat.sh" | bash -s -- -l
```

Exit codes:
- `0` - Compatible
- `1` - Incompatible or Docker not installed

## k3s

Fresh install k3s. Removes old k3s if it exists.

When using `--docker`, the script automatically checks Docker compatibility and prompts to continue if incompatible. Skip with `K3S_DOCKER_COMPAT_SKIP=1`.

```shell
# Pods CIDR
CLUSTER_CIDR="192.168.44.0/23"
# Services CIDR
SERVICES_CIDR="192.168.46.0/23"

curl -s https://raw.githubusercontent.com/Noksa/install-scripts/main/k3s.sh | \
  INSTALL_K3S_VERSION="v1.29.15+k3s1" \
  INSTALL_K3S_EXEC="server --docker --disable=traefik --cluster-cidr=${CLUSTER_CIDR} --service-cidr=${SERVICES_CIDR} --write-kubeconfig-mode 0600 --kube-apiserver-arg service-node-port-range=1-65000" \
  sudo -E HOME=$HOME USER=$USER bash
```