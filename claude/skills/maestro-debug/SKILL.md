---
name: maestro-debug
description: "🔍 Pipeline de debug com qualidade do MAESTRO — reproduz o bug com teste (RED) → investiga sistematicamente (hipóteses, bissecção, logs) → fix mínimo (GREEN) → build+test → review (L3+) → registro no STATE.md. Autocontido, sem dependências externas. Carregue ao corrigir qualquer bug que não seja trivial de 1 linha, ou quando um bug atravessa sessões (estado persistente em .planning/debug/{slug}.md). Herda a Lei de Ferro de maestro-tdd."
---

# 🔍 maestro-debug — Debug com qualidade

Cada bug corrigido deixa o projeto **mais forte**: sai com um teste de regressão commitado. Pipeline autocontido — a investigação é feita aqui, inline, não delegada.

**Fórmula:** bug fix do `maestro-tdd` + investigação sistemática + verificação real (Gate 9) + review (Gate 10).

## Passo 0 — Classificar e abrir sessão

1. **Severidade:** bloqueante (crash, perda de dado) · funcional (comportamento errado) · cosmético.
2. **Complexidade:** L1 (1 arquivo, causa óbvia) — pode corrigir direto com teste; L2+ — pipeline completo.
3. **Slug:** derive um `slug` kebab-case do sintoma (ex.: "Login falha no Safari" → `login-falha-safari`, máx. 30 chars).
4. **Estado persistente:** se o bug pode atravessar sessões (ou já é L3+), crie/abra `.planning/debug/{slug}.md` (formato no fim). Antes de começar, verifique se já existe uma sessão para este bug e retome de onde parou.

## Passo 1 — 🔴 RED: reproduzir com teste

> Nunca corrija um bug sem um teste que o prove.

1. **Sintoma:** o que deveria acontecer? o que acontece? qual a mensagem de erro?
2. Escreva **UM** teste que descreve o comportamento correto e **falha** com o código atual.
3. Rode via **Bash** (`npm test`, `pytest`, `cargo test`…):
   - Falha pelo motivo certo → ✅ bug reproduzido.
   - Passa → o teste não pega o bug; reescreva.
   - Erro (crash, não falha) → ajuste o teste até ser executável.
4. Registre na sessão: `🔴 RED: {teste} reproduz o bug — falha com "{erro}"`.

**Bug não reproduzível em teste** (visual, infra, timing): documente os passos de reprodução manual, registre o bypass no `.planning/EVENT-LOG.md` (HARD RULE 2) e siga.

## Passo 2 — 🔍 Investigar: root cause (método científico)

Investigação sistemática, uma hipótese por vez — não chute o fix:

1. **Hipóteses:** liste as causas plausíveis, da mais provável à menos. Anote na sessão.
2. **Uma por vez:** para cada hipótese, defina o que espera observar e o teste/observação que a confirma ou elimina. Hipótese eliminada vai para a lista `Eliminated` (com o porquê) — nunca a revisite.
3. **Bissecção:** estreite o espaço de busca — comente/isole metades do fluxo, `git bisect` entre um estado bom e o ruim, ou reduza a um caso mínimo que reproduz.
4. **Logs/observação:** instrumente o ponto suspeito (log de valores, breakpoint, `console`/`print` temporário) e leia os valores reais em vez de supor. Remova a instrumentação depois.
5. **Root cause:** ao encontrar, registre `arquivo:linha` e a explicação causal (por que produz o sintoma) — não apenas onde dói.

Modo `--diagnose`: pare aqui. Reporte causa raiz + arquivos + sugestão de fix; grave `status: diagnosed` na sessão. Não corrija.

## Passo 3 — 🟢 GREEN: fix mínimo

1. Corrija com a **menor** alteração que faz o teste do Passo 1 passar. Sem melhorar além do necessário.
2. Rode o teste: passou → ✅; falhou → ajuste e re-rode (**máx. 3 tentativas**, HARD RULE de retry). Após 3 sem sucesso → reporte ao Produtor com o diagnóstico.
3. Registre: `🟢 GREEN: {teste} passa — fix em {arquivo}:{linha}`.

## Passo 4 — ✅ Verificar: build + testes (Gate 9)

1. **Build** via Bash (`npm run build` / `cargo build` / `go build ./...` conforme a stack). Falhou → corrija (máx. 3×).
2. **Todos os testes**, não só o novo. Um teste que passava e agora falha = **regressão** → conserte sem quebrar o que funcionava.
3. Compare com o baseline, se houve health-check pré-trabalho.
4. Registre: `✅ Build: PASS/FAIL · Testes: X/Y · Regressão: nenhuma/{lista} · Novo teste: {nome}`.

## Passo 5 — 🔍 Review (L3+)

Bug que tocou 3+ arquivos ou envolveu decisão de design → `maestro-review --codigo` (subagente em contexto limpo ou `/code-review`), passando o diff + o teste + a descrição do bug. `ISSUES` → corrija e re-submeta; `CLEAN` → siga. Bugs L2 (1-2 arquivos): pule.

## Passo 6 — 📝 Commit + registro (Gate 7/9)

1. **Commit atômico:** fix + teste de regressão juntos (`fix: {bug} + teste de regressão`).
2. **Sessão:** marque `status: fixed` em `.planning/debug/{slug}.md` com a resolução.
3. **STATE.md:** append `[DATA] 🐛 Fix: {bug} | teste: {nome} | build: PASS | tests: X/X` na seção do Workstream ativo.
4. **Reporte** ao Produtor com evidência: teste criado, fix (`arquivo:linha`), build PASS, testes X/X, regressão nenhuma, commit.

## Estado persistente — `.planning/debug/{slug}.md`

Sobrevive a resets de contexto; permite retomar um bug em outra sessão.
```markdown
---
status: investigating | diagnosed | fixing | fixed
trigger: "{descrição verbatim do sintoma}"
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
## Sintomas
esperado / atual / erro / quando começou / como reproduzir

## Current Focus
hypothesis: {hipótese atual}
next_action: {próximo passo concreto}

## Evidence
- {timestamp}: {o que observei}

## Eliminated
- {hipótese}: {por que foi descartada}

## Resolution
root_cause: {arquivo:linha + causa}
fix: {o que mudou}
test: {teste de regressão}
verification: build PASS | tests X/X
```

## Flags e guardrails
- `--diagnose`: só investiga (Passos 0-2), sem corrigir. · `--continue {slug}`: retoma a sessão. · `--list`: lista sessões ativas em `.planning/debug/`.
- `--skip-test`: só para bug não reproduzível; exige reprodução manual documentada e registro do bypass no EVENT-LOG.
- Review é **obrigatório em L3+** (Gate 10) — não há flag para pular.
- Teste é imutável durante o fix: se ele "atrapalha", o problema é o código ou a spec (peça aprovação antes de mexer no teste).
