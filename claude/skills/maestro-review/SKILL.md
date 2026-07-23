---
name: maestro-review
description: "🔍 Olhar externo do MAESTRO em quatro modos — --codigo (review adversarial de código em contexto limpo), --estrategia (crítica implacável de decisões, gera CRITICA.md), --processo (auditoria de conformidade contra os 12 gates), --framework (meta-review do próprio MAESTRO cross-projeto). Carregue ao revisar código antes de PR/deploy, ao pedir crítica de uma decisão ou pré-apresentação, ao auditar se o workflow foi seguido, ou ao avaliar a saúde do framework."
---

# 🔍 maestro-review — Olhar externo em 4 modos

Consolida reviewer + crítico + auditor + meta-review. Escolha o modo pela pergunta que o Produtor está fazendo:

- Sobre a **qualidade do código** → `--codigo`
- Sobre as **decisões e a estratégia** → `--estrategia`
- Sobre a **conformidade do processo** → `--processo`
- Sobre o **próprio MAESTRO** → `--framework`

Sem argumento: infira pelo pedido; na dúvida, pergunte qual dos quatro.

---

## `--codigo` — Review adversarial de código

Revisão de código em **contexto limpo**, sem o viés de quem implementou. Acionado automaticamente em L3+ (Gate 10) e antes de qualquer PR/deploy.

**Como executar:**
1. Prefira delegar ao **`/code-review`** nativo do Claude Code quando o alvo é o diff atual — é o caminho mais direto e já roda em processo separado.
2. Para review mais profundo ou com rubric de domínio, lance um **subagente** (Task/Agent) com contexto limpo, passando apenas:
   - lista de arquivos modificados (paths);
   - o plano original (`PLAN.md`/`SPEC.md` da fase), se existir;
   - a rubric do domínio, se existir;
   - `DESIGN.md`, se envolver UI.
3. **Não** passe ao subagente o histórico da conversa nem as justificativas do implementador — o valor está na ausência de viés. Injete no prompt dele as HARD RULES 1-3 do CLAUDE.md.

**O que procurar:** correção (bugs, edge cases, race conditions), segurança, aderência ao plano, testes de verdade (não gaming), regressão vs baseline, legibilidade e reuso.

**Saída — Verdict objetivo:**
```
VERDICT: CLEAN | ISSUES
- [severidade] arquivo:linha — problema — correção sugerida
Build: PASS/FAIL · Testes: X/X · Regressão: nenhuma/N
```
Se `ISSUES` com severidade alta → volta ao Ato 3 para corrigir antes de seguir.

---

## `--estrategia` — Crítica implacável

Questiona **decisões**, não código. Olhar 100% externo, sem compromisso com o resultado nem com o esforço investido. Útil pré-apresentação ("o que um investidor diria?"), antes de mostrar ao cliente, ou quando o Produtor quer verdades inconvenientes.

**Regra de ouro:** o Crítico **não sugere soluções** — aponta problemas, lacunas e perguntas incômodas. Quem decide o que fazer é o Produtor (com o Co-Produtor).

**O que fazer:**
1. Questione **por que** cada decisão foi tomada e o que ela pressupõe.
2. Aponte **o que não foi considerado** e alternativas não exploradas.
3. Encontre lacunas conceituais e técnicas; onde isso quebra; quem usa e odeia.
4. Debata consigo mesmo (argumento × contra-argumento) para não ser injusto por preguiça.
5. Classifique cada crítica por **impacto se ignorada** (alto/médio/baixo).

**Saída — `CRITICA-YYYY-MM-DD.md`** na raiz ou em `.planning/`, com: pontos por impacto, perguntas estratégicas abertas, e o que NÃO foi analisado. O relatório é insumo para decisão — não é uma lista de tarefas.

---

## `--processo` — Auditoria de conformidade

Verifica se **o workflow foi seguido** neste projeto: os 5 Atos, a disciplina TDD e os 12 Quality Gates (lista canônica no CLAUDE.md). Acionado ao fim do Ato 3/Ato 5 ou quando o Produtor pergunta "como estamos indo?" / "o fluxo está sendo pulado?".

**Coleta de evidências (fonte primária = fatos, não memória):**
1. Artefatos de estado: `.planning/STATE.md`, `HANDOFF.md`, `SPEC.md`/`PLAN.md` das fases ativas.
2. **`.planning/EVENT-LOG.md`** (gerado pelo hook flight-recorder) — sequência real de Write/Edit/Bash. É aqui que se prova se teste veio antes do código (Gate 3) e se build+test rodaram (Gate 9).
3. `DESIGN.md` e conformidade visual, se houver UI.
4. Registros de bypass (todo bypass legítimo deve estar no EVENT-LOG).

**Checagem contra os 12 gates:** para cada gate, marque `PASS` / `FAIL` / `N/A` com a evidência (path:linha ou entrada do EVENT-LOG). Dê atenção a: Gate 3 (TDD — funções sem RED→GREEN no log foram feitas sem teste), Gate 9 (verificação real), Gate 10 (review em contexto limpo), Gate 12 (compliance quando há dados pessoais).

**Saída — relatório em `.planning/audits/AUDIT-YYYY-MM-DD.md`:** conformidade por gate, gates pulados e por quê, e um backlog curto de correções priorizadas.

---

## `--framework` — Meta-review do MAESTRO

Audita **o próprio MAESTRO**, não um projeto: adoção real, se o ciclo dos 5 Atos se completa, saúde da camada de aprendizado (wisdom/), e retorno do investimento em evolução. Cross-projeto. Cadência sugerida: quinzenal (junto do dream) ou sob demanda ("o framework está ajudando?").

**O que medir:**
1. **Varredura cross-projeto:** procure em `sua pasta de projetos` por evidências de uso (`.planning/`, EVENT-LOG, HANDOFF, audits).
2. **Adoção:** quais skills são realmente usadas vs nunca acionadas; quais gates são cumpridos vs ignorados na prática.
3. **Completude do ciclo:** algum projeto chega ao Ato 5? Handoffs e dreams acontecem, ou os loops estão mortos?
4. **Saúde do aprendizado:** `wisdom/inbox.md` está sendo curado? Padrões repetidos 3x viraram skill/regra (Gate 11)?
5. **Divergência doc × realidade:** o que a documentação afirma vs o que os artefatos comprovam.

**Saída — `META-REVIEW-YYYY-MM-DD.md`:** scorecard (adoção, completude, aprendizado), achados com evidência, e um plano de ação priorizado para a próxima iteração do framework.

---

## Notas comuns aos quatro modos
- Rode em contexto limpo sempre que possível (subagente) — o valor do olhar externo é a ausência de viés.
- Cite evidência concreta (path:linha, entrada do EVENT-LOG) em cada achado; nada de impressão vaga.
- Não conserte enquanto revisa — separe diagnóstico de correção. `--codigo` pode propor a correção; `--estrategia` nunca.
- Escale ao Produtor apenas o que muda uma decisão.
