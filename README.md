<div align="center">

# 🎼 MAESTRO

**Um sistema de trabalho para o Claude Code — não mais um pacote de prompts.**

Regência de projetos com disciplina: esforço calibrado, TDD inegociável, memória curada e verificação real antes de qualquer "pronto".

`versão 4.0-cc.1` · Windows · macOS · Linux · [Instalação](#instalação-2-minutos) · [Como funciona](#o-que-você-ganha) · [Desinstalar](#desinstalar-100-reversível)

</div>

---

## O problema

Assistentes de código são excelentes executores e péssimos gerentes de si mesmos. Sem um sistema, eles: dizem "pronto" sem rodar o build, escrevem teste depois do código (quando escrevem), esquecem tudo entre sessões, usam canhão para matar formiga — e usam o modelo mais caro para responder "que horas são".

Nenhum desses problemas se resolve com um prompt melhor. Resolvem-se com **um sistema de trabalho**: níveis de esforço, portões de qualidade, memória com critério de admissão e enforcement executável.

## A ideia

O MAESTRO trata o desenvolvimento como uma orquestra: **você é o Produtor** — encomenda o espetáculo e tem o veto final. A IA é o **MAESTRO** — rege a execução com autonomia técnica, dentro de regras que ela não pode dobrar sozinha.

| Peça | O que faz |
|---|---|
| **Effort Router (L1–L5)** | Classifica todo pedido antes de agir. Typo não ganha plano de 5 fases; migração de arquitetura não é resolvida no improviso. |
| **Roteador de Modelos** | Recomenda *qual modelo* toca cada movimento e **te avisa quando você está pagando caro à toa**. Modelo premium só entra com briefing pronto e com registro de custo × entrega. |
| **5 Atos** | Visão → Partitura → Ensaio → Show → Aplauso. O ciclo de vida de qualquer entrega, do rascunho ao aprendizado. |
| **12 Quality Gates** | Portões explícitos entre spec, plano, código, review e deploy. Cada bypass é **anunciado e registrado** — nunca silencioso. |
| **Lei de Ferro do TDD** | Nenhum código de produção sem um teste falhando primeiro. Bug fix começa pelo teste que reproduz o bug. |
| **Memória com Gate de Admissão** | 4 testes (Dano, Pessoa, Recorrência, Ação) antes de gravar qualquer aprendizado. Contexto não-curado degrada mais do que economiza. |
| **Cortina (fim de sessão)** | Handoff + estado + insights gravados antes de encerrar. A próxima sessão começa sabendo onde a anterior parou. |
| **3 hooks executáveis** | Flight recorder, guarda de TDD e cobrança da Cortina — disciplina que roda como código, não como boa vontade. |
| **9 skills** | `maestro` (roteador) · `-tdd` · `-review` · `-debug` · `-design` · `-copro` · `-dream` · `-compliance` · `-onboard` |

> **A regra que sustenta tudo:** *nunca minta sobre status.* Teste falhou = reportar falha. Passo pulado = dizer que pulou. Um sistema de trabalho que aceita relatório bonito vira teatro em duas semanas.

## O que você ganha

Depois de instalado, toda sessão do Claude Code passa a:

- abrir lendo o estado do projeto (`.planning/FLOW.md` → `HANDOFF.md` → `STATE.md`) em vez de começar do zero;
- classificar o pedido e **dizer em uma linha** o nível de esforço, o Ato e o modelo em uso;
- rodar build e testes **de verdade** antes de dizer que terminou;
- registrar cada Write/Edit/Bash num flight recorder append-only (`.planning/EVENT-LOG.md`), que é a régua da auditoria de processo;
- cobrar o handoff antes de encerrar;
- acumular aprendizados **curados** — não um despejo automático de tudo que aconteceu.

## Instalação (2 minutos)

**Pré-requisitos:** [Claude Code](https://claude.com/claude-code) e [Node.js](https://nodejs.org) (só os hooks dependem dele).

```powershell
git clone https://github.com/Cristiano-Belever/maestro.git
cd maestro
.\install.ps1 -Produtor "Seu Nome, o que você faz"
```

Isso instala, **globalmente** (`~/.claude/`): as 9 skills, o `CLAUDE.md` com as regras e o `GATES.md`. Reabra o Claude Code e o MAESTRO está regendo.

Para preparar **um projeto** (hooks + `.planning/`):

```powershell
.\install.ps1 -Projeto C:\caminho\do\projeto
```

Quer experimentar sem tocar em nada fora de uma pasta? Modo teste:

```powershell
.\install.ps1 -Projeto C:\projeto\cobaia -SomenteProjeto
```

Ver o que aconteceria, sem escrever nada: `.\install.ps1 -DryRun`

### Primeira sessão — personalize

O MAESTRO genérico é bom. O MAESTRO **seu** é outro patamar. Na primeira sessão, peça:

> *"MAESTRO, me entreviste em 5 perguntas e reescreva a seção 'Como o Produtor trabalha' do meu `~/.claude/CLAUDE.md`."*

É essa seção que faz a diferença entre um assistente educado e um que trabalha do seu jeito.

### Em cada projeto novo

```
/maestro-onboard --novo
```

## Rotinas semanais (opcional, mas é onde o sistema fica vivo)

```powershell
.\rotinas\agendar.ps1 -Projeto C:\caminho\do\projeto
```

| Rotina | Quando | O que faz |
|---|---|---|
| `maestro-scout-github` | segunda, 09:00 | Varre o **GitHub** (releases do Claude Code, kits e frameworks de agentes, tema rotativo da stack), compara com o que o MAESTRO já faz e grava no máximo **3 propostas acionáveis** em `.planning/scout/GITHUB-{data}.md` + linhas no `BACKLOG.md`. **Só propõe** — não altera skill, hook nem regra. |
| `maestro-dream-semanal` | sexta, 17:00 | Cura o inbox de aprendizados pelo Gate de Admissão e promove padrões repetidos 3× a candidatos a skill. |

Ambas rodam headless (`claude -p`) via Agendador de Tarefas do Windows, com `-StartWhenAvailable`: **se o computador estiver desligado na hora marcada, roda assim que ligar.**

Conferir: `.\rotinas\agendar.ps1 -Listar` · Remover: `.\rotinas\agendar.ps1 -Remover`

## Atualizar

```powershell
.\update.ps1
```

`git pull` + reinstalação idempotente. Skills são substituídas; `CLAUDE.md` e `GATES.md` ganham backup automático em `~/.claude/.maestro/backup-*`; seu `.planning/` nunca é tocado.

## Desinstalar (100% reversível)

```powershell
.\uninstall.ps1          # simula: lista tudo que seria removido
.\uninstall.ps1 -Sim     # remove de fato
```

O MAESTRO é só arquivo — sem serviço, sem registro do Windows, sem telemetria. O desinstalador remove **apenas o que o instalador colocou**: sua configuração pessoal no `settings.json`, um `CLAUDE.md` que não seja do MAESTRO e o histórico em `.planning/` continuam intactos.

## Estrutura do repositório

```
maestro/
├─ install.ps1          instalador idempotente (global | projeto | dry-run)
├─ uninstall.ps1        desinstalador (simula por padrão; -Sim executa)
├─ update.ps1           git pull + reinstalação
├─ claude/
│  ├─ CLAUDE.md         as regras (vai para ~/.claude/CLAUDE.md)
│  ├─ GATES.md          os 12 quality gates em detalhe — fonte canônica
│  ├─ settings-template.json
│  ├─ hooks/            flight-recorder · tdd-guard · cortina (Node puro)
│  └─ skills/           as 9 skills maestro-*
├─ rotinas/             scout-github · dream-semanal · agendar.ps1
├─ tests/smoke.ps1      instala → verifica → desinstala, em sandbox
└─ INSTALL.md           guia detalhado, passo a passo
```

## Verificação

O kit tem teste próprio. Antes de confiar nele na sua máquina:

```powershell
.\tests\smoke.ps1
```

24 checagens em sandbox temporário (`%TEMP%`): instala, valida skills/hooks/JSON, executa um hook de verdade, confere idempotência, desinstala e verifica que **nada seu** foi levado junto. Não toca no seu `~/.claude` nem em nenhum projeto real.

## O que o MAESTRO **não** é

- **Não é um agente autônomo.** Ele propõe; você decide. As rotinas agendadas nunca alteram o framework sozinhas.
- **Não é captura automática de memória.** Contexto não-curado degrada mais do que economiza — por isso existe o Gate de Admissão.
- **Não coleta nada.** Nenhuma telemetria, nenhuma chamada externa própria. Tudo é markdown na sua máquina.
- **Não traz tudo que o autor usa.** Uma skill do uso interno da Belever (pipeline de reuniões, propostas comerciais e perfis de pessoas) fica fora do kit público por conter método de negócio e dados de cliente. O núcleo do sistema de trabalho está todo aqui.
- **Não é magia.** É disciplina escrita de forma que a IA consiga seguir — e que você consiga auditar quando ela não seguir.

## Compatibilidade

Escrito e verificado no **Windows 11 + PowerShell 5.1**. Os hooks são Node puro (`.cjs`) e funcionam igual em macOS e Linux; os instaladores `.ps1` rodam em PowerShell 7 nessas plataformas — a instalação equivalente em bash está no roadmap. Contribuições são bem-vindas.

## Créditos e licença

Framework autoral de **Cristiano Pospichil** ([Belever](https://belever.com.br)) — destilado de uso diário real, não de teoria. Nasceu para uma operação onde quem rege o projeto é designer de formação, não programador: por isso a disciplina vale mais que o virtuosismo.

Licença [MIT](LICENSE) — use, adapte, incorpore. Se ele te ajudar, uma estrela no repo ou um crédito é suficiente.
