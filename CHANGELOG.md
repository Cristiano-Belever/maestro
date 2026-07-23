# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/). Versão = a do adaptador Claude Code do MAESTRO.

## [4.0-cc.1] — 2026-07-23

Primeira publicação como kit instalável. Antes disso, o MAESTRO era instalado colando prompts à mão.

### Adicionado
- `install.ps1` — instalador idempotente com três modos (global, global+projeto, só projeto), `-DryRun`, backup automático e manifesto de instalação.
- `uninstall.ps1` — desinstalador que simula por padrão e remove **apenas** o que o instalador colocou.
- `update.ps1` — `git pull` + reinstalação.
- `rotinas/agendar.ps1` — registra as rotinas semanais no Agendador de Tarefas do Windows com `-StartWhenAvailable`.
- `rotinas/scout-github.cmd` — **rotina nova**: varredura semanal do GitHub (releases do Claude Code, kits e frameworks de agentes, tema rotativo da stack) que grava no máximo 3 propostas acionáveis e **nunca** altera o framework.
- `tests/smoke.ps1` — 24 checagens em sandbox: instala, executa um hook de verdade, confere idempotência, desinstala e verifica que nada do usuário foi levado junto.
- `INSTALL.md` com solução dos problemas comuns; `README.md` autoral; `LICENSE` (MIT).

### Alterado
- `rotinas/dream-semanal.cmd` agora recebe o caminho do projeto como argumento (antes era fixo numa máquina).
- `claude/CLAUDE.md` genérico: identidade parametrizada (`-Produtor`) e Roteador de Modelos por papel, em vez de nomes de modelo de um plano específico.

### Corrigido
- Os 3 hooks passaram a ignorar BOM no início do payload de stdin — sem isso, a verificação manual pelo PowerShell 5.1 falhava em silêncio (`JSON.parse` quebrava e o hook saía com 0 sem registrar nada).

### Núcleo (inalterado nesta versão)
Effort Router L1–L5, 5 Atos, 12 Quality Gates, Lei de Ferro do TDD, Personas, Co-Produtor, memória com Gate de Admissão, Cortina, 9 skills e 3 hooks. A skill de transcrições/propostas do uso interno da Belever não faz parte do kit público.
