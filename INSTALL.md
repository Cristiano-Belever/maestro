# 🎼 Guia de instalação do MAESTRO

Guia completo, passo a passo. Se você só quer o caminho rápido, o [README](README.md) resolve em 3 comandos.

---

## 1. Antes de começar

| Requisito | Para quê | Como conferir |
|---|---|---|
| [Claude Code](https://claude.com/claude-code) | é o que o MAESTRO rege | `claude --version` |
| [Node.js](https://nodejs.org) | os 3 hooks rodam em Node puro | `node --version` |
| PowerShell | os instaladores são `.ps1` | já vem no Windows |

Sem Node você ainda tem skills, regras e gates — perde só o enforcement automático (flight recorder, guarda de TDD, cobrança da Cortina).

**Se o PowerShell bloquear scripts** (`ExecutionPolicy`), rode uma vez na sessão:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## 2. Baixar

**Com git** (recomendado — é o que permite `update.ps1` depois):

```powershell
git clone https://github.com/Cristiano-Belever/maestro.git
cd maestro
```

**Sem git:** baixe o ZIP em *Code → Download ZIP*, extraia, e abra o PowerShell na pasta extraída.

## 3. Escolher o modo de instalação

### Modo A — global (o normal)

O MAESTRO passa a valer em **todos** os seus projetos.

```powershell
.\install.ps1 -Produtor "Seu Nome, o que você faz"
```

Instala em `~/.claude/`: as 9 skills `maestro-*`, o `CLAUDE.md` e o `GATES.md`.

### Modo B — global + um projeto

Além do global, prepara um projeto com hooks e estado:

```powershell
.\install.ps1 -Produtor "Seu Nome" -Projeto C:\caminho\do\projeto
```

Acrescenta no projeto: `.claude/hooks/*.cjs`, o bloco `hooks` no `.claude/settings.json` (mesclado, sem apagar sua config) e um `.planning/` mínimo (`STATE.md`, `HANDOFF.md`, `BACKLOG.md`, `wisdom/inbox.md`).

### Modo C — só um projeto (modo cobaia)

Nada é escrito fora da pasta do projeto. Ideal para experimentar:

```powershell
.\install.ps1 -Projeto C:\projeto\cobaia -SomenteProjeto
```

Gostou? Rode o Modo A e apague o `.claude/skills` e o `CLAUDE.md` locais do projeto-cobaia. Não gostou? Apague `.claude/` e `.planning/` do projeto — fim, sem rastro.

> **Repo compartilhado com outra pessoa?** Adicione `.planning/` e `.claude/` ao `.git/info/exclude` (ignore local, não altera o repositório) e confirme com `git status` que nada do MAESTRO aparece.

### Opções úteis

| Flag | Efeito |
|---|---|
| `-DryRun` | mostra tudo que faria, sem escrever um byte |
| `-Force` | sobrescreve um `CLAUDE.md` que não seja do MAESTRO (sempre com backup) |
| `-Home <path>` | instala num "home" alternativo (usado pelos testes) |
| `-Silencioso` | sem saída no console |

## 4. Ativar

Feche e reabra o Claude Code — **hooks e skills são lidos no início da sessão**.

Confira que pegou: comece uma sessão num projeto e peça algo simples. A resposta deve abrir com a linha de contexto:

```
🎼 Ato 3 · L2 · TDD · Opus
```

E as skills devem aparecer como `/maestro`, `/maestro-tdd`, `/maestro-review`…

## 5. Personalizar (o passo que a maioria pula)

O `CLAUDE.md` instalado traz um perfil genérico. Na primeira sessão:

> *"MAESTRO, me entreviste em 5 perguntas e reescreva a seção 'Como o Produtor trabalha' do meu `~/.claude/CLAUDE.md`. Depois ajuste o Roteador de Modelos aos modelos do meu plano."*

Vale reservar 10 minutos: é o que transforma o framework genérico no **seu** sistema de trabalho.

## 6. Onboarding de cada projeto

Dentro do projeto, no Claude Code:

```
/maestro-onboard --novo
```

Cria o `.planning/` do projeto, um `CLAUDE.md` curto com a stack real e os comandos de build/test, e registra o projeto no seu radar.

## 7. Rotinas semanais (opcional)

```powershell
.\rotinas\agendar.ps1 -Projeto C:\caminho\do\projeto
```

Registra duas tarefas no Agendador do Windows:

- **`maestro-scout-github`** — segunda 09:00. Varre o GitHub e escreve no máximo 3 propostas de evolução em `.planning/scout/GITHUB-{data}.md`. **Só propõe.**
- **`maestro-dream-semanal`** — sexta 17:00. Cura a memória pelo Gate de Admissão.

Personalizar dia/hora: `-DiaScout Wednesday -HoraScout 08:30`. Só uma delas: `-Rotinas scout` ou `-Rotinas dream`.

Conferir: `.\rotinas\agendar.ps1 -Listar`
Testar agora, sem esperar a semana: `Start-ScheduledTask -TaskName maestro-scout-github`
Remover: `.\rotinas\agendar.ps1 -Remover`

> As rotinas usam `-StartWhenAvailable`: computador desligado na hora marcada → rodam assim que ele voltar.

## 8. Atualizar

```powershell
.\update.ps1
```

Faz `git pull` e reinstala. Idempotente: pode rodar quantas vezes quiser. Com `-Projeto <path>`, atualiza também os hooks daquele projeto.

## 9. Desinstalar

```powershell
.\uninstall.ps1        # simulação: lista o que seria removido
.\uninstall.ps1 -Sim   # remove de fato
```

Remove skills `maestro-*`, o `CLAUDE.md` do MAESTRO, o `GATES.md`, os hooks e o bloco `hooks` do `settings.json` de cada projeto registrado.

**Preserva:** sua configuração no `settings.json`, um `CLAUDE.md` que não seja do MAESTRO, todo o `.planning/` (histórico do projeto) e os backups em `~/.claude/.maestro/backup-*`.

Para apagar também o histórico: `-RemoverPlanning` (não recomendado).
Rotinas agendadas saem com: `.\rotinas\agendar.ps1 -Remover`

---

## Problemas comuns

**"não é possível carregar o arquivo ... install.ps1"**
Política de execução. Rode `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` e tente de novo.

**As skills não aparecem no Claude Code**
Elas são lidas na abertura da sessão — feche e reabra. Confira que existe `~/.claude/skills/maestro/SKILL.md`.

**Os hooks não registram nada em `.planning/EVENT-LOG.md`**
1. `node --version` funciona? 2. O projeto tem `.claude/hooks/flight-recorder.cjs`? 3. O `.claude/settings.json` tem o bloco `hooks`? 4. A sessão foi reaberta depois da instalação?
Teste manual (Git Bash, na raiz do projeto):
```bash
echo '{"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"src/x.ts"},"cwd":"'"$PWD"'"}' | node .claude/hooks/flight-recorder.cjs
```
Deve aparecer uma linha `[timestamp] [Write] src/x.ts` no `.planning/EVENT-LOG.md`.

**"settings.json do projeto é JSON inválido"**
O instalador se recusa a mexer num JSON quebrado — de propósito. Corrija o arquivo (ou renomeie) e rode de novo.

**Eu já tinha um `CLAUDE.md` global**
Ele **não** é sobrescrito: o instalador faz backup em `~/.claude/.maestro/backup-*` e avisa. Abra `claude/CLAUDE.md` do kit e cole as seções que quiser, ou rode com `-Force` para adotar o do MAESTRO (o backup continua lá).

**Quero conferir que o kit funciona antes de instalar de verdade**
```powershell
.\tests\smoke.ps1
```
Roda o ciclo completo em sandbox temporário, sem tocar no seu ambiente.
