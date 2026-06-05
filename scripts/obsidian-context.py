#!/usr/bin/env python3
"""
Hook UserPromptSubmit: injeta contexto relevante do Obsidian vault em cada prompt.
Configuração via OBSIDIAN_VAULT_PATH (env var ou ~/.claude/obsidian.env).
"""
import json
import os
import sys
from pathlib import Path


def load_vault_path() -> Path | None:
    v = os.environ.get("OBSIDIAN_VAULT_PATH")
    if v:
        return Path(v)
    env_file = Path.home() / ".claude" / "obsidian.env"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if line.startswith("OBSIDIAN_VAULT_PATH="):
                val = line.split("=", 1)[1].strip().strip('"').strip("'")
                if val:
                    return Path(val)
    return None


VAULT = load_vault_path()

# Edite este mapeamento para refletir os projetos da sua equipe
# Padrão: lista de substrings no CWD → nome da pasta em projects/
PROJECT_MAP = [
    (["atheva", "data-engineer", "dw_project", "adm2-web", "app-resposavel", "app-responsavel",
      "ia_experience", "perseu", "ava-courses"], "atheva"),
    (["datapay", "data-pay"], "datapay"),
    (["spec_ia", "spec-ia", "specia"], "spec_ia"),
    (["vanvalu", "van-valu", "aninha"], "vanvalu"),
]

MAX_CHARS = 6000


def detect_project(cwd: str) -> str | None:
    cwd_lower = cwd.lower()
    for patterns, project in PROJECT_MAP:
        if any(p in cwd_lower for p in patterns):
            return project
    return None


def read_truncated(path: Path, max_chars: int = 2000) -> str:
    try:
        content = path.read_text(encoding="utf-8")
        if len(content) > max_chars:
            content = content[:max_chars] + f"\n\n... [truncado — {len(content)} chars total]"
        return content
    except Exception:
        return ""


def build_context(cwd: str) -> str:
    if not VAULT or not VAULT.exists():
        return ""

    parts = []

    wiki_index = VAULT / "wiki" / "index.md"
    if wiki_index.exists():
        content = read_truncated(wiki_index, 1500)
        if content:
            parts.append(f"## Obsidian Wiki Index\n{content}")

    project = detect_project(cwd)
    if project:
        project_dir = VAULT / "projects" / project
        index_path = project_dir / "INDEX.md"
        if index_path.exists():
            content = read_truncated(index_path, 3000)
            if content:
                parts.append(f"## Projeto: {project}\n{content}")
        elif project_dir.exists():
            items = [p.name for p in sorted(project_dir.iterdir()) if not p.name.startswith(".")]
            parts.append(f"## Projeto: {project}\nArquivos: {', '.join(items)}")

    if not parts:
        return ""

    header = (
        "=== OBSIDIAN CODE BRAIN (contexto automático) ===\n"
        f"Vault: {VAULT}\n"
        f"CWD: {cwd}\n"
        f"Projeto: {detect_project(cwd) or 'não mapeado'}\n\n"
    )
    full_context = header + "\n\n".join(parts)
    if len(full_context) > MAX_CHARS:
        full_context = full_context[:MAX_CHARS] + "\n... [truncado]"
    return full_context


def main():
    try:
        payload = json.loads(sys.stdin.read())
    except Exception:
        payload = {}
    cwd = payload.get("cwd") or os.environ.get("CLAUDE_CWD") or os.getcwd()
    context = build_context(cwd)
    print(json.dumps({"additionalContext": context} if context else {}))


if __name__ == "__main__":
    main()
