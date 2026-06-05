#!/usr/bin/env bash
# install.sh — Instala a integração Obsidian ↔ Claude Code
# Uso: bash install.sh
# Ou com vault já definido: OBSIDIAN_VAULT_PATH="/caminho/vault" bash install.sh

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SKILLS_DIR="$CLAUDE_DIR/skills"
SETTINGS="$CLAUDE_DIR/settings.json"
ENV_FILE="$CLAUDE_DIR/obsidian.env"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Cores ──────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Obsidian ↔ Claude Code — Instalação   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Verificações ───────────────────────────────────────────────────────────────
command -v python3 &>/dev/null || err "Python 3 não encontrado. Instale antes de continuar."
[ -d "$CLAUDE_DIR" ] || err "Claude Code não encontrado em $CLAUDE_DIR. Instale o Claude Code primeiro."

# ── Vault path ─────────────────────────────────────────────────────────────────
if [ -z "$OBSIDIAN_VAULT_PATH" ] && [ -f "$ENV_FILE" ]; then
  OBSIDIAN_VAULT_PATH=$(grep "^OBSIDIAN_VAULT_PATH=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
fi

if [ -z "$OBSIDIAN_VAULT_PATH" ]; then
  echo "Qual é o caminho completo do seu Obsidian vault?"
  echo "  Exemplo: /Users/seunome/Documents/MeuVault"
  echo ""
  read -r -p "Vault path: " OBSIDIAN_VAULT_PATH
fi

# Remove trailing slash
OBSIDIAN_VAULT_PATH="${OBSIDIAN_VAULT_PATH%/}"

if [ ! -d "$OBSIDIAN_VAULT_PATH" ]; then
  warn "Diretório '$OBSIDIAN_VAULT_PATH' não existe ainda."
  read -r -p "Criar agora? (s/N): " CREATE_VAULT
  if [[ "${CREATE_VAULT,,}" == "s" ]]; then
    mkdir -p "$OBSIDIAN_VAULT_PATH/wiki" "$OBSIDIAN_VAULT_PATH/projects" "$OBSIDIAN_VAULT_PATH/raw"
    ok "Vault criado em $OBSIDIAN_VAULT_PATH"
  else
    err "Vault não encontrado. Abra o Obsidian e crie o vault primeiro."
  fi
fi

ok "Vault: $OBSIDIAN_VAULT_PATH"

# ── Cria diretórios ────────────────────────────────────────────────────────────
mkdir -p "$SCRIPTS_DIR" "$SKILLS_DIR"

# ── Salva config de vault ──────────────────────────────────────────────────────
echo "OBSIDIAN_VAULT_PATH=\"$OBSIDIAN_VAULT_PATH\"" > "$ENV_FILE"
ok "Configuração salva em $ENV_FILE"

# ── Copia scripts ──────────────────────────────────────────────────────────────
cp "$REPO_DIR/scripts/obsidian-context.py"     "$SCRIPTS_DIR/obsidian-context.py"
cp "$REPO_DIR/scripts/obsidian-session-end.sh" "$SCRIPTS_DIR/obsidian-session-end.sh"
chmod +x "$SCRIPTS_DIR/obsidian-context.py" "$SCRIPTS_DIR/obsidian-session-end.sh"
ok "Scripts instalados em $SCRIPTS_DIR"

# ── Copia skill ────────────────────────────────────────────────────────────────
cp "$REPO_DIR/skills/obsidian-sync.md" "$SKILLS_DIR/obsidian-sync.md"
ok "Skill /obsidian-sync instalada"

# ── Atualiza settings.json (merge — não sobrescreve) ──────────────────────────
HOOK_CONTEXT="python3 $SCRIPTS_DIR/obsidian-context.py"
HOOK_STOP="bash $SCRIPTS_DIR/obsidian-session-end.sh"

python3 - <<PYEOF
import json, pathlib, sys

settings_path = pathlib.Path("$SETTINGS")

if settings_path.exists():
    try:
        config = json.loads(settings_path.read_text())
    except Exception:
        config = {}
else:
    config = {}

hooks = config.setdefault("hooks", {})

# UserPromptSubmit
ups = hooks.setdefault("UserPromptSubmit", [])
hook_entry = {
    "matcher": "",
    "hooks": [{"type": "command", "command": "$HOOK_CONTEXT"}]
}
# Verifica se já existe para não duplicar
already = any(
    any(h.get("command", "") == "$HOOK_CONTEXT" for h in e.get("hooks", []))
    for e in ups
)
if not already:
    ups.append(hook_entry)

# Stop
stop = hooks.setdefault("Stop", [])
stop_entry = {
    "matcher": "",
    "hooks": [{"type": "command", "command": "$HOOK_STOP"}]
}
already_stop = any(
    any(h.get("command", "") == "$HOOK_STOP" for h in e.get("hooks", []))
    for e in stop
)
if not already_stop:
    stop.append(stop_entry)

settings_path.write_text(json.dumps(config, indent=2, ensure_ascii=False) + "\n")
print("ok")
PYEOF

ok "Hooks adicionados em $SETTINGS"

# ── Testa o script de contexto ─────────────────────────────────────────────────
echo ""
echo "Testando injeção de contexto..."
RESULT=$(echo "{\"cwd\":\"$OBSIDIAN_VAULT_PATH\"}" | \
  OBSIDIAN_VAULT_PATH="$OBSIDIAN_VAULT_PATH" python3 "$SCRIPTS_DIR/obsidian-context.py" 2>/dev/null)

if echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('additionalContext')" 2>/dev/null; then
  ok "Contexto lido com sucesso do vault"
else
  warn "Vault sem notas ainda — crie arquivos .md em $OBSIDIAN_VAULT_PATH/wiki/ ou projects/"
fi

# ── Resumo ─────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Instalação concluída!                             ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  • Reinicie o Claude Code para ativar os hooks      ║"
echo "║  • Use /obsidian-sync para sincronizar sessões      ║"
echo "║  • Vault configurado:                               ║"
echo "║    $OBSIDIAN_VAULT_PATH" | head -c 56
echo ""
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Para alterar o vault depois:"
echo "  Edite $ENV_FILE"
echo ""
