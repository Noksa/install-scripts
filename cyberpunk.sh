#!/usr/bin/env bash
# Cyberpunk DevOps Theme Library
# Source: curl -s https://raw.githubusercontent.com/Noksa/install-scripts/main/cyberpunk.sh

CYBER_C='\033[38;5;51m'   # Cyan
CYBER_M='\033[38;5;201m'  # Magenta
CYBER_G='\033[38;5;46m'   # Green
CYBER_Y='\033[38;5;226m'  # Yellow
CYBER_R='\033[38;5;196m'  # Red
CYBER_W='\033[38;5;255m'  # White
CYBER_D='\033[2m'         # Dim
CYBER_B='\033[1m'         # Bold
CYBER_X='\033[0m'         # Reset

cyber_log()  { echo -e "${CYBER_D}[$(date +%H:%M:%S)]${CYBER_X} ${CYBER_C}▸${CYBER_X} $1"; }
cyber_ok()   { echo -e "${CYBER_D}[$(date +%H:%M:%S)]${CYBER_X} ${CYBER_G}✔${CYBER_X} $1"; }
cyber_warn() { echo -e "${CYBER_D}[$(date +%H:%M:%S)]${CYBER_X} ${CYBER_Y}⚠${CYBER_X} $1"; }
cyber_err()  { echo -e "${CYBER_D}[$(date +%H:%M:%S)]${CYBER_X} ${CYBER_R}✖${CYBER_X} $1"; }
cyber_step() { echo -e "\n${CYBER_M}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CYBER_X}"; echo -e "${CYBER_B}${CYBER_C}⚡ $1${CYBER_X}"; echo -e "${CYBER_M}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CYBER_X}\n"; }
cyber_trap() { echo -e "\n${CYBER_R}⚡ TERMINATED BY USER ⚡${CYBER_X}"; exit 0; }
