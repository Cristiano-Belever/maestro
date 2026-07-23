# =============================================================================
# MAESTRO . desinstalador (Claude Code)
#
#   .\uninstall.ps1                     # mostra o que seria removido (nada acontece)
#   .\uninstall.ps1 -Sim                # remove de fato (global + projetos do manifesto)
#   .\uninstall.ps1 -Sim -Projeto C:\x  # remove tambem os hooks desse projeto
#   .\uninstall.ps1 -Sim -RemoverPlanning   # apaga tambem o .planning (NAO recomendado)
#
# Regra de ouro: so remove o que o MAESTRO instalou. Config sua no settings.json,
# CLAUDE.md que nao seja do MAESTRO e o historico em .planning/ ficam intactos.
# Os backups feitos na instalacao continuam em ~/.claude/.maestro/backup-*.
# =============================================================================
[CmdletBinding()]
param(
  [Alias('Home')][string]$HomeDir = $env:USERPROFILE,
  [string]$Projeto,
  [switch]$Sim,
  [switch]$RemoverPlanning,
  [switch]$Silencioso
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$executar = [bool]$Sim

function Say($msg, $cor = 'Gray') { if (-not $Silencioso) { Write-Host ("  " + $msg) -ForegroundColor $cor } }
function Acao($msg) { if ($executar) { Say ("removido: " + $msg) 'DarkYellow' } else { Say ("removeria: " + $msg) 'DarkGray' } }

if (-not $Silencioso) {
  Write-Host ""
  Write-Host "  MAESTRO . desinstalador" -ForegroundColor Cyan
  if (-not $executar) { Write-Host "  SIMULACAO . rode com -Sim para remover de fato" -ForegroundColor Yellow }
}

$maestroDir    = Join-Path $HomeDir '.claude\.maestro'
$manifestoPath = Join-Path $maestroDir 'install-manifest.json'
$projetos = @()
if ($Projeto) { $projetos += (Resolve-Path -LiteralPath $Projeto).Path }
if (Test-Path -LiteralPath $manifestoPath) {
  try {
    $m = Get-Content -LiteralPath $manifestoPath -Raw | ConvertFrom-Json
    foreach ($p in @($m.projetos)) { if ($p -and (Test-Path -LiteralPath $p)) { $projetos += $p } }
  } catch { Say "[AVISO] manifesto ilegivel . seguindo pelos caminhos padrao." 'Yellow' }
}
$projetos = @($projetos | Select-Object -Unique)

# ------------------------------ GLOBAL ---------------------------------------
$claudeDir = Join-Path $HomeDir '.claude'

# skills maestro*
$skillsDir = Join-Path $claudeDir 'skills'
if (Test-Path -LiteralPath $skillsDir) {
  foreach ($s in (Get-ChildItem -LiteralPath $skillsDir -Directory | Where-Object { $_.Name -like 'maestro*' })) {
    Acao ("skill " + $s.Name)
    if ($executar) { Remove-Item -LiteralPath $s.FullName -Recurse -Force }
  }
}

# CLAUDE.md (so se for o do MAESTRO)
$claudeMd = Join-Path $claudeDir 'CLAUDE.md'
if (Test-Path -LiteralPath $claudeMd) {
  $txt = Get-Content -LiteralPath $claudeMd -Raw
  if (($txt -match 'MAESTRO') -and ($txt -match 'Effort Router')) {
    Acao $claudeMd
    if ($executar) { Remove-Item -LiteralPath $claudeMd -Force }
  } else {
    Say "CLAUDE.md global nao e do MAESTRO . preservado." 'DarkGray'
  }
}

# GATES.md
$gates = Join-Path $claudeDir 'GATES.md'
if (Test-Path -LiteralPath $gates) { Acao $gates; if ($executar) { Remove-Item -LiteralPath $gates -Force } }

# ------------------------------ PROJETOS -------------------------------------
foreach ($p in $projetos) {
  Say ""
  Say ("projeto: " + $p) 'White'

  $hooks = Join-Path $p '.claude\hooks'
  if (Test-Path -LiteralPath $hooks) {
    foreach ($h in (Get-ChildItem -LiteralPath $hooks -Filter '*.cjs' | Where-Object { $_.Name -match 'flight-recorder|tdd-guard|cortina' })) {
      Acao ("hook " + $h.Name)
      if ($executar) { Remove-Item -LiteralPath $h.FullName -Force }
    }
    if ($executar -and -not (Get-ChildItem -LiteralPath $hooks -Force)) { Remove-Item -LiteralPath $hooks -Force }
  }

  $settingsPath = Join-Path $p '.claude\settings.json'
  if (Test-Path -LiteralPath $settingsPath) {
    try {
      $s = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
      if ($s.PSObject.Properties['hooks']) {
        foreach ($evento in @($s.hooks.PSObject.Properties.Name)) {
          $restantes = @($s.hooks.$evento) | Where-Object { ($_ | ConvertTo-Json -Depth 10 -Compress) -notmatch 'flight-recorder|tdd-guard|cortina' }
          if (@($restantes).Count -eq 0) { $s.hooks.PSObject.Properties.Remove($evento) }
          else { $s.hooks.$evento = @($restantes) }
        }
        if (@($s.hooks.PSObject.Properties).Count -eq 0) { $s.PSObject.Properties.Remove('hooks') }
        Acao "bloco hooks do settings.json (resto da config preservado)"
        if ($executar) { [System.IO.File]::WriteAllText($settingsPath, ($s | ConvertTo-Json -Depth 20), $utf8) }
      }
    } catch { Say "[AVISO] settings.json ilegivel . nao alterado." 'Yellow' }
  }

  $planning = Join-Path $p '.planning'
  if (Test-Path -LiteralPath $planning) {
    if ($RemoverPlanning) {
      Acao ($planning + " (historico do projeto!)")
      if ($executar) { Remove-Item -LiteralPath $planning -Recurse -Force }
    } else {
      Say ".planning preservado (historico do projeto). Use -RemoverPlanning para apagar." 'DarkGray'
    }
  }
}

# ------------------------------ MANIFESTO ------------------------------------
if (Test-Path -LiteralPath $manifestoPath) {
  Acao "manifesto de instalacao"
  if ($executar) { Remove-Item -LiteralPath $manifestoPath -Force }
}

if (-not $Silencioso) {
  Write-Host ""
  if ($executar) {
    Write-Host "  MAESTRO removido." -ForegroundColor Green
    if (Test-Path -LiteralPath $maestroDir) {
      Write-Host ("  Backups da instalacao continuam em: " + $maestroDir) -ForegroundColor DarkGray
      Write-Host "  (pode apagar a pasta a mao quando quiser)" -ForegroundColor DarkGray
    }
    Write-Host "  Rotinas agendadas, se voce criou: .\rotinas\agendar.ps1 -Remover" -ForegroundColor DarkGray
  } else {
    Write-Host "  Nada foi alterado. Rode de novo com -Sim para executar." -ForegroundColor Yellow
  }
  Write-Host ""
}
exit 0
