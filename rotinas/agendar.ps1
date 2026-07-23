# =============================================================================
# MAESTRO . agendador de rotinas (Windows Task Scheduler)
#
#   .\rotinas\agendar.ps1 -Projeto C:\meu\projeto        # agenda as duas rotinas
#   .\rotinas\agendar.ps1 -Projeto . -Rotinas scout      # so o scout do GitHub
#   .\rotinas\agendar.ps1 -Listar                        # mostra o que esta agendado
#   .\rotinas\agendar.ps1 -Remover                       # remove as tarefas do MAESTRO
#
# Padrao:
#   maestro-scout-github    segunda 09:00   varre o GitHub e PROPOE melhorias
#   maestro-dream-semanal   sexta   17:00   cura a memoria (.planning/wisdom)
#
# Ambas usam -StartWhenAvailable: se o computador estiver desligado na hora
# marcada, a rotina roda assim que ele voltar. Nada se perde.
#
# Pre-requisito: o CLI `claude` no PATH (as rotinas rodam `claude -p` headless).
# =============================================================================
[CmdletBinding()]
param(
  [string]$Projeto,
  [ValidateSet('todas','scout','dream')][string]$Rotinas = 'todas',
  [string]$HoraScout = '09:00',
  [ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string]$DiaScout = 'Monday',
  [string]$HoraDream = '17:00',
  [ValidateSet('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')][string]$DiaDream = 'Friday',
  [switch]$Listar,
  [switch]$Remover
)

$ErrorActionPreference = 'Stop'
$rotinasDir = $PSScriptRoot

function Info($m, $c = 'Gray') { Write-Host ("  " + $m) -ForegroundColor $c }

Write-Host ""
Write-Host "  MAESTRO . rotinas agendadas" -ForegroundColor Cyan

# ------------------------------- LISTAR --------------------------------------
if ($Listar) {
  $tarefas = Get-ScheduledTask -TaskName 'maestro-*' -ErrorAction SilentlyContinue
  if (-not $tarefas) { Info "nenhuma rotina do MAESTRO agendada." 'Yellow'; Write-Host ""; exit 0 }
  foreach ($t in $tarefas) {
    $info = Get-ScheduledTaskInfo -TaskName $t.TaskName
    Info ($t.TaskName + "  [" + $t.State + "]") 'White'
    Info ("   comando:  " + $t.Actions[0].Execute + " " + $t.Actions[0].Arguments) 'DarkGray'
    Info ("   proxima:  " + $info.NextRunTime + "   ultima: " + $info.LastRunTime + " (" + $info.LastTaskResult + ")") 'DarkGray'
  }
  Write-Host ""
  exit 0
}

# ------------------------------- REMOVER -------------------------------------
if ($Remover) {
  $tarefas = Get-ScheduledTask -TaskName 'maestro-*' -ErrorAction SilentlyContinue
  if (-not $tarefas) { Info "nenhuma rotina do MAESTRO agendada." 'Yellow'; Write-Host ""; exit 0 }
  foreach ($t in $tarefas) {
    Unregister-ScheduledTask -TaskName $t.TaskName -Confirm:$false
    Info ("removida: " + $t.TaskName) 'DarkYellow'
  }
  Write-Host ""
  exit 0
}

# ------------------------------- AGENDAR -------------------------------------
if (-not $Projeto) { throw "Informe -Projeto <caminho do projeto que a rotina vai operar> (ou use -Listar / -Remover)." }
$projPath = (Resolve-Path -LiteralPath $Projeto).Path

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Info "[AVISO] CLI 'claude' nao encontrado no PATH - a tarefa sera criada, mas so roda quando o CLI existir." 'Yellow'
}

$config = @()
if ($Rotinas -in @('todas','scout')) {
  $config += @{ Nome = 'maestro-scout-github'; Cmd = (Join-Path $rotinasDir 'scout-github.cmd'); Dia = $DiaScout; Hora = $HoraScout
                Desc = 'MAESTRO: varredura semanal do GitHub com propostas de evolucao (so propoe, nao altera o framework)' }
}
if ($Rotinas -in @('todas','dream')) {
  $config += @{ Nome = 'maestro-dream-semanal'; Cmd = (Join-Path $rotinasDir 'dream-semanal.cmd'); Dia = $DiaDream; Hora = $HoraDream
                Desc = 'MAESTRO: curadoria semanal de memoria (Gate de Admissao)' }
}

foreach ($c in $config) {
  if (-not (Test-Path -LiteralPath $c.Cmd)) { Info ("[PULADO] script ausente: " + $c.Cmd) 'Yellow'; continue }

  $acao     = New-ScheduledTaskAction -Execute $c.Cmd -Argument ('"' + $projPath + '"') -WorkingDirectory $projPath
  $gatilho  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $c.Dia -At $c.Hora
  $opcoes   = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 1)

  if (Get-ScheduledTask -TaskName $c.Nome -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $c.Nome -Confirm:$false
    Info ("substituindo tarefa existente: " + $c.Nome) 'DarkGray'
  }
  Register-ScheduledTask -TaskName $c.Nome -Action $acao -Trigger $gatilho -Settings $opcoes -Description $c.Desc | Out-Null
  Info ($c.Nome + "  ->  " + $c.Dia + " " + $c.Hora + "  |  projeto: " + $projPath) 'Green'
}

Write-Host ""
Info "Conferir:  .\rotinas\agendar.ps1 -Listar" 'DarkGray'
Info "Testar agora (roda de verdade):  Start-ScheduledTask -TaskName maestro-scout-github" 'DarkGray'
Write-Host ""
exit 0
