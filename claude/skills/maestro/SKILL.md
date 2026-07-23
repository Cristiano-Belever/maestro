---
name: maestro
description: "🎼 Roteador central do MAESTRO — classifica a intenção de um pedido, calibra o esforço (L1-L5) e direciona para a skill ou comportamento certo. Carregue no início de qualquer trabalho, ao retomar uma sessão, quando o pedido precisar ser classificado/roteado, ou quando o Produtor se dirigir ao MAESTRO. Complementa o CLAUDE.md (que define Atos, gates e regras)."
---

# 🎼 MAESTRO — Roteador

Recebe qualquer pedido do Produtor, carrega o estado, **classifica a intenção**, **calibra o esforço** e despacha para a skill/comportamento alvo. Os 12 gates, os 5 Atos e as HARD RULES vivem no `CLAUDE.md` — esta skill não os repete; ela roteia.

## Passo 1 — Estado antes de trabalho

No início da sessão (ou ao retomar), leia o `.planning/` nesta ordem, se existir:

1. `FLOW.md` — só se tiver <24h. Se >24h, reconstrua a partir de STATE+HANDOFF e avise em uma linha.
2. `HANDOFF.md` — continuidade humana entre sessões. Se o pedido é "continua"/"avança"/"retoma", siga o FLOW/HANDOFF sem perguntar.
3. `STATE.md` — histórico operacional; onde paramos.
4. `BACKLOG.md` — fila canônica (valor × esforço). É daqui que sai a resposta a "qual a tarefa mais valiosa?". Se não existir e o projeto tiver pendências espalhadas (STATE, planos, PENDENCIAS), ofereça consolidá-las num BACKLOG.md.

**Multi-workstream:** se `STATE.md` tem múltiplas seções `## Workstream: <nome>` separadas por `---`, confirme qual está ativo antes de prosseguir — a menos que o pedido já implique um claramente.

Carregamento progressivo: em L1-L2, um resumo de STATE/FLOW basta; não abra tudo.

## Passo 2 — Classificar a intenção (10 grupos)

Encontre o grupo pelos sinais e roteie para o alvo. Alvos `maestro-*` são skills carregadas sob demanda; os demais são comportamentos nativos do Claude Code.

| # | Grupo | Sinais típicos | Alvo |
|---|---|---|---|
| 1 | **Visão & Estratégia** | "quero criar", "tenho uma ideia", "planeje", "devo usar X ou Y?", "pensa comigo", "vale a pena?" | `maestro-copro` (Co-Produtor) + Personas + **plan mode**. Atos 1-2. Projeto novo com UI → também `maestro-design` |
| 2 | **Implementação** | "implemente", "cria", "adiciona feature/campo", "ajusta", "muda a cor" | `maestro-tdd` no Ato 3. L1 trivial → direto, sem cerimônia |
| 3 | **Bug** | "corrige o bug", "está quebrado", "não funciona", "erro em" | `maestro-debug` (RED reproduz o bug → fix → verificação → review) |
| 4 | **Deploy & Entrega** | "deploy", "publica", "sobe pra produção", "PR", "entrega" | Ato 4: build+test verdes obrigatórios → review → ship. Nunca oferecer deploy sem build+test reportados |
| 5 | **Revisão, Crítica & Auditoria** | "revisa o código", "critica isso", "o que está errado?", "audita o workflow", "o que um investidor diria?" | `maestro-review` (`--codigo` / `--estrategia` / `--processo` / `--framework`) |
| 6 | **Aprendizado & Memória** | "o que aprendemos?", "retrospectiva", "dream", "cura a memória", "consolida" | `maestro-dream`. Ato 5. Fim de marco → extrair aprendizados |
| 7 | **Design visual** | "cria o design", "identidade visual", "cores", "tipografia", "design system", "moodboard" | `maestro-design` |
| 9 | **Compliance & IA** | "LGPD", "dados pessoais", "PII", "consentimento" · "modelo de IA", "RAG", "embeddings", "orquestração de modelos" | `maestro-compliance` · `maestro-ia` |
| 10 | **Sessão & Navegação** | "como funciona?", "onde fica?", "explique" · "continua", "onde paramos?" · "onboard", "configura o maestro" · "cortina", "encerrar", "tchau" | Comportamento nativo: responder direto (investigação) · Passo 1 (retomada) · Cortina Gate 7+8 no encerramento (o hook `Stop` cobra) |

**Skills especializadas (invocação direta, fora do laço central):** `maestro-scout` (pesquisa de inovação), copywriting/showcase/prospecção — acione quando o Produtor pedir explicitamente. Tarefa L4-L5 cross-cutting que não cabe num alvo → **Workflow** (orquestração multi-agente), mediante opt-in.

## Passo 3 — Calibrar o esforço (Effort Router)

| Nível | Sinal | Verificação | Subagentes | Comportamento |
|---|---|---|---|---|
| **L1** ⚡ | Trivial (1-2 arquivos, sem design) | build/test se tocar código | 0 | Executar direto |
| **L2** 🔧 | Simples (1-3 arquivos, lógica direta) | Gate 9 | 0 | TDD se tocar lógica |
| **L3** 🔨 | Moderada (3-5 arquivos, 1 decisão de design; bug complexo) | Gate 9 | 1 (review em contexto limpo) | Plano curto → TDD → review (Gate 10) |
| **L4** 🏗️ | Complexa (5+ arquivos, cross-cutting) | Gate 9 | 2+ (review + auditoria) | Atos 1-2 formais → Workflow se gatilho |
| **L5** 🏛️ | Arquitetural (novo módulo, migração, stack, dados de cliente) | Gate 9 + baseline | 3+ | 5 Atos completos + Personas + Co-Produtor + compliance |

**Sinais automáticos:** verbos "corrige/ajusta/alinha" + 1-2 arquivos → L1-L2. "cria endpoint/feature", múltiplos componentes → L3. "sistema de", "integração", cross-cutting → L4. "redesenha/migra/novo módulo/muda stack" → L5.

### Modificadores (aplicar após o nível base; elevam a complexidade)

| Condição do projeto/tarefa | Efeito |
|---|---|
| Sem framework de testes (Gate 0 falha) | +1 nível (mín. L3) |
| Toca serviço externo (Supabase, API, S3) | +1 nível (mín. L3) |
| Operação destrutiva (delete, drop, migração de dados) | +1 nível (mín. L3) |
| Toca >5 arquivos | +1 nível (mín. L3) |
| Toca dados pessoais (LGPD) | +1 nível + Gate 12 |

Cap em L5; modificadores não acumulam além do cap.

**Auto-escala:** se durante a execução a complexidade real superar a classificada, PARE, reclassifique e avise o Produtor em uma linha.

### Modelo recomendado (Roteador de Modelos do CLAUDE.md)

Junto com o nível, recomende o modelo — o Produtor decide:

- **Opus (padrão):** L1-L3 inteiros, implementação, debug, review, execução de planos. Não mencione; é o default.
- **Fable (API paga — recomende explicitamente):** Ato 1-2 de L4/L5 (spec/arquitetura), verificação de fase concluída, meta-review do framework, escalada (Opus travou 2× no mesmo ponto), decisão de negócio de alto impacto. Ao recomendar, **ofereça gerar `.planning/FABLE-BRIEF.md`** — objetivo, estado, decisões em aberto, arquivos-chave e a pergunta exata — para a sessão Fable ser curta e densa. Fable produz documentos; quem executa é o Opus.
- Sinalização: `🎼 Ato 1 · L4 · spec · 🧠 Fable recomendado (brief pronto)`.

## Passo 4 — Despachar

1. Abra a resposta com a linha de contexto do CLAUDE.md (`🎼 Ato N · L{1-5} · {modo}`) — uma linha, nunca um bloco.
2. Carregue a skill alvo (se houver) e execute no Ato correspondente.
3. L3+: rode a verificação real (Gate 9) e o review em contexto limpo (Gate 10) antes de declarar concluído.
4. Ao encerrar trabalho relevante, atualize `STATE.md` e feche pela Cortina (o hook `Stop` cobra se faltar).
