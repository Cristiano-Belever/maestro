---
name: maestro-compliance
description: "🛡️ Guardião de Compliance do MAESTRO (Gate 12) — verifica LGPD (minimização, consentimento, direitos do titular), Privacy by Design e a cobertura do Flight Recorder (EVENT-LOG.md) contra o COMPLIANCE-RULES.md do projeto. Carregue quando o Produtor mencionar LGPD/dados pessoais/DPO/ANPD, quando uma feature tocar dados pessoais, antes de deploy de sistema que trata PII, ou em auditoria de projeto. A fonte normativa é o COMPLIANCE-RULES.md — esta skill aplica e verifica, não redefine as regras."
---

# 🛡️ maestro-compliance — Gate 12 (LGPD + Privacy by Design)

Garante que a música seja bela **e** legal. A norma vive no **`COMPLIANCE-RULES.md`** da raiz do projeto — esta skill **aplica e verifica** contra ele; não duplica nem reinventa as regras. Quando este documento e a skill divergirem, o `COMPLIANCE-RULES.md` vence.

## Passo 1 — Estado de compliance do projeto
1. `COMPLIANCE-RULES.md` existe na raiz? **Não** → `--init` (crie a partir do template do repo do MAESTRO, substitua `{NOME_DO_PROJETO}`, marque como "N/A" as seções que o projeto não usa). **Sim** → carregue como referência.
2. `.planning/compliance/` existe? Senão, crie. Último audit >30 dias ou inexistente → sugira `--audit`.
3. Carregue o contexto (stack, integrações, se toca dados pessoais). **Se não há dado pessoal algum**, a maior parte do Gate 12 é N/A — registre e siga leve.

## Passo 2 — Os quatro scans (`--audit`)
Auditoria contra as seções do `COMPLIANCE-RULES.md`. Cite sempre a seção/artigo da norma no achado.

**Código (`--check-code`)** — varra o fonte por: PII em loggers (`console.log`/`logger` com email, CPF, nome, telefone) 🔴 · secrets hardcoded (fora de `.env`) 🔴 · SQL sem parametrização 🔴 · `.env` fora do `.gitignore` 🟠 · input sem validação/sanitização 🟠 · CORS wildcard em produção 🟡 · sem rate limit / sem CSP 🟡 · deps vulneráveis (`npm audit`) 🔵.

**Infra (`--check-infra`)** — RLS habilitado e com policies (Supabase); gestão de env/secrets; headers de segurança; configuração CORS.

**Dados (`--check-data`)** — pipelines RAG/embeddings com filtragem por tenant/namespace; mecanismo de exclusão do titular (Art. 18); e a **cobertura do Flight Recorder** (Passo 3).

**Frontend / transparência (`--check-frontend`)** — contato do DPO/Encarregado; Política de Privacidade; Termos; banner de cookies granular (se aplicável). Podem ser discretos, **nunca** ausentes.

## Passo 3 — Verificar o Flight Recorder (EVENT-LOG.md)
O `COMPLIANCE-RULES.md` (seção "Auditoria Forense com Flight Recorder") exige log de proveniência **append-only**. No MAESTRO para Claude Code esse log **existe**: é o `.planning/EVENT-LOG.md`, alimentado pelo hook `PostToolUse` (`flight-recorder.cjs`). Portanto, verifique **presença e cobertura**, não ausência:

1. **Presença** — `.planning/EVENT-LOG.md` existe? O hook `flight-recorder` está registrado no `settings.json` (matcher `Write|Edit|NotebookEdit|Bash`)? Se faltar → 🟠 recomende instalar/ativar (ver `claude-code/install.md`).
2. **Cobertura** — o log tem entradas recentes cobrindo as ações da sessão? Timestamps ISO presentes? Se há trabalho de código sem linhas correspondentes → o recorder pode estar desativado; sinalize.
3. **Integridade append-only** — o arquivo cresce, nunca é truncado/reescrito à mão (o cabeçalho avisa "não editar"). Edição manual quebra a garantia forense → 🔴.
4. **Lacuna para produção** — o hook cobre a *auditoria de desenvolvimento* (ações do agente). Para sistemas que tratam dados de cliente em produção, a norma pede também log **imutável e criptografado** das chamadas de IA/consentimento em runtime — isso é responsabilidade do produto, não do hook. Aponte a distinção quando aplicável.

## Passo 4 — Pilares LGPD (checagem, norma no COMPLIANCE-RULES.md)
Verifique a presença dos mecanismos; a definição detalhada está na norma:
- **Minimização (Privacy by Default, Art. 47):** coleta-se só o dado adequado e necessário à finalidade? Campos/scopes excessivos são violação.
- **Consentimento (Art. 7-8):** granular por finalidade, revogável com efeito imediato, registrado em log imutável (quem/quando/o quê/base legal/versão/canal); double opt-in para marketing; fluxo parental para menores (Art. 14).
- **Direitos do titular (Art. 18):** exclusão/anonimização integral e automatizada — inclusive em backups — e portabilidade (export JSON/CSV).
- **Transparência (Art. 9/20):** Política de Privacidade acessível; explicabilidade por progressive disclosure em decisões críticas de IA.
- **Incidentes (Art. 48):** plano de resposta e comunicação à ANPD (~72h); cadeia DPO → Controlador → ANPD → titulares.
- **DPIA/RIPD (Art. 38):** para tratamentos de risco, o relatório de impacto existe?

## Passo 5 — Relatório, severidade e registro
- **Relatório (`--report`)** em `.planning/compliance/`: score, resumo e violações por severidade com localização (arquivo:linha) e correção sugerida, cada uma citando a seção da norma.
- **Regra de deploy (Gate 12):** em **produção**, violações 🔴 CRÍTICAS **bloqueiam** o deploy; em **MVP**, geram alerta forte (não bloqueiam). 🟠 alerta, 🟡 recomendação, 🔵 melhoria.
- **`--fix`:** roda `--audit` antes e corrige o que for seguro automatizar (mover secret para `.env`, adicionar `.env` ao `.gitignore`, parametrizar query); o resto vira backlog.
- **Registro:** toda ação de compliance vira uma linha no próprio `.planning/EVENT-LOG.md`: `[COMPLIANCE] {ação} | score: {N} | violações: {resumo}`.

## Flags
`--init` · `--audit` · `--report` · `--fix` · `--check-code` · `--check-infra` · `--check-data` · `--check-frontend` · `--status` · `--update-rules`

## Guardrails
- `COMPLIANCE-RULES.md` é a fonte normativa; esta skill nunca a contradiz nem a copia — referencia.
- Na dúvida sobre se algo é dado pessoal, trate como se fosse e pergunte ao Produtor (HARD RULE 6 do CLAUDE.md).
- Feature que toca dados pessoais **ativa o Gate 12** — não é opcional.
- Não reporte "conforme" sem evidência: cite a linha do código/log que comprova.
