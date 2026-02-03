#!/usr/bin/env bash
#
# k3s to Docker version compatibility checker (dynamic version)
# Fetches version info directly from GitHub repos
#

set -eo pipefail

# Load cyberpunk theme
# shellcheck disable=SC1090
source <(curl -s https://raw.githubusercontent.com/Noksa/install-scripts/main/cyberpunk.sh)
trap 'cyber_trap' SIGINT SIGTERM



banner() {
cat << 'EOF'
                                                                              
    ██╗  ██╗██████╗ ███████╗    ██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗ 
    ██║ ██╔╝╚════██╗██╔════╝    ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗
    █████╔╝  █████╔╝███████╗    ██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝
    ██╔═██╗  ╚═══██╗╚════██║    ██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗
    ██║  ██╗██████╔╝███████║    ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║
    ╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                                                              
     ██████╗ ██████╗ ███╗   ███╗██████╗  █████╗ ████████╗
    ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝
    ██║     ██║   ██║██╔████╔██║██████╔╝███████║   ██║   
    ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██╔══██║   ██║   
    ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ██║  ██║   ██║   
     ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝   ╚═╝   
EOF
}

print_usage() {
    echo -e "${CYBER_D}┌─────────────────────────────────────────────────────────────────────────────┐${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_Y}📖 USAGE${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_W}$0 -k <VERSION>${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_C}OPTIONS:${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}    ${CYBER_G}-k, --k3s-version VERSION${CYBER_X}    Check k3s version against local Docker"
    echo -e "${CYBER_D}│${CYBER_X}    ${CYBER_G}-l, --list-releases${CYBER_X}          List recent k3s releases"
    echo -e "${CYBER_D}│${CYBER_X}    ${CYBER_G}-h, --help${CYBER_X}                   Show this help"
    echo -e "${CYBER_D}│${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_C}EXAMPLES:${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}    ${CYBER_W}$0 -k v1.29.0+k3s1${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}    ${CYBER_W}$0 -l${CYBER_X}"
    echo -e "${CYBER_D}└─────────────────────────────────────────────────────────────────────────────┘${CYBER_X}"
}

ensure_deps() {
    for cmd in curl jq; do
        command -v "$cmd" &>/dev/null || { cyber_err "$cmd is required"; exit 1; }
    done
}



# Fetch both DefaultVersion and MinSupportedAPIVersion from moby/moby
get_docker_api_info() {
    local docker_major=$1
    
    # Find latest tag for this major version
    local tag=$(curl -sf "https://api.github.com/repos/moby/moby/tags?per_page=100" | \
        jq -r ".[].name" | grep "^v${docker_major}\." | head -1)
    
    if [[ -z "$tag" ]]; then
        # Fallback for unreleased versions - Docker 29+ requires minimum 1.44
        if [[ "$docker_major" -ge 29 ]]; then
            echo "1.52:1.44"
            return 0
        fi
        echo "unknown:1.24"
        return 1
    fi
    
    local api_common=$(curl -sf "https://raw.githubusercontent.com/moby/moby/${tag}/api/common.go")
    [[ -z "$api_common" ]] && { echo "unknown:1.24"; return 1; }
    
    local default_ver=$(echo "$api_common" | grep 'DefaultVersion.*=' | grep -o '"[0-9.]*"' | tr -d '"' | head -1)
    local min_ver=$(echo "$api_common" | grep 'MinSupportedAPIVersion.*=' | grep -o '"[0-9.]*"' | tr -d '"' | head -1)
    
    echo "${default_ver:-unknown}:${min_ver:-1.24}"
}

get_k3s_cridockerd_version() {
    local k3s_tag=$1
    
    local go_mod=$(curl -sf "https://raw.githubusercontent.com/k3s-io/k3s/${k3s_tag}/go.mod")
    
    [[ -z "$go_mod" ]] && { echo "error"; return 1; }
    
    # k3s uses replace directives to point to k3s-io fork with specific tags like v0.3.12-k3s1.28
    # First check for replace directive: github.com/Mirantis/cri-dockerd => github.com/k3s-io/cri-dockerd v0.3.12-k3s1.28
    local ver=$(echo "$go_mod" | grep -E 'Mirantis/cri-dockerd\s+=>' | sed -E 's/.*k3s-io\/cri-dockerd[[:space:]]+([^[:space:]]+).*/\1/' | head -1)
    
    # Fallback to direct dependency if no replace
    [[ -z "$ver" ]] && ver=$(echo "$go_mod" | grep 'k3s-io/cri-dockerd' | grep -v '=>' | sed -E 's/.*k3s-io\/cri-dockerd[[:space:]]+([^[:space:]]+).*/\1/' | head -1)
    [[ -z "$ver" ]] && ver=$(echo "$go_mod" | grep 'Mirantis/cri-dockerd' | grep -v '=>' | sed -E 's/.*Mirantis\/cri-dockerd[[:space:]]+([^[:space:]]+).*/\1/' | head -1)
    
    [[ -n "$ver" ]] && echo "$ver" || echo "unknown"
}

get_cridockerd_docker_version() {
    local cridockerd_ver=$1
    
    local go_mod=$(curl -sf "https://raw.githubusercontent.com/k3s-io/cri-dockerd/${cridockerd_ver}/go.mod")
    [[ -z "$go_mod" ]] && go_mod=$(curl -sf "https://raw.githubusercontent.com/Mirantis/cri-dockerd/${cridockerd_ver}/go.mod")
    
    [[ -z "$go_mod" ]] && { echo "unknown"; return 1; }
    
    local ver=$(echo "$go_mod" | grep 'docker/docker' | sed -E 's/.*docker\/docker[[:space:]]+([v0-9.+incompatible]+).*/\1/' | head -1)
    [[ -n "$ver" ]] && echo "$ver" || echo "unknown"
}

get_docker_api_version() {
    local docker_ver=$1
    
    local clean_ver=$(echo "$docker_ver" | sed 's/+incompatible//')
    
    local api_common=$(curl -sf "https://raw.githubusercontent.com/moby/moby/${clean_ver}/api/common.go")
    [[ -z "$api_common" ]] && { echo "unknown"; return 1; }
    
    local api_ver=$(echo "$api_common" | grep 'DefaultVersion.*=' | grep -o '"[0-9.]*"' | tr -d '"' | head -1)
    [[ -n "$api_ver" ]] && echo "$api_ver" || echo "unknown"
}

compare_versions() {
    [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]]
}

get_docker_version() {
    command -v docker &>/dev/null && docker version --format '{{.Server.Version}}' 2>/dev/null || echo "not_installed"
}

get_docker_api_local() {
    command -v docker &>/dev/null && docker version --format '{{.Server.APIVersion}}' 2>/dev/null || echo "not_installed"
}

get_docker_min_api_local() {
    command -v docker &>/dev/null && docker version --format '{{.Server.MinAPIVersion}}' 2>/dev/null || echo "not_installed"
}

list_k3s_releases() {
    cyber_step "FETCHING K3S RELEASES"
    cyber_log "Querying GitHub API..."
    
    echo ""
    echo -e "${CYBER_D}┌─────────────────────────────────────────────────────────────────────────────┐${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_Y}📦 RECENT K3S RELEASES${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}"
    
    curl -sf "https://api.github.com/repos/k3s-io/k3s/releases?per_page=20" | \
        jq -r '.[] | "    \(.tag_name)\t\(.published_at | split("T")[0])"' | \
        while read -r line; do
            echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_G}${line}${CYBER_X}"
        done
    
    echo -e "${CYBER_D}└─────────────────────────────────────────────────────────────────────────────┘${CYBER_X}"
    cyber_ok "Release list fetched"
}

check_k3s_compat() {
    local k3s_tag=$1
    
    # Show local Docker info if available
    local local_docker_ver=$(get_docker_version)
    local local_docker_api=$(get_docker_api_local)
    local local_docker_min_api=$(get_docker_min_api_local)
    
    if [[ "$local_docker_ver" == "not_installed" ]]; then
        cyber_err "Docker is not installed"
        return 1
    fi
    
    echo -e "${CYBER_D}┌─────────────────────────────────────────────────────────────────────────────┐${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_Y}🐳 LOCAL DOCKER${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_W}VERSION${CYBER_X}  ${CYBER_C}→${CYBER_X} ${CYBER_G}$local_docker_ver${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_W}API${CYBER_X}      ${CYBER_C}→${CYBER_X} ${CYBER_G}$local_docker_api${CYBER_X}"
    echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_W}MIN API${CYBER_X}  ${CYBER_C}→${CYBER_X} ${CYBER_G}$local_docker_min_api${CYBER_X}"
    echo -e "${CYBER_D}└─────────────────────────────────────────────────────────────────────────────┘${CYBER_X}"
    echo ""
    
    cyber_step "ANALYZING K3S $k3s_tag"
    
    cyber_log "Fetching k3s dependency info..."
    local cridockerd_ver=$(get_k3s_cridockerd_version "$k3s_tag")
    if [[ "$cridockerd_ver" == "error" || "$cridockerd_ver" == "unknown" ]]; then
        cyber_err "Could not determine cri-dockerd version for k3s $k3s_tag"
        cyber_warn "Make sure the version exists and includes the 'v' prefix (e.g., v1.29.0+k3s1)"
        return 1
    fi
    cyber_ok "k3s $k3s_tag uses cri-dockerd: $cridockerd_ver"
    
    cyber_log "Fetching cri-dockerd dependency info..."
    local docker_client_ver=$(get_cridockerd_docker_version "$cridockerd_ver")
    if [[ "$docker_client_ver" == "unknown" ]]; then
        cyber_err "Could not determine Docker client version"
        return 1
    fi
    cyber_ok "cri-dockerd uses docker client: $docker_client_ver"
    
    cyber_log "Fetching Docker API version..."
    local api_version=$(get_docker_api_version "$docker_client_ver")
    if [[ "$api_version" == "unknown" ]]; then
        cyber_err "Could not determine API version"
        return 1
    fi
    cyber_ok "cri-dockerd speaks Docker API: $api_version"
    
    echo ""
    cyber_step "DOCKER DAEMON COMPATIBILITY MATRIX"
    cyber_log "Building compatibility matrix..."
    
    # Get local Docker major version and build range around it
    local local_major=$(echo "$local_docker_ver" | cut -d. -f1)
    local min_ver=$((local_major - 1))
    local max_ver=$((local_major + 1))
    [[ $min_ver -lt 24 ]] && min_ver=24
    
    echo ""
    echo -e "${CYBER_D}┌─────────────────────────────────────────────────────────────────────────────┐${CYBER_X}"
    printf "${CYBER_D}│${CYBER_X}  ${CYBER_C}%-15s${CYBER_X} ${CYBER_C}%-10s${CYBER_X} ${CYBER_C}%-10s${CYBER_X} ${CYBER_C}%-20s${CYBER_X}      ${CYBER_D}│${CYBER_X}\n" "DOCKER" "API" "MIN API" "COMPATIBLE"
    echo -e "${CYBER_D}├─────────────────────────────────────────────────────────────────────────────┤${CYBER_X}"
    
    for ((dv=max_ver; dv>=min_ver; dv--)); do
        local api_info=$(get_docker_api_info "$dv" 2>/dev/null)
        local max_api=$(echo "$api_info" | cut -d: -f1)
        local min_api=$(echo "$api_info" | cut -d: -f2)
        [[ "$max_api" == "unknown" ]] && continue
        local compat="YES"
        local compat_color="${CYBER_G}"
        if ! compare_versions "$api_version" "$min_api"; then
            compat="NO (needs >=$min_api)"
            compat_color="${CYBER_R}"
        fi
        local label="${dv}.x"
        [[ "$dv" == "$local_major" ]] && label="${dv}.x (local)"
        printf "${CYBER_D}│${CYBER_X}  ${CYBER_W}%-15s${CYBER_X} ${CYBER_Y}%-10s${CYBER_X} ${CYBER_Y}%-10s${CYBER_X} ${compat_color}%-20s${CYBER_X}      ${CYBER_D}│${CYBER_X}\n" "$label" "$max_api" "$min_api" "$compat"
    done
    
    echo -e "${CYBER_D}└─────────────────────────────────────────────────────────────────────────────┘${CYBER_X}"
    echo ""
    cyber_ok "Summary: k3s $k3s_tag uses API $api_version"
    
    # Show verdict against local Docker
    echo ""
    cyber_step "VERDICT"
    
    if compare_versions "$api_version" "$local_docker_min_api"; then
        cyber_ok "GOOD: k3s $k3s_tag (API $api_version) works with your Docker $local_docker_ver (min API $local_docker_min_api)"
        return 0
    else
        cyber_err "BAD: k3s $k3s_tag (API $api_version) cannot work with your Docker $local_docker_ver (min API $local_docker_min_api)"
        echo ""
        echo -e "${CYBER_D}┌─────────────────────────────────────────────────────────────────────────────┐${CYBER_X}"
        echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_Y}⚡ SOLUTIONS${CYBER_X}"
        echo -e "${CYBER_D}│${CYBER_X}"
        echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_W}1.${CYBER_X} Upgrade k3s to a version with API >= $local_docker_min_api"
        echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_W}2.${CYBER_X} Downgrade Docker to a version with min API <= $api_version"
        echo -e "${CYBER_D}│${CYBER_X}  ${CYBER_W}3.${CYBER_X} Use containerd instead of Docker (remove --docker flag)"
        echo -e "${CYBER_D}└─────────────────────────────────────────────────────────────────────────────┘${CYBER_X}"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

ensure_deps

# Show banner
echo -e "${CYBER_M}"
banner
echo -e "${CYBER_X}"
echo -e "${CYBER_D}                    ╔══════════════════════════════════════╗${CYBER_X}"
echo -e "${CYBER_D}                    ║${CYBER_X}  ${CYBER_C}🔌 VERSION COMPATIBILITY CHECKER${CYBER_X}"
echo -e "${CYBER_D}                    ╚══════════════════════════════════════╝${CYBER_X}"
echo ""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--k3s-version) check_k3s_compat "$2"; exit $? ;;
        -l|--list-releases) list_k3s_releases; exit 0 ;;
        -h|--help) print_usage; exit 0 ;;
        *) cyber_err "Unknown option: $1"; print_usage; exit 1 ;;
    esac
    shift
done

print_usage
