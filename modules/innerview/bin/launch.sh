#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
C25_HOME="${C25_HOME:-$HOME/.c25}"
STATE="$C25_HOME/modules/innerview/state"
mkdir -p "$STATE"
echo "[{\"agent\":\"Venus\",\"status\":\"idle\",\"ts\":\"$(date -Iseconds)\"},{\"agent\":\"Mars\",\"status\":\"idle\",\"ts\":\"$(date -Iseconds)\"},{\"agent\":\"Jupiter\",\"status\":\"routing\",\"ts\":\"$(date -Iseconds)\"}]" > "$STATE/agent_meta.json"
echo "[{\"task_id\":\"ruview_esp32_flash\",\"state\":\"pending\"},{\"task_id\":\"innerview_ui_init\",\"state\":\"queued\"}]" > "$STATE/queue.json"
echo "[{\"hash\":\"sha256:$(date +%s | sha256sum | cut -d' ' -f1)\",\"ts\":\"$(date -Iseconds)\",\"sig\":\"MOCK\",\"alg\":\"ed25519\"}]" > "$STATE/witness.jsonl"
echo "[innerView] Serving → http://127.0.0.1:8899"
cd "$C25_HOME/modules/innerview/ui"
python3 -m http.server 8899 &
PID=$!
echo "PID: $PID | Ctrl+C to stop"
command -v termux-open-url &>/dev/null && termux-open-url http://127.0.0.1:8899 || echo "Open http://127.0.0.1:8899 manually"
wait $PID
