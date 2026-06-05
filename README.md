# obsidian-claude-sync

Integração entre **Claude Code** e **Obsidian** — injeta o vault como contexto primário em cada sessão e persiste resumos de sessão como notas.

## O que faz

| Componente | Função |
|---|---|
| Hook `UserPromptSubmit` | Injeta contexto do vault em **todo** prompt automaticamente |
| Hook `Stop` | Registra marcador de sessão no `wiki/log.md` ao encerrar |
| Skill `/obsidian-sync` | Instruções para o Claude ler/escrever notas e criar resumos de sessão |

## Pré-requisitos

- [Claude Code](https://claude.ai/code) instalado
- Python 3.8+
- Obsidian com um vault criado

## Instalação (cada dev roda uma vez)

```bash
git clone https://github.com/WilHunter/obsidian-claude-sync.git
cd obsidian-claude-sync
bash install.sh
```

O instalador vai:
1. Perguntar o caminho do vault Obsidian
2. Copiar os scripts para `~/.claude/scripts/`
3. Copiar a skill para `~/.claude/skills/`
4. Adicionar os hooks em `~/.claude/settings.json` (sem sobrescrever configs existentes)
5. Testar a conexão com o vault

Depois, **reinicie o Claude Code**.

## Configurar o vault path manualmente

Edite `~/.claude/obsidian.env`:

```
OBSIDIAN_VAULT_PATH="/caminho/para/seu/vault"
```

Ou exporte a variável de ambiente antes de abrir o Claude Code:

```bash
export OBSIDIAN_VAULT_PATH="/caminho/para/seu/vault"
```

## Estrutura esperada do vault

O vault deve ter esta estrutura para o contexto funcionar melhor:

```
vault/
├── projects/
│   ├── atheva/
│   │   └── INDEX.md      ← lido automaticamente quando CWD contém "atheva"
│   ├── datapay/
│   │   └── INDEX.md
│   └── ...
├── wiki/
│   ├── index.md          ← sempre injetado como contexto base
│   └── log.md            ← log de sessões
└── raw/                  ← documentos fonte (não modificados)
```

## Mapeamento CWD → projeto

O script detecta o projeto pelo diretório de trabalho atual:

| Substring no CWD | Projeto no vault |
|---|---|
| `atheva`, `adm2-web`, `data-engineer`, `dw_project`, `app-resposavel` | `projects/atheva/` |
| `datapay` | `projects/datapay/` |
| `spec_ia`, `spec-ia` | `projects/spec_ia/` |
| `vanvalu` | `projects/vanvalu/` |

Para adicionar projetos, edite `PROJECT_MAP` em `~/.claude/scripts/obsidian-context.py`.

## Uso diário

```
/obsidian-sync
```

Invoque ao final de cada sessão para o Claude:
- Criar uma nota de resumo em `projects/<projeto>/sessions/YYYY-MM-DD-<topico>.md`
- Atualizar documentações relevantes
- Append no `wiki/log.md`

## Atualização

Para atualizar os scripts sem mudar a configuração do vault:

```bash
git pull
bash install.sh   # detecta vault já configurado, não pergunta novamente
```
