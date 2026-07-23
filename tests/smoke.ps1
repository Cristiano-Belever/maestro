# =============================================================================
# MAESTRO . teste de fumaca do kit (instalar -> verificar -> desinstalar)
# Roda 100% em sandbox: nao toca no seu ~/.claude nem em nenhum projeto real.
#   .\tests\smoke.ps1
# Saida: lista de checagens + exit code 0 (tudo passou) ou 1 (algo falhou).
# =============================================================================
[CmdletBinding()]
param(
  [string]$Sandbox
)

$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $PSScriptRoot

if (-not $Sandbox) {
  $Sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("maestro-smoke-" + [guid]::NewGuid().ToString('N').Substring(0,8))
}
$sandHome = Join-Path $Sandbox 'home'
$sandProj = Join-Path $Sandbox 'projeto'
New-Item -ItemType Directory -Force -Path $sandHome, $sandProj | Out-Null

$script:falhas = 0
$script:total  = 0
function Check([string]$nome, [scriptblock]$cond) {
  $script:total++
  $ok = $false
  try { $ok = [bool](& $cond) } catch { $ok = $false }
  if ($ok) { Write-Host ("  [OK]   " + $nome) -ForegroundColor Green }
  else     { Write-Host ("  [FALHA] " + $nome) -ForegroundColor Red; $script:falhas++ }
}

Write-Host ""
Write-Host "MAESTRO . smoke test" -ForegroundColor Cyan
Write-Host ("sandbox: " + $Sandbox) -ForegroundColor DarkGray
Write-Host ""

# --- Pre-condicao: settings.json do projeto ja existente com config propria ---
New-Item -ItemType Directory -Force -Path (Join-Path $sandProj '.claude') | Out-Null
$settingsPath = Join-Path $sandProj '.claude\settings.json'
[System.IO.File]::WriteAllText($settingsPath, '{"env":{"MINHA_VAR":"preservar"}}', (New-Object System.Text.UTF8Encoding($false)))

# =============================== INSTALAR ====================================
Write-Host "1) install.ps1 (global + projeto)" -ForegroundColor Yellow
& (Join-Path $kit 'install.ps1') -Home $sandHome -Projeto $sandProj -Produtor 'Teste Automatizado' -Silencioso
Check "install.ps1 saiu com exit code 0" { $LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE }

$skillsDir = Join-Path $sandHome '.claude\skills'
Check "skills instaladas (>=9 pastas maestro-*/maestro)" {
  (Get-ChildItem -LiteralPath $skillsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'maestro*' }).Count -ge 9
}
Check "toda skill tem SKILL.md" {
  $dirs = Get-ChildItem -LiteralPath $skillsDir -Directory | Where-Object { $_.Name -like 'maestro*' }
  ($dirs | Where-Object { -not (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md')) }).Count -eq 0
}
Check "CLAUDE.md global instalado e personalizado" {
  $p = Join-Path $sandHome '.claude\CLAUDE.md'
  (Test-Path -LiteralPath $p) -and ((Get-Content -LiteralPath $p -Raw) -match 'MAESTRO') -and ((Get-Content -LiteralPath $p -Raw) -match 'Teste Automatizado')
}
Check "CLAUDE.md global sem placeholder sobrando" {
  (Get-Content -LiteralPath (Join-Path $sandHome '.claude\CLAUDE.md') -Raw) -notmatch '\{\{PRODUTOR\}\}'
}
Check "GATES.md global instalado" { Test-Path -LiteralPath (Join-Path $sandHome '.claude\GATES.md') }
Check "manifesto de instalacao gravado" { Test-Path -LiteralPath (Join-Path $sandHome '.claude\.maestro\install-manifest.json') }

Check "3 hooks .cjs no projeto" {
  (Get-ChildItem -LiteralPath (Join-Path $sandProj '.claude\hooks') -Filter '*.cjs' -ErrorAction SilentlyContinue).Count -eq 3
}
Check "settings.json continua sendo JSON valido" {
  $null = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json; $true
}
Check "settings.json sem BOM (Node consegue ler)" {
  $bytes = [System.IO.File]::ReadAllBytes($settingsPath)
  -not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
}
Check "hooks registrados (PostToolUse/PreToolUse/Stop)" {
  $s = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
  $s.hooks.PostToolUse -and $s.hooks.PreToolUse -and $s.hooks.Stop
}
Check "config previa do usuario preservada (env.MINHA_VAR)" {
  ((Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json).env.MINHA_VAR) -eq 'preservar'
}
Check ".planning minimo criado" {
  (Test-Path -LiteralPath (Join-Path $sandProj '.planning\STATE.md')) -and
  (Test-Path -LiteralPath (Join-Path $sandProj '.planning\HANDOFF.md')) -and
  (Test-Path -LiteralPath (Join-Path $sandProj '.planning\BACKLOG.md')) -and
  (Test-Path -LiteralPath (Join-Path $sandProj '.planning\wisdom\inbox.md'))
}

# =========================== HOOK DE VERDADE =================================
Write-Host ""
Write-Host "2) hook flight-recorder executado de verdade (node)" -ForegroundColor Yellow
$node = (Get-Command node -ErrorAction SilentlyContinue)
if ($node) {
  $payload = '{"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"src/exemplo.ts"},"cwd":"' + ($sandProj -replace '\\','\\') + '"}'
  $payload | & node (Join-Path $sandProj '.claude\hooks\flight-recorder.cjs') | Out-Null
  Check "EVENT-LOG.md registrou a acao" {
    $p = Join-Path $sandProj '.planning\EVENT-LOG.md'
    (Test-Path -LiteralPath $p) -and ((Get-Content -LiteralPath $p -Raw) -match '\[Write\]')
  }
} else {
  Write-Host "  [SKIP] node nao encontrado no PATH - hook nao testado" -ForegroundColor DarkYellow
}

# ============================= IDEMPOTENCIA ==================================
Write-Host ""
Write-Host "3) rodar install.ps1 de novo (idempotencia)" -ForegroundColor Yellow
& (Join-Path $kit 'install.ps1') -Home $sandHome -Projeto $sandProj -Silencioso
Check "settings.json segue valido apos 2a instalacao" {
  $null = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json; $true
}
Check "hooks NAO duplicaram (1 entrada por evento)" {
  $s = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
  (@($s.hooks.PostToolUse).Count -eq 1) -and (@($s.hooks.PreToolUse).Count -eq 1) -and (@($s.hooks.Stop).Count -eq 1)
}
Check "config previa AINDA preservada" {
  ((Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json).env.MINHA_VAR) -eq 'preservar'
}

# ============================== DESINSTALAR ==================================
Write-Host ""
Write-Host "4) uninstall.ps1" -ForegroundColor Yellow
& (Join-Path $kit 'uninstall.ps1') -Home $sandHome -Projeto $sandProj -Sim -Silencioso
Check "skills maestro-* removidas" {
  (Get-ChildItem -LiteralPath $skillsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'maestro*' }).Count -eq 0
}
Check "CLAUDE.md global removido" { -not (Test-Path -LiteralPath (Join-Path $sandHome '.claude\CLAUDE.md')) }
Check "GATES.md global removido" { -not (Test-Path -LiteralPath (Join-Path $sandHome '.claude\GATES.md')) }
Check "hooks do projeto removidos" { -not (Test-Path -LiteralPath (Join-Path $sandProj '.claude\hooks\cortina.cjs')) }
Check "bloco hooks removido do settings.json" {
  $s = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
  -not $s.hooks -or -not $s.hooks.Stop
}
Check "config do usuario SOBREVIVEU a desinstalacao" {
  ((Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json).env.MINHA_VAR) -eq 'preservar'
}
Check ".planning preservado (historico nao se joga fora)" {
  Test-Path -LiteralPath (Join-Path $sandProj '.planning\STATE.md')
}

# ================================ RESUMO =====================================
Write-Host ""
if ($script:falhas -eq 0) {
  Write-Host ("RESULTADO: " + $script:total + "/" + $script:total + " checagens passaram.") -ForegroundColor Green
  Remove-Item -LiteralPath $Sandbox -Recurse -Force -ErrorAction SilentlyContinue
  exit 0
} else {
  Write-Host ("RESULTADO: " + ($script:total - $script:falhas) + "/" + $script:total + " passaram . " + $script:falhas + " FALHA(S).") -ForegroundColor Red
  Write-Host ("sandbox preservado para inspecao: " + $Sandbox) -ForegroundColor DarkGray
  exit 1
}
