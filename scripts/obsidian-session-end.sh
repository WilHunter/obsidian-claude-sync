#!/usr/bin/env bash
# Hook Stop: registra marcador de sessão no vault ao finalizar o Claude Code.

if [ -n "$OBSIDIAN_VAULT_PATH" ]; then
  VAULT="$OBSIDIAN_VAULT_PATH"
elif [ -f "$HOME/.claude/obsidian.env" ]; then
  VAULT=$(grep "^OBSIDIAN_VAULT_PATH=" "$HOME/.claude/obsidian.env" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
fi

[ -z "$VAULT" ] && exit 0
[ ! -d "$VAULT" ] && exit 0

LOG="$VAULT/wiki/log.md"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)

PAYLOAD=$(cat)
CWD=$(echo "$PAYLOAD" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('cwd',''))" 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

# Adicione aqui os padrões do seu time
detect_project() {
  local cwd="${1,,}"
  for pattern in atheva data-engineer dw_project adm2-web app-resposavel perseu ava-courses; do
    [[ "$cwd" == *"$pattern"* ]] && { echo "atheva"; return; }
  done
  [[ "$cwd" == *"datapay"* ]] && { echo "datapay"; return; }
  [[ "$cwd" == *"spec"* ]] && { echo "spec_ia"; return; }
  [[ "$cwd" == *"vanvalu"* ]] && { echo "vanvalu"; return; }
  echo "unknown"
}

PROJECT=$(detect_project "$CWD")

if [ -f "$LOG" ]; then
  LAST=$(tail -5 "$LOG" | grep "session-marker" | grep "$DATE" | head -1)
  if [ -z "$LAST" ]; then
    printf "\n## [%s %s] session-marker | %s\n- CWD: %s\n" \
      "$DATE" "$TIME" "$PROJECT" "$CWD" >> "$LOG"
  fi
fi

exit 0
