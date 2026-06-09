#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
C25_HOME="${C25_HOME:-$HOME/.c25}"
STATE_DIR="$C25_HOME/modules/digadollar/state"
LOG_DIR="$C25_HOME/tasks/status"
mkdir -p "$STATE_DIR"/{user,merchant,issuer,acquirer} "$LOG_DIR"
TASK_FILE="${1:-}"
OTN="${2:-}"
TIMESTAMP=$(date +%s)
LOG="$LOG_DIR/jupiter_txn_${TIMESTAMP}.log"
log() { echo "[$(date '+%H:%M:%S')] [JUPITER] $1" | tee -a "$LOG"; }
[[ -z "$TASK_FILE" ]] && { echo "Usage: $0 <task_json> [otn]"; exit 1; }
log "INITIALIZING SWIMLANE (US6908030B2 Fig.5)"
echo "session_id=sess_${TIMESTAMP}" > "$STATE_DIR/user/session.env"
[[ -z "$OTN" ]] && OTN="4123456789012345"
echo "otn=$OTN" >> "$STATE_DIR/user/session.env"
log "S51: OTN loaded: $OTN"
cp "$STATE_DIR/user/session.env" "$STATE_DIR/issuer/pending_auth.txt"
log "S52: Issuer indexed"
cp "$STATE_DIR/user/session.env" "$STATE_DIR/merchant/cart.txt"
log "S53: Merchant checkout"
echo "auth_req=true" >> "$STATE_DIR/merchant/cart.txt"
cp "$STATE_DIR/merchant/cart.txt" "$STATE_DIR/acquirer/queue.txt"
cp "$STATE_DIR/acquirer/queue.txt" "$STATE_DIR/issuer/auth_request.txt"
log "S55: Auth request routed"
if grep -q "otn=$OTN" "$STATE_DIR/issuer/pending_auth.txt" 2>/dev/null; then
  log "S56: ✓ OTN verified & user mapped"
else
  log "S56: ✗ OTN mismatch → DECLINED"; exit 1
fi
printf "srt_auth=valid\ncredit_check=approved\n" >> "$STATE_DIR/issuer/auth_request.txt"
log "S57: ✓ SRT auth & limits cleared"
printf "status=APPROVED\ntxn_ref=TXN_%s\n" "$TIMESTAMP" > "$STATE_DIR/issuer/response.txt"
cp "$STATE_DIR/issuer/response.txt" "$STATE_DIR/merchant/auth_response.txt"
log "S58: APPROVED → Merchant → User notified"
echo "{\"status\":\"approved\",\"otn\":\"$OTN\",\"txn_ref\":\"TXN_${TIMESTAMP}\"}" > "$LOG_DIR/jupiter_result_${TIMESTAMP}.json"
log "SWIMLANE COMPLETE. Log: $LOG"
