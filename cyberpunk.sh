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
cyber_step() {
  local text="⚡ $1"
  # +1: ⚡ занимает 2 колонки в терминале, а ${#} считает за 1
  local len=$(( ${#text} + 1 ))
  # Ограничиваем: минимум 20, максимум 78 символов
  (( len < 20 )) && len=20
  (( len > 78 )) && len=78
  local line=""
  for ((i = 0; i < len; i++)); do line+="━"; done
  echo -e "\n${CYBER_M}${line}${CYBER_X}"
  echo -e "${CYBER_B}${CYBER_C}${text}${CYBER_X}"
  echo -e "${CYBER_M}${line}${CYBER_X}\n"
}
cyber_trap() { echo -e "\n${CYBER_R}⚡ TERMINATED BY USER ⚡${CYBER_X}"; exit 0; }
