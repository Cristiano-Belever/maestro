# 🚦 GATES.md — Os 12 Quality Gates do MAESTRO (lista canônica única)

> **Autoridade:** este arquivo é a **única fonte canônica** dos Quality Gates do MAESTRO,
> válida para **ambas as plataformas** (Claude Code e Antigravity). Onde qualquer outro
> documento divergir da numeração, do nome ou da regra de um gate, **GATES.md vence**.
>
> **Contexto:** a auditoria (ANALISE-FABLE §1) constatou que não existia lista canônica —
> o `MAESTRO.md` numerava 1–7, tratava 9/10/11 só em prosa, colocava o 12 em seção própria
> e **não tinha Gate 8**. Este arquivo resolve isso. O `MAESTRO.md` do Antigravity **não é
> editado aqui**; ele será alinhado a este GATES.md na próxima revisão (item **P2.4**).
>
> **Registro de bypass:** todo gate pulado é anunciado ao Produtor e registrado em
> `.planning/EVENT-LOG.md` (HARD RULE 2), no formato:
> `[<ISO-timestamp>] [GATE] Gate N: SKIP (<motivo>) | nível: <L> | produtor: <confirmou>`.
> No Claude Code o EVENT-LOG é alimentado pelo hook `flight-recorder.cjs`; no Antigravity,
> por escrita direta da skill/instrução.

## Tabela-resumo

| # | Gate | Dispara em | Claude Code | Antigravity |
|---|------|-----------|-------------|-------------|
| 1 | Spec → Plan | L4+ | Instrução + plan mode | Instrução (orquestrador) |
| 2 | Plan → Code | L3+ | Instrução + plan mode (aprovação) | Instrução |
| 3 | Test → Code (TDD) | Todo código de produção | Hook `PreToolUse` (aviso) + skill `maestro-tdd` | Instrução + skill `maestro-tdd` |
| 4 | Review → Deploy | Antes de produção | `/code-review` + subagente | Skill reviewer + instrução |
| 5 | Learn → Ship | Marco concluído | Skill `maestro-dream` + cron semanal | Skill dream / extract-learnings |
| 6 | Self-Check | Antes de "done" | Instrução (UCV) | Instrução |
| 7 | Handoff | Fim de sessão de trabalho | Hook `Stop` (`cortina.cjs`) | Skill `maestro-cortina` |
| 8 | Auto-Learn | Fim de sessão | Hook `Stop` (cobra inbox) + dream cura | Skill `maestro-cortina` |
| 9 | Verificação real | Após qualquer código | HARD RULE 1 + EVENT-LOG (hook) | Instrução (Protocolo V1-V2) |
| 10 | Fresh-Context Review | L3+ | Subagente (contexto limpo) | Subagente reviewer |
| 11 | Cristalização | Padrão repetido 3× | `counters.json` + dream (promoção) | Instrução / dream |
| 12 | Compliance & Anti-Regressão | Dados pessoais / refactor grande | Skill `maestro-compliance` + baseline | Skill `maestro-compliance` |

---

## Gate 1 — Spec → Plan
- **Regra:** em tarefas **L4+**, não se abre um plano sem um objetivo/spec aprovado pelo Produtor. Para L5 (arquitetura, novo projeto, dados de cliente), a spec é formal (`SPEC.md`).
- **Trigger:** classificação L4 ou L5 no Effort Router.
- **Claude Code:** instrução do roteador; o **plan mode** nativo estrutura a spec antes de planejar.
- **Antigravity:** instrução do orquestrador `maestro/SKILL.md` (Ato 1 → SPEC.md).
- **Exceções:** L1–L3 não exigem spec formal (bypass implícito, sem registro). Pular a spec numa tarefa L4+ exige registro no EVENT-LOG e aval do Produtor.

## Gate 2 — Plan → Code
- **Regra:** em tarefas **L3+**, não se escreve código sem um plano aceito pelo Produtor.
- **Trigger:** classificação L3, L4 ou L5.
- **Claude Code:** instrução; o plan mode exige aprovação explícita (ExitPlanMode) antes de codar.
- **Antigravity:** instrução do orquestrador (Ato 2 → PLAN.md aprovado).
- **Exceções:** L1–L2 (trivial/simples) executam direto — bypass implícito. Pular o plano numa tarefa L3+ é registrado e confirmado.

## Gate 3 — Test → Code (Lei de Ferro do TDD)
- **Regra:** nenhum código de produção sem um teste falhando primeiro. Ciclo RED → GREEN → REFACTOR → COMMIT. Bug fix começa com teste que reproduz o bug. Testes são imutáveis durante a implementação.
- **Trigger:** qualquer Write/Edit em código de produção (raízes `src/`, `app/`, `pages/`, `lib/`, `components/`, `server/`).
- **Claude Code:** hook `PreToolUse` `tdd-guard.cjs` em **modo aviso** (lembra o Gate 3 quando se edita produção sem teste tocado na sessão; nunca bloqueia) + skill `maestro-tdd` + Gate 0 pré-voo (framework de testes existe?).
- **Antigravity:** instrução (Lei de Ferro no orquestrador) + skill `maestro-tdd`.
- **Exceções legítimas:** spike descartável declarado, config pura (`.env`, `config.json`), código gerado, markdown/conteúdo estático. **Registro:** `[GATE] Gate 3: SKIP (spike|config|gerado) | produtor: confirmou` no EVENT-LOG; spike tem validade curta (alertar na próxima sessão se não virar código testado).

## Gate 4 — Review → Deploy
- **Regra:** nada vai para produção sem passar por review. Complementa o Gate 10 (o Gate 10 é o *como*: contexto limpo; o Gate 4 é o *quando*: antes de entregar).
- **Trigger:** qualquer deploy/PR/entrega (Ato 4).
- **Claude Code:** `/code-review` nativo e/ou subagente `maestro-review --codigo`; instrução de não ofertar deploy sem review + build/test reportados.
- **Antigravity:** skill `maestro-reviewer`/`gsd-code-review` + instrução.
- **Exceções:** L2 (1–2 arquivos, sem decisão de design) pode dispensar review formal (`--no-review`, registrado). **L3+ é obrigatório — não há bypass.**

## Gate 5 — Learn → Ship
- **Regra:** ao concluir um marco, extrair os aprendizados antes de seguir (Ato 5 — Aplauso). Nunca pular: é 1 minuto.
- **Trigger:** conclusão de marco/fase.
- **Claude Code:** skill `maestro-dream` (curadoria) + rotina agendada semanal (`maestro-dream-semanal`).
- **Antigravity:** skill `maestro-dream` / `gsd-extract-learnings` + `gsd-complete-milestone`.
- **Exceções:** marco sem aprendizado real → registrar "nenhum insight" (não é bypass, é resultado). O funil de candidatos (`inbox.md`) é append livre; o Gate de Admissão só roda na curadoria.

## Gate 6 — Self-Check
- **Regra:** antes de declarar "done", comparar pedido original vs entregue (tabela mental): todos os requisitos citados foram atendidos? Edge cases mencionados cobertos? Sem regressão?
- **Trigger:** imediatamente antes de reportar conclusão.
- **Claude Code:** instrução; loop UCV (Understand-Change-Verify) descrito em `maestro-tdd`.
- **Antigravity:** instrução (mesmo UCV).
- **Exceções:** nenhuma. Custa segundos; sempre se aplica.

## Gate 7 — Handoff
- **Regra:** ao encerrar uma sessão de trabalho, atualizar `.planning/HANDOFF.md` (o que foi feito, o que falta, próximo passo concreto, prompt de retomada) e fazer append do resultado no `STATE.md`.
- **Trigger:** fim de sessão que produziu trabalho (sinal do Produtor: "tchau"/"cortina"/"encerrar" — ou trabalho concluído).
- **Claude Code:** hook `Stop` `cortina.cjs` — se a sessão editou código e o HANDOFF tem >30min, bloqueia o encerramento cobrando a Cortina (anti-loop via `stop_hook_active`).
- **Antigravity:** skill `maestro-cortina` / instrução.
- **Exceções:** sessão só de conversa/investigação (sem edição de código) → protocolo **leve**, sem cobrança de HANDOFF (no Claude Code o hook nem dispara, pois não houve Write/Edit).

## Gate 8 — Auto-Learn  <sup>[†]</sup>
- **Regra:** ao fim de uma sessão, capturar **0–3 micro-insights** em `.planning/wisdom/inbox.md`. O Gate de Admissão **não** se aplica ao inbox (append livre); a curadoria (Gate 5/11) filtra depois.
- **Trigger:** fim de sessão de trabalho (junto do Gate 7).
- **Claude Code:** hook `Stop` `cortina.cjs` (a mesma cobrança do Gate 7 inclui os insights); a skill `maestro-dream` cura o inbox depois.
- **Antigravity:** skill `maestro-cortina` (passo Auto-Learn).
- **Exceções:** sessão sem nada a aprender → 0 insights é válido. Nunca forçar insight artificial.

## Gate 9 — Verificação real
- **Regra:** rodar build e testes **de verdade** após qualquer código, antes de declarar concluído. Falhou → corrigir (máx. 3 tentativas) → se persistir, reportar com o output real. Nunca dizer "pronto" sem verificar; nunca mentir sobre status (HARD RULE 1 e 2). **Se o build do projeto pula a validação de tipos** (ex.: `ignoreBuildErrors` no next.config), "build PASS" não vale como verificação — rodar o typecheck à parte (`tsc --noEmit`) e separar erros pré-existentes dos introduzidos (só os seus bloqueiam).
- **Trigger:** após qualquer alteração de código.
- **Claude Code:** HARD RULE 1 (instrução) + evidência no `.planning/EVENT-LOG.md` (hook `flight-recorder.cjs` registra os Bash de build/test) — auditável pelo `maestro-review --processo`.
- **Antigravity:** instrução (Protocolo de Verificação Pós-Execução V1-V2) / `gsd-verify-work`.
- **Exceções:** só quando **nenhum** código foi tocado (doc/markdown puro) → registrar `build: N/A | tests: N/A` no STATE.md. Ausência de framework de testes → Gate 0 do `maestro-tdd` decide (configurar / spike / dívida registrada).

## Gate 10 — Fresh-Context Review
- **Regra:** em **L3+**, o review é feito por um agente com **contexto limpo** — sem o histórico da implementação, sem as justificativas do implementador. Quem implementa não é o único a revisar.
- **Trigger:** conclusão de implementação L3, L4 ou L5.
- **Claude Code:** subagente (Task/Agent) em contexto limpo, ou `maestro-review --codigo`; recebe só arquivos+plano+rubric (nunca a conversa).
- **Antigravity:** skill `maestro-reviewer` como subagente.
- **Exceções:** L1–L2 dispensam (bypass implícito). Em L3+ é obrigatório; `--no-review` é proibido nesse nível.

## Gate 11 — Cristalização
- **Regra:** um padrão que se repete **3×** deve ser promovido — vira skill/regra nova proposta ao Produtor. "Ninguém conta ocorrências" era o gap; agora há contador.
- **Trigger:** terceira ocorrência de um mesmo padrão.
- **Claude Code:** `.planning/wisdom/counters.json` (contador por slug) mantido pela skill `maestro-dream`; ao atingir `count ≥ 3`, marca ✅ no `playbook.md` e grava proposta em `.planning/wisdom/skill-proposals/PROP-{data}-{slug}.md`.
- **Antigravity:** instrução / dream (mesma lógica, sem contador automatizado até o alinhamento P2.4).
- **Exceções:** a promoção **propõe** a cristalização; criar a skill exige aval do Produtor (não é automático).

## Gate 12 — Compliance & Anti-Regressão
- **Regra:** feature que toca **dados pessoais** ativa a verificação LGPD (minimização, consentimento, direitos do titular, Privacy by Design) — norma no `COMPLIANCE-RULES.md`. Antes de refactor grande, capturar **baseline de testes** para detectar regressão.
- **Trigger:** qualquer código que trate dados pessoais; qualquer refactor de grande superfície.
- **Claude Code:** skill `maestro-compliance` (4 scans + verificação do EVENT-LOG como flight recorder) + baseline de testes antes do refactor.
- **Antigravity:** skill `maestro-compliance`.
- **Exceções:** projeto sem dado pessoal → a parte LGPD é **N/A** (registrar). Severidade por ambiente: em **MVP**, violações críticas geram **alerta forte** (não bloqueiam); em **produção**, **bloqueiam** o deploy.

---

<sup>[†]</sup> **Nota de rodapé — numeração histórica.** No `MAESTRO.md` (Antigravity) o Auto-Learn
era referido informalmente como **"Gate 7.5"** (um passo intercalado entre o Handoff e o
fim de sessão), e por isso **não existia um "Gate 8"** na numeração antiga. Nesta lista
canônica, o Auto-Learn passa a ser o **Gate 8** oficial. Mapeamento:

| Numeração histórica (MAESTRO.md) | Canônica (GATES.md) |
|---|---|
| Gate 7.5 — Auto-Learn | **Gate 8 — Auto-Learn** |
| (inexistente) | Gate 8 agora ocupado |
| Gates 9, 10, 11 (só em prosa) | Gates 9, 10, 11 (formalizados aqui) |
| Gate 12 (seção própria) | Gate 12 (integrado à lista) |

O `MAESTRO.md` será atualizado para refletir esta numeração no item **P2.4** (revisão do
Antigravity). Até lá, em caso de conflito, **GATES.md é a referência**.
