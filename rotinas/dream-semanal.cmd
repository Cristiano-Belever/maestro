@echo off
REM ============================================================================
REM MAESTRO . dream semanal -- curadoria de memoria (Gate de Admissao).
REM Execucao HEADLESS via Windows Task Scheduler (nao depende do app aberto).
REM
REM Uso:  dream-semanal.cmd [caminho-do-projeto]
REM       sem argumento, usa a pasta atual.
REM Registrado por: rotinas\agendar.ps1 (ou claude-code/install.md, secao Rotinas).
REM ============================================================================
setlocal
set "PROJETO=%~1"
if "%PROJETO%"=="" set "PROJETO=%CD%"
cd /d "%PROJETO%" || exit /b 1

claude -p "Execute a curadoria de memoria (skill maestro-dream) no projeto atual (%PROJETO%). Passos: (1) leia .planning\wisdom\inbox.md; (2) para cada candidato aplique o Gate de Admissao (4 testes: Dano, Pessoa, Recorrencia, Acao) -- reprovou em um, nao grava; (3) grave os aprovados no arquivo certo de .planning\wisdom\ (producer-profile.md, agent-discipline.md, playbook.md, decisions.md ou project-insights\); (4) remova do inbox os candidatos ja curados; (5) atualize .planning\wisdom\counters.json (incrementa o slug; se count>=3 proponha cristalizacao de skill/regra); (6) escreva um relatorio de 5 linhas em .planning\wisdom\dream-logs\DREAM-AAAA-MM-DD.md com a data REAL de hoje. Use apenas Read/Write/Edit; nao rode comandos de shell." --permission-mode acceptEdits

endlocal
