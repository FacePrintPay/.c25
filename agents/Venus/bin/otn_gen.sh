#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
C25_HOME="${C25_HOME:-$HOME/.c25}"
STATE="$C25_HOME/modules/digadollar/state/venus"
LOG_DIR="$C25_HOME/tasks/status"
mkdir -p "$STATE" "$LOG_DIR"
LOG="$LOG_DIR/venus_otn_$(date +%s).log"
log() { echo "[$(date '+%H:%M:%S')] [VENUS] $1" | tee -a "$LOG"; }

NET_ID="${1:-4}"
ISSUER_ID="${2:-1234}"
TXN_AMOUNT="${3:-0.00}"
MERCHANT_ID="${4:-9876543210}"
PERM_CARD_LAST4="${5:-1111}"

log "GENERATING OTN (Net:$NET_ID Issuer:$ISSUER_ID)"

# 1. 10-digit Txn ID via HMAC
RAW="${NET_ID}${ISSUER_ID}${TXN_AMOUNT}${MERCHANT_ID}${PERM_CARD_LAST4}$(date +%s%N)"
HMAC=$(echo -n "$RAW" | openssl dgst -sha256 -hmac "c25_venus_secret" -hex 2>/dev/null | awk '{print $NF}')
DEC=$(printf "%d" "0x${HMAC:0:8}")
TXN_ID=$(printf "%010d" $((DEC % 10000000000)))

# 2. Assemble 15-digit prefix
FIRST_15="${NET_ID}${ISSUER_ID}${TXN_ID}"

# 3. Luhn Checksum
calc_luhn() {
  local s="$1" sum=0 alt=0 len=${#s}
  for ((i=len-1; i>=0; i--)); do
    local d=${s:$i:1}
    (( alt )) && d=$((d*2)) && ((d>9)) && d=$((d-9))
    sum=$((sum+d)); alt=$((!alt))
  done
  echo $(( (10 - (sum%10)) % 10 ))
}
CHECKSUM=$(calc_luhn "$FIRST_15")
OTN="${FIRST_15}${CHECKSUM}"

log "✓ OTN GENERATED: $OTN"
log "  Format: [${NET_ID}] [${ISSUER_ID}] [${TXN_ID}] [${CHECKSUM}]"
echo "$OTN" > "$STATE/last_otn.txt"

# Agent payload
cat << EOF
{"otn":"$OTN","issuer":"$ISSUER_ID","txn_id":"$TXN_ID","checksum":"$CHECKSUM","state":"$STATE/last_otn.txt"}
EOF
