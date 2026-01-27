#!/usr/bin/env bash
set -eo pipefail

# Load cyberpunk theme
# shellcheck disable=SC1090
source <(curl -s https://raw.githubusercontent.com/Noksa/install-scripts/main/cyberpunk.sh)
trap 'cyber_trap' SIGINT SIGTERM

banner() {
cat << 'EOF'
                                                                              
    ██╗  ██╗██████╗ ███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
    ██║ ██╔╝╚════██╗██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
    █████╔╝  █████╔╝███████╗    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
    ██╔═██╗  ╚═══██╗╚════██║    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
    ██║  ██╗██████╔╝███████║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
    ╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYBER_M}"
banner
echo -e "${CYBER_X}"
echo -e "${CYBER_D}                    ╔══════════════════════════════════════╗${CYBER_X}"
echo -e "${CYBER_D}                    ║${CYBER_X}  ${CYBER_C}🚀 LIGHTWEIGHT KUBERNETES ENGINE${CYBER_X}  ${CYBER_D}║${CYBER_X}"
echo -e "${CYBER_D}                    ╚══════════════════════════════════════╝${CYBER_X}"
echo ""

[[ -n "${INSTALL_K3S_VERSION:-}" ]] && export INSTALL_K3S_VERSION
[[ -n "${INSTALL_K3S_EXEC:-}" ]] && export INSTALL_K3S_EXEC

# ═══════════════════════════════════════════════════════════════════════════════
cyber_step "PHASE 1: CLEANUP OLD INSTALLATION"
# ═══════════════════════════════════════════════════════════════════════════════

cyber_log "Terminating existing k3s processes..."
/usr/local/bin/k3s-killall.sh 2>/dev/null && cyber_ok "Processes terminated" || cyber_warn "No running k3s found"

cyber_log "Removing previous k3s installation..."
/usr/local/bin/k3s-uninstall.sh 2>/dev/null && cyber_ok "Old k3s removed" || cyber_warn "No previous installation"
rm -rf /etc/rancher/k3s/k3s.yaml

cyber_log "Cleaning orphaned kubernetes containers..."
containers=$(docker ps --filter="label=io.kubernetes.pod.name" -aq 2>/dev/null || true)
if [[ -n "$containers" ]]; then
  docker rm "$containers" --force >/dev/null 2>&1 && cyber_ok "Containers purged" || cyber_warn "No containers to remove"
else
  cyber_warn "No orphaned containers found"
fi

# ═══════════════════════════════════════════════════════════════════════════════
cyber_step "PHASE 2: DEPLOY K3S CLUSTER"
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${CYBER_D}┌─────────────────────────────────────────────────────────────────────────────┐${CYBER_X}"
echo -e "${CYBER_D}│${CYBER_X} ${CYBER_W}HOME${CYBER_X}    ${CYBER_C}→${CYBER_X} ${CYBER_G}$HOME${CYBER_X}"
echo -e "${CYBER_D}│${CYBER_X} ${CYBER_W}USER${CYBER_X}    ${CYBER_C}→${CYBER_X} ${CYBER_G}$USER${CYBER_X}"
[[ -n "${INSTALL_K3S_VERSION:-}" ]] && echo -e "${CYBER_D}│${CYBER_X} ${CYBER_W}VERSION${CYBER_X} ${CYBER_C}→${CYBER_X} ${CYBER_G}${INSTALL_K3S_VERSION}${CYBER_X}"
echo -e "${CYBER_D}└─────────────────────────────────────────────────────────────────────────────┘${CYBER_X}"
echo ""

cyber_log "Downloading and installing k3s..."
if curl -sfL https://get.k3s.io | bash; then
  cyber_ok "K3s installed successfully"
else
  cyber_err "Installation failed!"
  exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
cyber_step "PHASE 3: CONFIGURE KUBECONFIG"
# ═══════════════════════════════════════════════════════════════════════════════


cyber_log "Creating kubeconfig directory..."
mkdir -p "${HOME}/.kube"
chmod 0700 "${HOME}/.kube"
chown "${USER}" "${HOME}/.kube"
cyber_ok "Directory ready: ${HOME}/.kube"

REAL_KUBECONFIG_PATH="${HOME}/.kube/k3s_config"
cyber_log "Copying kubeconfig..."
rm -rf "${REAL_KUBECONFIG_PATH}"
cp /etc/rancher/k3s/k3s.yaml "${REAL_KUBECONFIG_PATH}"
cyber_ok "Kubeconfig copied"
cyber_log "Renaming context to 'k3s'..."
KUBECONFIG="${REAL_KUBECONFIG_PATH}" kubectl config rename-context default k3s >/dev/null
cyber_ok "Context renamed"
chown "${USER}" "${REAL_KUBECONFIG_PATH}"
chmod 0600 "${REAL_KUBECONFIG_PATH}"

# ═══════════════════════════════════════════════════════════════════════════════
cyber_step "DEPLOYMENT COMPLETE"
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${CYBER_G}"
cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                                                           ║
    ║   ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗██╗██╗██╗      ║
    ║   ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝██║██║██║      ║
    ║   ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗██║██║██║      ║
    ║   ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║╚═╝╚═╝╚═╝      ║
    ║   ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║██╗██╗██╗      ║
    ║   ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝╚═╝╚═╝╚═╝      ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${CYBER_X}"

echo -e "${CYBER_D}┌─────────────────────────────────────────────────────────────────────────────┐${CYBER_X}"
echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_Y}🔥 QUICK START${CYBER_X}                                                            ${CYBER_D}│${CYBER_X}"
echo -e "${CYBER_D}│${CYBER_X}                                                                             ${CYBER_D}│${CYBER_X}"
echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_W}export KUBECONFIG=\"${REAL_KUBECONFIG_PATH}\"${CYBER_X}                                      ${CYBER_D}│${CYBER_X}"
echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_W}kubectl get pods -A${CYBER_X}                                                       ${CYBER_D}│${CYBER_X}"
echo -e "${CYBER_D}│${CYBER_X}                                                                             ${CYBER_D}│${CYBER_X}"
echo -e "${CYBER_D}└─────────────────────────────────────────────────────────────────────────────┘${CYBER_X}"
echo ""
echo -e "${CYBER_C}⚡${CYBER_X} ${CYBER_D}K3s is ready. Welcome to the edge.${CYBER_X} ${CYBER_C}⚡${CYBER_X}"
echo ""
