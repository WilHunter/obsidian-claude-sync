---
name: obsidian-sync
description: Sincroniza a sessão do Claude Code com o Obsidian vault e usa o vault como contexto primário. Invoque com /obsidian-sync.
---

# Obsidian Code Brain — Contexto e Sincronização

**Vault:** `/Users/wilsonvitoriano/Desktop/Code_Brain_Obs/Code Brain/`

O Obsidian é a fonte primária de verdade para projetos e documentação. Em toda sessão:
1. Leia o índice do vault para se orientar
2. Leia as notas do projeto atual
3. Escreva um resumo de sessão ao finalizar

---

## Mapeamento de projetos

| Diretório de trabalho | Pasta no vault |
|---|---|
| `*atheva*`, `*data-engineer*`, `*dw_project*`, `*adm2-web*` | `projects/atheva/` |
| `*datapay*` | `projects/datapay/` |
| `*spec*ia*`, `*spec-ia*` | `projects/spec_ia/` |
| `*vanvalu*` | `projects/vanvalu/` |
| `*app-resposavel*`, `*app-responsavel*` | `projects/atheva/` |

---

## Ao iniciar a sessão

```bash
VAULT="/Users/wilsonvitoriano/Desktop/Code_Brain_Obs/Code Brain"

# 1. Leia o índice geral da wiki
cat "$VAULT/wiki/index.md"

# 2. Identifique o projeto pelo CWD e leia o INDEX
cat "$VAULT/projects/<projeto>/INDEX.md" 2>/dev/null || \
  ls "$VAULT/projects/<projeto>/" 2>/dev/null
```

---

## Ao finalizar a sessão

Antes de encerrar, crie uma nota de sessão no vault:

```bash
VAULT="/Users/wilsonvitoriano/Desktop/Code_Brain_Obs/Code Brain"
PROJECT="<projeto>"         # ex: atheva, datapay, spec_ia, vanvalu
DATE="$(date +%Y-%m-%d)"
SLUG="<topico-kebab-case>"  # ex: fix-etl-pipeline

mkdir -p "$VAULT/projects/$PROJECT/sessions"

cat > "$VAULT/projects/$PROJECT/sessions/${DATE}-${SLUG}.md" << 'ENDNOTE'
---
title: Session - <Tópico>
type: session
date: <DATA>
project: <projeto>
tags: [session, <projeto>]
---

## Objetivo
<O que foi trabalhado>

## Decisões tomadas
- 

## Mudanças realizadas
- 

## Pendências
- 

## Arquivos modificados
- 

ENDNOTE
```

Depois, append no log:
```bash
echo "
## [$(date +%Y-%m-%d)] session | $SLUG
- Projeto: $PROJECT
- Resumo: <breve descrição>" >> "$VAULT/wiki/log.md"
```

---

## Atualizar documentação existente

Se você criou, refatorou ou descobriu algo relevante sobre o projeto:

```bash
VAULT="/Users/wilsonvitoriano/Desktop/Code_Brain_Obs/Code Brain"

# Atualize o INDEX.md do projeto
# Atualize notas de entidades/conceitos relevantes
# Mantenha o frontmatter (updated: YYYY-MM-DD)
```

---

## Buscar contexto específico

```bash
VAULT="/Users/wilsonvitoriano/Desktop/Code_Brain_Obs/Code Brain"

# Busca por conteúdo
grep -rli "keyword" "$VAULT/projects/" --include="*.md"

# Leia uma nota específica
cat "$VAULT/projects/<projeto>/<subpasta>/<nota>.md"
```

---

## Regras

- Sempre use wikilinks `[[Nome da Nota]]` ao referenciar outras notas
- Mantenha frontmatter com `updated: YYYY-MM-DD` em toda nota editada
- Nunca modifique arquivos em `raw/` — são documentos fonte imutáveis
- Ao criar uma nova nota, adicione entrada em `wiki/index.md` ou no `INDEX.md` do projeto
- Resumos de sessão são a memória de longo prazo do projeto — seja específico
