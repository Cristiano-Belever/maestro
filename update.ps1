# =============================================================================
# MAESTRO . atualizador
#
#   .\update.ps1                       # git pull + reinstala global
#   .\update.ps1 -Projeto C:\meu\app   # atualiza tambem os hooks do projeto
#
# Atualizar o MAESTRO = baixar a versao nova do repo e rodar o install de novo.
# O install e idempotente: skills sao substituidas, CLAUDE.md e GATES.md ganham
# backup automatico, e o .planning/ do projeto nunca e tocado.
# =============================================================================
[CmdletBinding()]
param(
  [string]$Projeto,
  [switch]$SemGit,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot

Write-Host ""
Write-Host "  MAESTRO . atualizador" -ForegroundColor Cyan

$versaoAntes = if (Test-Path -LiteralPath (Join-Path $kit 'VERSION')) { (Get-Content -LiteralPath (Join-Path $kit 'VERSION') -Raw).Trim() } else { '?' }

if (-not $SemGit) {
  if (Test-Path -LiteralPath (Join-Path $kit '.git')) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "git nao encontrado no PATH. Baixe o ZIP novo do repo e rode install.ps1, ou use -SemGit." }
    Write-Host "  buscando atualizacoes..." -ForegroundColor Gray
    git -C $kit pull --ff-only
    if ($LASTEXITCODE -ne 0) { throw "git pull falhou. Resolva o conflito no repo do kit e rode de novo." }
  } else {
    Write-Host "  [aviso] esta copia nao e um clone git - pulando o pull." -ForegroundColor Yellow
    Write-Host "          para receber atualizacoes automaticas: git clone https://github.com/Cristiano-Belever/maestro" -ForegroundColor DarkGray
  }
}

$versaoDepois = if (Test-Path -LiteralPath (Join-Path $kit 'VERSION')) { (Get-Content -LiteralPath (Join-Path $kit 'VERSION') -Raw).Trim() } else { '?' }
Write-Host ("  versao: " + $versaoAntes + "  ->  " + $versaoDepois) -ForegroundColor DarkGray

$argumentos = @{}
if ($Projeto) { $argumentos['Projeto'] = $Projeto }
if ($Force)   { $argumentos['Force']   = $true }
& (Join-Path $kit 'install.ps1') @argumentos

if (Test-Path -LiteralPath (Join-Path $kit 'CHANGELOG.md')) {
  Write-Host "  O que mudou: veja CHANGELOG.md" -ForegroundColor DarkGray
  Write-Host ""
}
exit 0
