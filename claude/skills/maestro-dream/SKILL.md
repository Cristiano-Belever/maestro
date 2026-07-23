---
name: maestro-dream
description: "🌙 Curadoria de memória do MAESTRO — a ÚNICA implementação do ciclo de sabedoria. Lê os candidatos crus do inbox (capturados pelo Gate 8/Cortina), aplica o Gate de Admissão completo (4 testes), grava os aprovados no arquivo certo de wisdom, mantém o contador de promoção e cristaliza padrões recorrentes. Carregue quando o Produtor pedir dream/consolidar/curar a memória, no fim de um marco, ou quando disparada por scheduled task. Roda em <2 min."
---

# 🌙 maestro-dream — Curadoria de memória (implementação única)

Fecha o loop de aprendizado do MAESTRO. A captura de candidatos é responsabilidade do **Gate 8 / Cortina** (append livre em `inbox.md`, sem filtro). Aqui é o **único** lugar onde o Gate de Admissão roda — elimina a antiga triplicação (cortina/dream/orquestrador). Nada de reler `brain/`: o `inbox.md` é a fonte de candidatos.

**Trigger:** manual (`/maestro-dream`) **e** scheduled task semanal (P0.4). Sem argumento, roda o ciclo completo abaixo.

**Filosofia:** na dúvida, NÃO adicionar. É mais seguro não ter uma memória do que ter uma que engana no contexto errado.

## Passo 1 — Ler candidatos

Ler `.planning/wisdom/inbox.md`. Cada bloco (bullet ou parágrafo sob um `##`) é um candidato bruto. Conte o total. Inbox vazio → relatório com tudo zero e encerra.

## Passo 2 — Gate de Admissão completo (4 testes)

Para **cada** candidato, aplicar os 4 testes do CLAUDE.md. Reprovou em **qualquer** um → **descartar** (não grava; registra o motivo no relatório).

1. **Dano** — Se eu esquecer isso, algo dá errado de verdade? (ou: aplicado no contexto errado, causa prejuízo?) → reprova se for inócuo/genérico.
2. **Pessoa** — É sobre COMO o Produtor/projeto funciona, não um fato genérico de programação? → se for específico de **projeto**, o destino é `project-insights/{projeto}.md` (isolado, nunca cruzar projetos).
3. **Recorrência** — Vai se repetir em sessões futuras? → se ainda não, entra como candidato 🔹 (silencioso) no `playbook.md`.
4. **Ação** — Muda um comportamento concreto meu (diz o que FAZER)? → observação pura não entra.

## Passo 3 — Gravar aprovados e limpar o inbox

Para cada aprovado, redigir no formato do arquivo destino e **remover do inbox** (o inbox só guarda o que ainda não foi curado):

| Tipo do insight | Destino |
|---|---|
| Preferência pessoal / como o Produtor trabalha ou decide | `wisdom/producer-profile.md` |
| Padrão técnico / como fazer algo (condicional a contexto) | `wisdom/playbook.md` |
| Decisão de arquitetura ou do framework | `wisdom/decisions.md` |
| Específico de um projeto | `wisdom/project-insights/{projeto}.md` |

Formato de entrada no playbook: `**Quando:** {contexto} → **Faça:** {ação}` (prescrição, não observação). Limite curadoria a ~10 mudanças por arquivo por execução — curadoria é gradual. Nunca apague um arquivo de wisdom inteiro; edite entradas.

## Passo 4 — Contador de promoção (Gate 11)

Manter `.planning/wisdom/counters.json`. Formato exato:
```json
{
  "padrao-slug": { "count": 2, "primeira": "2026-07-01", "ultima": "2026-07-03", "fontes": ["projeto-x", "projeto-y"] }
}
```

Para cada candidato **aprovado**:
1. Derivar um `slug` kebab-case do núcleo do insight (ex.: "sempre validar env antes do build" → `validar-env-pre-build`).
2. Se já existe padrão **similar** (mesmo slug ou equivalente semântico): incrementar `count`, atualizar `ultima` (data de hoje) e dar append da `fonte` (projeto/sessão) se nova.
3. Se é novo: criar entrada com `count: 1`, `primeira` = `ultima` = hoje, `fontes: [fonte]`.

**Promoção ao atingir `count >= 3`:**
- Marcar o padrão como **✅ confirmado** no `playbook.md` (troca o 🔹 candidato por ✅, com nota `(confirmado em N fontes)`).
- Propor **cristalização** (Gate 11): gravar `.planning/wisdom/skill-proposals/PROP-{YYYY-MM-DD}-{slug}.md` com: o padrão, as fontes/evidências, e um esboço de skill ou regra nova. **Sugerir ao Produtor** — não criar a skill automaticamente; a decisão é dele.

> As datas vêm do sistema no momento da execução (a scheduled task injeta a data; em execução manual, use a data corrente). Nunca invente datas.

## Passo 5 — Relatório (exatamente 5 linhas)

```
🌙 Dream — {data}
Candidatos lidos: N
Aprovados: A (destinos: producer-profile ×i, playbook ×j, decisions ×k, project-insights ×l)
Descartados: D (motivo por candidato)
Contadores: +C incrementados | Promoções: P (slugs) → propostas em skill-proposals/
```

## Guardrails
- Gate de Admissão é **obrigatório** — nenhum insight entra sem passar nos 4 testes.
- Priorizar NÃO adicionar sobre adicionar; candidatos 🔹 são silenciosos até promoção.
- Nunca cruzar `project-insights/` entre projetos.
- Antes de **remover** algo de `decisions.md`, perguntar ao Produtor.
- Tudo é rastreável: o relatório justifica cada descarte e cada promoção.
- Trabalho enxuto: alvo <2 min. Sem varredura de logs brutos; o inbox já é o funil.
