@echo off
REM ============================================================================
REM MAESTRO . scout-github -- varredura semanal do que o mercado publicou no
REM GitHub, com propostas de evolucao para o framework. Execucao HEADLESS via
REM Windows Task Scheduler (nao depende do app do Claude Code estar aberto).
REM
REM Uso:  scout-github.cmd [caminho-do-projeto]
REM       sem argumento, usa a pasta atual.
REM
REM A rotina SO PROPOE: nunca altera skills, hooks, CLAUDE.md ou GATES.md.
REM
REM --allowedTools libera SO leitura do GitHub via gh (search/api/release/repo).
REM Sem isso, em modo headless o gh e bloqueado por permissao e a rotina cai
REM para busca web -- perde estrelas e data de ultimo commit (o filtro de hype).
REM ============================================================================
setlocal
set "PROJETO=%~1"
if "%PROJETO%"=="" set "PROJETO=%CD%"
cd /d "%PROJETO%" || exit /b 1

claude -p "Execute o SCOUT GITHUB semanal do MAESTRO no projeto atual (%PROJETO%). OBJETIVO: descobrir o que o mercado publicou no GitHub que possa evoluir este framework, e propor - nunca aplicar. PASSOS: (1) Pesquise, priorizando o que mudou nos ultimos 14 dias: (a) releases/changelog do Claude Code e da Anthropic - eventos de hook novos, formato de skills/plugins/subagentes, mudancas de settings.json; (b) repositorios ativos e populares de frameworks, kits e colecoes para Claude Code e agentes de codigo (por exemplo listas 'awesome', colecoes de skills, hooks, subagentes, workflows, memoria, spec-driven development) - registre estrelas e data do ultimo commit para separar hype de tracao real; (c) um tema rotativo da stack: escolha entre Next.js, Supabase e Design systems o que NAO apareceu no relatorio mais recente de .planning\\scout\\. Use o gh CLI quando disponivel (gh search repos, gh release list, gh api) e busca web como apoio. (2) Para CADA achado relevante responda em uma linha: o MAESTRO ja faz isso? faz melhor? faz pior? nao faz e deveria? Descarte o que for modismo sem tracao (poucas estrelas, abandonado, ou que troca disciplina por automacao nao-curada). (3) Grave um relatorio CURTO em .planning\\scout\\GITHUB-{data}.md, com {data} = a data REAL de hoje em AAAA-MM-DD (nunca invente a data; crie o diretorio se nao existir). Estrutura: frontmatter com data e tema rotativo; uma secao 'Achados' com uma linha por item e a URL da fonte; uma secao 'Propostas' com no MAXIMO 3 propostas acionaveis - cada uma com o que e, por que importa para o MAESTRO, esforco estimado (L1-L5) e o proximo passo concreto; e uma secao final 'Descartados' com uma linha por item rejeitado e o motivo. (4) Acrescente ao final de .planning\\BACKLOG.md uma linha por proposta, marcada com a origem (scout-github + data). (5) PROIBIDO nesta rotina: alterar qualquer skill, hook, CLAUDE.md, GATES.md, settings.json ou codigo de projeto. Voce so escreve dentro de .planning\\scout\\ e acrescenta linhas ao BACKLOG.md. (6) Se a semana nao tiver nada relevante, escreva 'sem novidade relevante nesta rodada' e encerre - nao encha linguica. (7) Cite SEMPRE a URL da fonte de cada achado." --permission-mode acceptEdits --allowedTools "Bash(gh search:*)" "Bash(gh api:*)" "Bash(gh release:*)" "Bash(gh repo view:*)" "WebSearch" "WebFetch" "Read" "Write" "Edit" "Glob" "Grep"

endlocal
