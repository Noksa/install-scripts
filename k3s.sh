#!/usr/bin/env bash
trap 'echo -e "\n\033[38;5;196m⚡ TERMINATED BY USER ⚡\033[0m"; exit 0' SIGINT SIGTERM
set -eo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
#  CYBERPUNK K3S INSTALLER v2.0
# ═══════════════════════════════════════════════════════════════════════════════

C='\033[38;5;51m'   # Cyan neon
M='\033[38;5;201m'  # Magenta neon
G='\033[38;5;46m'   # Green neon
Y='\033[38;5;226m'  # Yellow
R='\033[38;5;196m'  # Red
W='\033[38;5;255m'  # White
D='\033[2m'         # Dim
B='\033[1m'         # Bold
X='\033[0m'         # Reset

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

log()  { echo -e "${D}[$(date +%H:%M:%S)]${X} ${C}▸${X} $1"; }
ok()   { echo -e "${D}[$(date +%H:%M:%S)]${X} ${G}✔${X} $1"; }
warn() { echo -e "${D}[$(date +%H:%M:%S)]${X} ${Y}⚠${X} $1"; }
err()  { echo -e "${D}[$(date +%H:%M:%S)]${X} ${R}✖${X} $1"; }
step() { echo -e "\n${M}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"; echo -e "${B}${C}⚡ $1${X}"; echo -e "${M}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}\n"; }

spin() {
  local pid=$1 msg=$2
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  while kill -0 "$pid" 2>/dev/null; do
    for f in "${frames[@]}"; do
      printf "\r${M}%s${X} %s" "$f" "$msg"
      sleep 0.1
    done
  done
  printf "\r\033[K"
}

# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${M}"
banner
echo -e "${X}"
echo -e "${D}                    ╔══════════════════════════════════════╗${X}"
echo -e "${D}                    ║${X}  ${C}🚀 LIGHTWEIGHT KUBERNETES ENGINE${X}  ${D}║${X}"
echo -e "${D}                    ╚══════════════════════════════════════╝${X}"
echo ""

[[ -n "${INSTALL_K3S_VERSION:-}" ]] && export INSTALL_K3S_VERSION
[[ -n "${INSTALL_K3S_EXEC:-}" ]] && export INSTALL_K3S_EXEC

# ═══════════════════════════════════════════════════════════════════════════════
step "PHASE 1: CLEANUP OLD INSTALLATION"
# ═══════════════════════════════════════════════════════════════════════════════

log "Terminating existing k3s processes..."
/usr/local/bin/k3s-killall.sh 2>/dev/null && ok "Processes terminated" || warn "No running k3s found"

log "Removing previous k3s installation..."
/usr/local/bin/k3s-uninstall.sh 2>/dev/null && ok "Old k3s removed" || warn "No previous installation"

log "Cleaning orphaned kubernetes containers..."
containers=$(docker ps --filter="label=io.kubernetes.pod.name" -aq 2>/dev/null || true)
if [[ -n "$containers" ]]; then
  docker rm $containers --force >/dev/null 2>&1 && ok "Containers purged" || warn "No containers to remove"
else
  warn "No orphaned containers found"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "PHASE 2: DEPLOY K3S CLUSTER"
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${D}┌─────────────────────────────────────────────────────────────────────────────┐${X}"
echo -e "${D}│${X} ${W}HOME${X}    ${C}→${X} ${G}$HOME${X}"
echo -e "${D}│${X} ${W}USER${X}    ${C}→${X} ${G}$USER${X}"
[[ -n "${INSTALL_K3S_VERSION:-}" ]] && echo -e "${D}│${X} ${W}VERSION${X} ${C}→${X} ${G}${INSTALL_K3S_VERSION}${X}"
echo -e "${D}└─────────────────────────────────────────────────────────────────────────────┘${X}"
echo ""

log "Downloading and installing k3s..."
curl -sfL https://get.k3s.io | bash &
spin $! "Installing k3s cluster..."
wait $! && ok "K3s installed successfully" || { err "Installation failed!"; exit 1; }

# ═══════════════════════════════════════════════════════════════════════════════
step "PHASE 3: CONFIGURE KUBECONFIG"
# ═══════════════════════════════════════════════════════════════════════════════

log "Setting up kubeconfig permissions..."
chown "${USER}" /etc/rancher/k3s/k3s.yaml
chmod 0600 /etc/rancher/k3s/k3s.yaml
ok "Permissions configured"

log "Creating kubeconfig directory..."
mkdir -p "${HOME}/.kube"
chmod 0700 "${HOME}/.kube"
ok "Directory ready: ${HOME}/.kube"

log "Copying kubeconfig..."
rm -rf "${HOME}/.kube/k3s_config"
cp /etc/rancher/k3s/k3s.yaml "${HOME}/.kube/k3s_config"
ok "Kubeconfig copied"

log "Renaming context to 'k3s'..."
KUBECONFIG="${HOME}/.kube/k3s_config" kubectl config rename-context default k3s >/dev/null
ok "Context renamed"

# ═══════════════════════════════════════════════════════════════════════════════
step "DEPLOYMENT COMPLETE"
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${G}"
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
echo -e "${X}"

echo -e "${D}┌─────────────────────────────────────────────────────────────────────────────┐${X}"
echo -e "${D}│${X}  ${Y}🔥 QUICK START${X}                                                            ${D}│${X}"
echo -e "${D}│${X}                                                                             ${D}│${X}"
echo -e "${D}│${X}  ${W}export KUBECONFIG=~/.kube/k3s_config${X}                                      ${D}│${X}"
echo -e "${D}│${X}  ${W}kubectl get pods -A${X}                                                       ${D}│${X}"
echo -e "${D}│${X}                                                                             ${D}│${X}"
echo -e "${D}└─────────────────────────────────────────────────────────────────────────────┘${X}"
echo ""
echo -e "${C}⚡${X} ${D}K3s is ready. Welcome to the edge.${X} ${C}⚡${X}"
echo ""
