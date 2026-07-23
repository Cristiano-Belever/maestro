# =============================================================================
# MAESTRO . instalador (Claude Code)
#
#   .\install.ps1                          # instala global (skills + CLAUDE.md + GATES.md)
#   .\install.ps1 -Projeto C:\meu\app      # instala global E prepara o projeto (hooks + .planning)
#   .\install.ps1 -Projeto . -SomenteProjeto   # modo teste: nada fora da pasta do projeto
#   .\install.ps1 -Produtor "Seu Nome, papel"  # personaliza a identidade no CLAUDE.md
#   .\install.ps1 -DryRun                  # mostra o que faria, sem escrever nada
#
# Idempotente: rodar de novo = atualizar. Nunca sobrescreve um CLAUDE.md alheio
# sem backup. Tudo o que instala fica registrado no manifesto, e o uninstall.ps1
# remove exatamente isso.
# =============================================================================
[CmdletBinding()]
param(
  [Alias('Home')][string]$HomeDir = $env:USERPROFILE,
  [string]$Projeto,
  [switch]$SomenteProjeto,
  [string]$Produtor,
  [switch]$Force,
  [switch]$DryRun,
  [switch]$Silencioso
)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot

# ------------------------------- utilitarios ---------------------------------
$utf8 = New-Object System.Text.UTF8Encoding($false)   # sem BOM: Node/JSON exigem
function Say($msg, $cor = 'Gray')  { if (-not $Silencioso) { Write-Host ("  " + $msg) -ForegroundColor $cor } }
function Titulo($msg)              { if (-not $Silencioso) { Write-Host ""; Write-Host $msg -ForegroundColor Cyan } }
function EscreverTexto($caminho, $conteudo) {
  if ($DryRun) { return }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $caminho) | Out-Null
  [System.IO.File]::WriteAllText($caminho, $conteudo, $utf8)
}
function Backup($caminho, $pastaBackup) {
  if (-not (Test-Path -LiteralPath $caminho)) { return $null }
  if ($DryRun) { return '(dry-run)' }
  New-Item -ItemType Directory -Force -Path $pastaBackup | Out-Null
  $destino = Join-Path $pastaBackup (Split-Path -Leaf $caminho)
  Copy-Item -LiteralPath $caminho -Destination $destino -Force
  return $destino
}

$carimbo    = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$maestroDir = Join-Path $HomeDir '.claude\.maestro'
$backupDir  = Join-Path $maestroDir ("backup-" + $carimbo)
$versao     = if (Test-Path -LiteralPath (Join-Path $kit 'VERSION')) { (Get-Content -LiteralPath (Join-Path $kit 'VERSION') -Raw).Trim() } else { 'desconhecida' }

$manifesto = [ordered]@{
  versao          = $versao
  instalado_em    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  origem          = $kit
  escopo          = if ($SomenteProjeto) { 'projeto' } else { 'global' }
  arquivos_global = @()
  skills          = @()
  projetos        = @()
}

if (-not $Silencioso) {
  Write-Host ""
  Write-Host "  MAESTRO . instalador" -ForegroundColor Cyan
  Write-Host ("  versao " + $versao + "  |  home: " + $HomeDir) -ForegroundColor DarkGray
  if ($DryRun) { Write-Host "  MODO DRY-RUN . nada sera escrito" -ForegroundColor Yellow }
}

# --------------------------- pre-requisito: node -----------------------------
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Say "[AVISO] Node.js nao encontrado no PATH. Os 3 hooks precisam dele (https://nodejs.org)." 'Yellow'
  Say "        O resto do MAESTRO (skills, CLAUDE.md, gates) funciona sem Node." 'DarkGray'
}

# ============================== ALVO GLOBAL ==================================
$alvoBase = if ($SomenteProjeto) {
  if (-not $Projeto) { throw "-SomenteProjeto exige -Projeto <caminho>" }
  (Resolve-Path -LiteralPath $Projeto).Path
} else {
  $HomeDir
}
$claudeDir = Join-Path $alvoBase '.claude'

Titulo ("1) Skills e regras  ->  " + $claudeDir)

# --- skills ---
$skillsOrigem = Join-Path $kit 'claude\skills'
$skillsDestino = Join-Path $claudeDir 'skills'
if (-not (Test-Path -LiteralPath $skillsOrigem)) { throw "Kit incompleto: falta $skillsOrigem" }
foreach ($s in (Get-ChildItem -LiteralPath $skillsOrigem -Directory)) {
  $destino = Join-Path $skillsDestino $s.Name
  Say ("skill  " + $s.Name)
  if (-not $DryRun) {
    if (Test-Path -LiteralPath $destino) { Remove-Item -LiteralPath $destino -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $destino | Out-Null
    Copy-Item -Path (Join-Path $s.FullName '*') -Destination $destino -Recurse -Force
  }
  $manifesto.skills += $s.Name
}

# --- CLAUDE.md ---
$claudeMdDestino = Join-Path $claudeDir 'CLAUDE.md'
$claudeMdOrigem  = Join-Path $kit 'claude\CLAUDE.md'
$conteudo = Get-Content -LiteralPath $claudeMdOrigem -Raw
$perfil = if ($Produtor) { $Produtor } else { 'personalize esta identidade . veja "Como o Produtor trabalha" logo abaixo' }
$conteudo = $conteudo.Replace('{{PRODUTOR}}', $perfil)
if ($SomenteProjeto) { $conteudo = $conteudo.Replace('~/.claude/GATES.md', '.claude/GATES.md').Replace('~/.claude/skills/', '.claude/skills/') }

$instalarClaudeMd = $true
if (Test-Path -LiteralPath $claudeMdDestino) {
  $atual = Get-Content -LiteralPath $claudeMdDestino -Raw
  $ehNosso = ($atual -match 'MAESTRO') -and ($atual -match 'Effort Router')
  $b = Backup $claudeMdDestino $backupDir
  if ($ehNosso -or $Force) {
    Say ("CLAUDE.md existente (MAESTRO) . backup em " + $b + " e atualizado") 'DarkYellow'
  } else {
    $instalarClaudeMd = $false
    Say "CLAUDE.md ja existe e NAO e do MAESTRO . NAO foi tocado." 'Yellow'
    Say ("  backup: " + $b) 'DarkGray'
    Say ("  para mesclar: abra " + $claudeMdOrigem + " e cole as secoes que quiser, ou rode com -Force.") 'DarkGray'
  }
}
if ($instalarClaudeMd) {
  EscreverTexto $claudeMdDestino $conteudo
  Say "CLAUDE.md instalado"
  $manifesto.arquivos_global += $claudeMdDestino
}

# --- GATES.md ---
$gatesDestino = Join-Path $claudeDir 'GATES.md'
if (Test-Path -LiteralPath $gatesDestino) { Backup $gatesDestino $backupDir | Out-Null }
if (-not $DryRun) {
  New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
  Copy-Item -LiteralPath (Join-Path $kit 'claude\GATES.md') -Destination $gatesDestino -Force
}
Say "GATES.md instalado"
$manifesto.arquivos_global += $gatesDestino

# ============================ ALVO: PROJETO ==================================
if ($Projeto) {
  $projPath = (Resolve-Path -LiteralPath $Projeto).Path
  Titulo ("2) Projeto  ->  " + $projPath)

  # --- hooks ---
  $hooksDestino = Join-Path $projPath '.claude\hooks'
  if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $hooksDestino | Out-Null }
  foreach ($h in (Get-ChildItem -LiteralPath (Join-Path $kit 'claude\hooks') -Filter '*.cjs')) {
    Say ("hook   " + $h.Name)
    if (-not $DryRun) { Copy-Item -LiteralPath $h.FullName -Destination $hooksDestino -Force }
  }

  # --- settings.json (merge nao-destrutivo) ---
  $settingsPath = Join-Path $projPath '.claude\settings.json'
  $template     = Get-Content -LiteralPath (Join-Path $kit 'claude\settings-template.json') -Raw | ConvertFrom-Json
  $nossos       = 'flight-recorder|tdd-guard|cortina'

  if (Test-Path -LiteralPath $settingsPath) {
    Backup $settingsPath $backupDir | Out-Null
    try { $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json }
    catch { throw "settings.json do projeto e JSON invalido ($settingsPath). Corrija ou remova antes de instalar." }
  } else {
    $settings = New-Object PSObject
  }
  if (-not $settings.PSObject.Properties['hooks']) {
    $settings | Add-Member -NotePropertyName hooks -NotePropertyValue (New-Object PSObject)
  }
  foreach ($evento in $template.hooks.PSObject.Properties.Name) {
    $novos = @($template.hooks.$evento)
    $existentes = @()
    if ($settings.hooks.PSObject.Properties[$evento]) {
      $existentes = @($settings.hooks.$evento) | Where-Object {
        ($_ | ConvertTo-Json -Depth 10 -Compress) -notmatch $nossos
      }
    }
    $final = @($existentes) + $novos
    if ($settings.hooks.PSObject.Properties[$evento]) { $settings.hooks.$evento = $final }
    else { $settings.hooks | Add-Member -NotePropertyName $evento -NotePropertyValue $final }
  }
  EscreverTexto $settingsPath (($settings | ConvertTo-Json -Depth 20))
  Say "settings.json com os hooks do MAESTRO (config existente preservada)"

  # --- .planning minimo ---
  $planning = Join-Path $projPath '.planning'
  $hoje = Get-Date -Format 'yyyy-MM-dd'
  $sementes = @{
    'STATE.md'        = "# STATE`n`n> Historico operacional: uma linha por resultado VERIFICADO.`n> Formato: [DATA] OK <tarefa> | build: PASS | tests: X/X`n"
    'HANDOFF.md'      = "# HANDOFF`n`n> Continuidade entre sessoes (Gate 7). Reescrito ao encerrar.`n`n## Estado`n(vazio - MAESTRO instalado em $hoje)`n`n## Proximo passo concreto`n-`n"
    'BACKLOG.md'      = "# BACKLOG`n`n> Fila canonica de tarefas, ordenada por valor x esforco.`n`n| # | Tarefa | Valor | Esforco | Status |`n|---|---|---|---|---|`n"
    'wisdom\inbox.md' = "# WISDOM INBOX`n`n> Candidatos crus a aprendizado (Gate 8). O dream cura depois.`n"
  }
  foreach ($rel in $sementes.Keys) {
    $p = Join-Path $planning $rel
    if (Test-Path -LiteralPath $p) { Say ("mantido .planning\" + $rel + " (ja existia)") 'DarkGray' }
    else { EscreverTexto $p $sementes[$rel]; Say (".planning\" + $rel) }
  }

  $manifesto.projetos += $projPath
}

# ============================== MANIFESTO ====================================
if (-not $DryRun) {
  New-Item -ItemType Directory -Force -Path $maestroDir | Out-Null
  $manifestoPath = Join-Path $maestroDir 'install-manifest.json'
  # preserva projetos ja instalados em execucoes anteriores
  if (Test-Path -LiteralPath $manifestoPath) {
    try {
      $antigo = Get-Content -LiteralPath $manifestoPath -Raw | ConvertFrom-Json
      $manifesto.projetos = @($antigo.projetos + $manifesto.projetos | Where-Object { $_ } | Select-Object -Unique)
    } catch { }
  }
  [System.IO.File]::WriteAllText($manifestoPath, ($manifesto | ConvertTo-Json -Depth 10), $utf8)
}

if (-not $Silencioso) {
  Write-Host ""
  Write-Host "  MAESTRO instalado." -ForegroundColor Green
  Write-Host ""
  Write-Host "  Proximos passos:" -ForegroundColor White
  Write-Host "   1. Abra (ou reabra) o Claude Code . hooks e skills sao lidos no inicio da sessao."
  Write-Host "   2. Personalize sua identidade: peca ao MAESTRO para reescrever a secao"
  Write-Host "      'Como o Produtor trabalha' do CLAUDE.md com base em 5 perguntas."
  Write-Host "   3. Em cada projeto novo: /maestro-onboard --novo"
  Write-Host ""
  Write-Host "  Desinstalar a qualquer momento: .\uninstall.ps1" -ForegroundColor DarkGray
  Write-Host ""
}
exit 0
