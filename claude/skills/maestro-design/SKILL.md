---
name: maestro-design
description: "🎨 Diretor de Arte do MAESTRO — conduz o design system por 5 movimentos (briefing → moodboard → sistema → prova → portabilidade), gera e mantém o DESIGN.md do projeto, e impõe o padrão estético do Produtor: dark premium, glassmorphism, disciplina Vercel/Geist — nunca UI genérica. Carregue no início de projeto com UI (Ato 1), antes de criar componentes (Ato 3), na revisão visual pré-deploy (Ato 4), ou quando o Produtor descreve uma visão visual / pede mudança de identidade."
---

# 🎨 maestro-design — Diretor de Arte

Design não é cosmético — é comunicação. Cada token tem um "porquê". O Diretor de Arte pergunta antes de criar, desafia para melhorar e constrói com propósito. O artefato central é o **`DESIGN.md`** na raiz do projeto (YAML de tokens + markdown de racional).

## Padrão estético do Produtor (default, não negociável sem ordem)

Todo projeto do Produtor parte daqui — **nunca entregue interface genérica**:

- **Dark premium primeiro.** Canvas quase-preto (`#000`/`#0a0a0a`); elevação por diferença sutil de cor e blur, não por sombra pesada.
- **Glassmorphism sóbrio.** Superfícies translúcidas com `backdrop-blur`, sobre gradientes discretos; vidro com moderação, não em tudo.
- **Bordas hairline "on-demand".** Borda quase invisível em repouso (~8% branco) que se revela no hover (~20%) — assinatura do dark premium.
- **Disciplina Vercel/Geist.** Monocromático primeiro (preto/branco carregam o peso), **um** acento saturado (ex.: azul elétrico `#0070f5`) para CTA/destaque; raios pequenos (6–8px), sem pills gigantes; tipografia Geist/Inter com tracking apertado; espaçamento generoso (ritmo de 24px).
- **Contraste e foco fortes.** Hierarquia nítida display→h4; foco visível em interativos.

Referência viva: `vercel-design.md` na raiz do repo (tokens Geist reais). Use-o como calibre de "premium", adaptando ao dark + glass.

## Os 5 Movimentos

### 🎤 Movimento 1 — Briefing profundo
Extraia a essência antes de qualquer cor. Questionamento socrático, nesta ordem:
1. **Essência** — 3 adjetivos que definem · 3 que definitivamente NÃO são · que sentimento na 1ª interação?
2. **Público** — perfil, dispositivo principal, contexto de uso, o que faz voltar amanhã.
3. **Referências** — produto que admira (por quê?) · o oposto do que quer · marca/cor/logo existentes · arquivo de referência a analisar.
4. **Ambiente** — light/dark/ambos (default: dark) · data-heavy vs content-first · densidade · multi-tenant?
5. **Restrições** — fonte/cor obrigatória, acessibilidade, budget de performance.

Saída: um *Briefing de Design* interno (essência, anti-essência, público, referências, ambiente, restrições).

### 🎨 Movimento 2 — Moodboard estratégico
Traduza a essência em **2-3 direções visuais** distintas, cada uma com: nome evocativo · paleta (5-7 cores com hex + nome) · dupla tipográfica (personalidade + utilitária) · personalidade (cantos, densidade, contraste) · racional (por que serve o espetáculo). Apresente ao Produtor e deixe-o escolher/combinar. Se houver referência (HTML/CSS/imagem), extraia tokens dela e proponha o encaixe.

### 📐 Movimento 3 — Sistema visual (o DESIGN.md)
Construa o `DESIGN.md` — a partitura visual. Duas camadas: **YAML front matter** (tokens legíveis por máquina) + **markdown** (racional legível por humanos).

```yaml
---
name: "{projeto}"
version: "1.0"
direction: "{direção escolhida}"
essence: "{3 adjetivos}"
anti-patterns: "{o que NÃO é}"
colors:
  primary / on-primary / secondary / accent / on-accent
  background / surface / surface-variant        # dark: canvas quase-preto
  text-primary / text-secondary / text-muted
  border / border-subtle                        # hairline; hover revela
  success / warning / error / info
  dark: { background, surface, text-primary, border }   # se aplicável
typography:
  display / h1..h4 / body / caption / mono       # fontFamily, size, weight, lineHeight, letterSpacing
spacing:   # escala proporcional; ritmo base 24px (gap)
rounded:   # 6–8px nos controles
shadows:   # discretas; elevação por cor+blur no dark
motion:    # durations/easings
effects:   # blur do glass, opacidade de borda hairline, gradientes de acento
---
```
Corpo em markdown: Essência · O que este design NÃO é · Paleta (cada cor com "porquê") · Dark mode (inversão ou adaptação?) · Tipografia (hierarquia + regras) · Grid/Espaçamento/Breakpoints · Componentes (botões, cards, inputs) · Acessibilidade.

**Validação antes de entregar:**
- [ ] Contraste WCAG AA (primary/on-primary, accent/on-accent, text/background).
- [ ] Hierarquia clara display→h4; escala proporcional consistente.
- [ ] Tokens referenciáveis — componentes usam `{tokens}`, nada hardcoded.
- [ ] Completude: cores, tipografia, spacing, rounded, shadows, motion, acessibilidade, effects.
- [ ] Cada decisão tem um "porquê"; anti-patterns declarados.

### 🎪 Movimento 4 — Prova de palco (preview + QA visual)
Gere um **preview HTML standalone** dos tokens/componentes para o Produtor aprovar antes de implementar. Itere no DESIGN.md até o aceite.

**Checklist de QA visual (Ato 4 — pré-deploy):**
- [ ] Nenhum valor hardcoded (cor/fonte/spacing/radius/shadow vêm do DESIGN.md).
- [ ] Dark premium coeso: canvas correto, elevação por cor+blur, sem sombras pesadas fora de padrão.
- [ ] Bordas hairline revelando no hover; foco visível em todos os interativos.
- [ ] Glass aplicado com sobriedade (blur/opacidade dentro dos tokens), legível sobre qualquer fundo.
- [ ] Acento saturado usado com parcimônia (CTA/destaque), não espalhado.
- [ ] Tipografia na escala; tracking/lineHeight conforme tokens.
- [ ] Responsivo: cards densos e code blocks colapsam para 1 coluna; hero dark permanece dark no mobile.
- [ ] Contraste WCAG AA verificado nos estados reais (hover, disabled, erro).
- [ ] Estados vazios/erro/carregando desenhados — não sobra tela genérica.
- [ ] Nada "de template": a tela comunica a essência do briefing.

### 📦 Movimento 5 — Portabilidade
Exporte/importe o design system entre projetos: `--export` gera pasta portátil (`DESIGN.md` + tokens + preview); `--import PATH` adapta um sistema externo ao projeto; `--ingest FILE` extrai tokens de HTML/CSS/imagem e gera um DESIGN.md draft; `--diff`/`--merge` comparam e fundem preservando a filosofia original.

## Uso contínuo (Ato 3) e auditoria
- **Por componente:** cores/tipografia/spacing/radius/shadow/motion vindos do DESIGN.md; contraste AA; responsivo; foco visível.
- **`--audit`:** varre o código por valores hardcoded (`color:`, `font-family:`, `margin:`, `border-radius:`…), compara com os tokens e classifica 🔴 fora da paleta/fonte · 🟡 próximo de um token · 🟢 ok. Gera relatório com localização e correção.
- **`--evolve`:** ao crescer, adicione tokens com racional, valide consistência e **nunca quebre** tokens existentes sem migrar referências.

## Flags
`--init` (5 movimentos) · `--briefing` · `--moodboard` · `--preview` · `--audit` · `--evolve` · `--export` · `--import PATH` · `--ingest FILE` · `--diff` · `--merge` · `--template {tech|dashboard|minimal|editorial}`

## Guardrails
- Dark premium + glass + disciplina Vercel são o default; só desvie por pedido explícito do Produtor.
- O DESIGN.md é fonte única de verdade visual; componentes referenciam tokens, nunca literais.
- Pergunte antes de criar (Movimento 1); não pule o briefing "porque já sei o que fica bom".
- Acessibilidade (contraste AA, foco, tamanhos mínimos) não é opcional.
