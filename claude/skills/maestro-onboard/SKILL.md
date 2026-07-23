---
name: maestro-onboard
description: "🚪 Onboarding de projetos no MAESTRO (Claude Code) — dois modos: --novo (projeto do zero: .planning mínimo + CLAUDE.md específico + hooks + registro) e --migracao (transferir um projeto do Antigravity sem perda de contexto: entrega ao Produtor o prompt de encerramento para colar lá, depois absorve o .planning aqui). Carregue quando o Produtor pedir onboarding, instalar o MAESTRO num projeto, migrar/trazer um projeto do Antigravity, ou 'configura o MAESTRO aqui'."
---

# 🚪 maestro-onboard — Entrada de projetos no MAESTRO

O MAESTRO (CLAUDE.md + skills) já é global — onboarding NÃO instala o framework; instala o **corpo local** do projeto: estado (`.planning/`), enforcement (hooks) e contexto específico (CLAUDE.md curto). Sem modo explícito: se o Produtor mencionar Antigravity ou "projeto em andamento", assuma `--migracao`; senão pergunte em uma linha.

## MODO `--migracao` (Antigravity → Claude Code)

### Passo 1 — Entregar o prompt de encerramento (o Produtor cola no Antigravity)

Mostre este bloco literalmente e diga: *"Cole no Antigravity, no projeto a migrar. Quando terminar, volte aqui e diga 'continua a migração'."*

```
CORTINA DE MIGRAÇÃO — este projeto vai para o Claude Code; você (Antigravity) está
gerando o pacote de continuidade. Despeje TUDO que está na sua memória sobre este
projeto para .planning/, em markdown puro:

1. HANDOFF.md — estado atual completo: o que foi feito, o que está em andamento,
   o que falta, próximo passo concreto.
2. STATE.md — atualize com o resultado da última sessão (formato padrão).
3. BACKLOG.md — TODAS as pendências conhecidas numa tabela: | item | valor | esforço
   | origem |. Inclua as que estão só na sua memória.
4. codebase/MAP.md — mapa do código: áreas/módulos, arquivos-chave por área,
   padrões e convenções adotados, dívidas técnicas conhecidas, comandos de
   build/test/deploy.
5. memory/CONTEXTO-MIGRACAO.md — tudo que você sabe e NÃO está escrito em nenhum
   documento: decisões e seus porquês, preferências do cliente, armadilhas já
   descobertas, histórico de tentativas que falharam, contexto comercial.

Regras: NÃO invente nada; o que já estiver documentado, referencie em vez de
duplicar; o que você não souber, escreva "desconhecido". Ao final, liste os 5
arquivos gerados com o tamanho de cada um.
```

### Passo 2 — Absorver (quando o Produtor voltar com "continua a migração")
1. Leia `.planning/`: HANDOFF, STATE (resumo), BACKLOG, `codebase/MAP.md`, `memory/CONTEXTO-MIGRACAO.md`. **Não re-analise o codebase** — o MAP é a verdade herdada; só confira por amostragem (2-3 arquivos-chave existem? comandos de build batem com o package.json?).
2. Divergência entre MAP e realidade → corrija o MAP e avise em uma linha.

### Passo 2.5 — Estado mínimo garantido (SEMPRE — os dois modos)
Independentemente do que o Antigravity gerou, o corpo local só está completo com estes três
arquivos existindo (crie os que faltarem — nunca sobrescreva os que já existem):

- `.planning/wisdom/inbox.md` — depósito do Gate 8 (a Cortina cobra insights; sem ele não há onde depositar).
- `.planning/BACKLOG.md` — fila canônica valor×esforço (o roteador lê daqui na retomada).
- `.planning/FABLE-LEDGER.md` — registro de sessões Fable via API (custo×entrega).

```powershell
New-Item -ItemType Directory -Force -Path ".\.planning\wisdom" | Out-Null
if (-not (Test-Path ".\.planning\wisdom\inbox.md")) { Set-Content -LiteralPath ".\.planning\wisdom\inbox.md" -Encoding utf8 -Value "# WISDOM INBOX`n> Candidatos crus a aprendizado (Gate 8). Curados pelo maestro-dream.`n" }
if (-not (Test-Path ".\.planning\BACKLOG.md"))      { Set-Content -LiteralPath ".\.planning\BACKLOG.md"      -Encoding utf8 -Value "# 📋 BACKLOG`n> Fila canônica (valor × esforço). ``[OPORTUNIDADE]`` = descoberto, não solicitado.`n`n| Item | Valor | Esforço | Origem | Status |`n|---|---|---|---|---|`n" }
if (-not (Test-Path ".\.planning\FABLE-LEDGER.md")) { Set-Content -LiteralPath ".\.planning\FABLE-LEDGER.md" -Encoding utf8 -Value "# FABLE-LEDGER — registro de sessões Fable`n> Uma linha por sessão Fable: custo × entrega.`n`n| Data | O que foi pedido | Tamanho aprox | O que entregou | Valeu? |`n|---|---|---|---|---|`n" }
```

### Passo 3 — CLAUDE.md específico do projeto (curto — o MAESTRO já é global)
Crie na raiz do app (onde está o package.json). Se já existir CLAUDE.md, **mescle, nunca sobrescreva**. Modelo (~20 linhas):

```markdown
# {Projeto} — contexto do projeto
> O sistema de trabalho MAESTRO está instalado globalmente. Aqui só o específico.
## O que é — {1-2 linhas: produto, status produção/dev, cliente}
## Stack — {da realidade do package.json}
## Documentos — MANIFESTO/DESIGN/brand (paths reais) · .planning/ compartilhado
## Regras específicas — {LGPD se dados pessoais · framework de testes: existe? ·
   deploy: como · particularidades que mudam o Effort Router}
```

### Passo 4 — Hooks (enforcement local)
Copie de `a pasta `claude\` do kit do MAESTRO`: `hooks\*.cjs` → `.claude\hooks\`; registre os 3 hooks no `.claude\settings.json` (se existir, mescle o bloco `hooks` sem apagar nada — modelo em `settings-template.json`, removendo a chave `"//"`).

### Passo 5 — Registrar
Adicione a linha do projeto em `seu indice de projetos (ex.: `.planning\PROJETOS.md` na pasta raiz onde voce guarda os projetos), se voce mantiver um` (tabela: projeto, path, hooks ✅, data) — entra na auditoria mensal.

### Passo 6 — Conexões do fluxo de entrega (GitHub · Vercel · Supabase)
O fluxo padrão do Produtor: código → push GitHub → Vercel auto-deploya → dados no Supabase. A integração GitHub→Vercel vive NA PLATAFORMA Vercel — migração não a afeta; nada a "reconectar". O que se configura aqui são as ferramentas do agente (preferir CLI a MCP: mais confiável e mais barato em contexto). Verifique e guie item a item, pedindo ao Produtor só o que faltar:

1. **Git/GitHub:** `git remote -v` (remoto existe?) e `gh auth status`. Faltando: `winget install GitHub.cli` → `gh auth login` (login via navegador). O `gh` é o canal para PRs/issues; push já funciona com as credenciais git existentes.
2. **Vercel:** para o agente ver deploys/logs/env: `vercel` CLI (`npm i -g vercel` → `vercel login` → `vercel link` na pasta do app). Se faltarem variáveis locais: `vercel env pull .env.local`.
3. **Supabase:** confira se `.env.local` tem URL + keys (o app já roda?). Para o agente acessar o banco (queries, migrações, types): `supabase` CLI (`npm i -g supabase` → `supabase login` → `supabase link --project-ref <ref>`). MCP oficial do Supabase é alternativa se o Produtor preferir — pergunte antes de instalar MCP.
4. **Registrar** no CLAUDE.md do projeto uma seção `## Deploy & Conexões` (fluxo, CLIs conectadas, comandos de deploy/verificação).
5. **Smoke test do fluxo:** mudança trivial → commit → push → confirmar que a Vercel deployou → registrar no STATE.md. Só então a migração está COMPLETA.

**Guardrail:** segredos (keys, tokens) NUNCA entram em CLAUDE.md, `.planning/` ou EVENT-LOG — vivem só em `.env.local` e nos dashboards. Feature que toque dados pessoais no Supabase → Gate 12.

### Passo 7 — Relatório de chegada (máx. 10 linhas + tabela)
Resumo do projeto herdado, riscos/dívidas principais, e **as 3 tarefas mais valiosas do BACKLOG** com nível L e modelo recomendado. Termine perguntando por onde começar.

## MODO `--novo` (projeto do zero)
Passos 3-6 acima, mais: crie `.planning/` mínimo (`STATE.md`, `HANDOFF.md`) **e rode o Passo 2.5** (garante `wisdom/inbox.md`, `BACKLOG.md` e `FABLE-LEDGER.md`). Se o projeto tiver UI, ofereça `maestro-design` (Ato 1) antes do primeiro componente.

## Guardrails
- Nunca sobrescrever arquivo existente sem mesclar; `.planning/` herdado é sagrado — completar, não reestruturar.
- Onboarding termina em minutos, não horas: sem varredura profunda de codebase (isso é tarefa L3 separada, se o Produtor pedir).
- Ao final, Cortina normal (o hook cobra).
