#!/usr/bin/env node
/**
 * MAESTRO · Flight Recorder — hook PostToolUse
 * ------------------------------------------------------------------
 * Repatria o "Flight Recorder" morto do MAESTRO v3.5 (ANALISE-FABLE §2).
 * Faz append determinístico de uma linha em .planning/EVENT-LOG.md para
 * cada uso de Write, Edit, NotebookEdit e Bash.
 *
 * Formato da linha:
 *   [ISO-timestamp] [tool] resumo
 *   - Write/Edit/NotebookEdit -> caminho do arquivo afetado
 *   - Bash                    -> comando executado (1 linha, truncado)
 *
 * Contrato do hook (Claude Code):
 *   - Recebe o JSON do evento via STDIN.
 *   - Append-only; cria o arquivo/dir se não existir; NUNCA trunca.
 *   - Silencioso: SEMPRE exit 0. Erro do próprio script jamais quebra a sessão.
 *
 * Node puro, sem dependências. Windows-safe (path.join, nunca concatenação).
 */

'use strict';

const fs = require('fs');
const path = require('path');

// ------------------------------------------------------------------
// Nunca deixar uma exceção escapar: o hook precisa ser invisível.
// ------------------------------------------------------------------
function safeExit() {
  process.exit(0);
}
process.on('uncaughtException', safeExit);

function readStdin() {
  return new Promise((resolve) => {
    let data = '';
    try {
      process.stdin.setEncoding('utf8');
      process.stdin.on('data', (chunk) => (data += chunk));
      process.stdin.on('end', () => resolve(data));
      process.stdin.on('error', () => resolve(data));
    } catch (_) {
      resolve(data);
    }
  });
}

// Colapsa qualquer valor em uma única linha enxuta para o log.
function oneLine(value, max) {
  if (value === undefined || value === null) return '';
  let s = String(value);
  s = s.replace(/\s+/g, ' ').trim();
  if (typeof max === 'number' && s.length > max) {
    s = s.slice(0, max - 1) + '…';
  }
  return s;
}

// Deriva o resumo humano da linha a partir do tool_input.
function summarize(toolName, toolInput) {
  const input = toolInput && typeof toolInput === 'object' ? toolInput : {};
  switch (toolName) {
    case 'Write':
    case 'Edit':
      return oneLine(input.file_path || input.filePath || input.path || '(arquivo desconhecido)', 300);
    case 'NotebookEdit':
      return oneLine(input.notebook_path || input.notebookPath || input.file_path || '(notebook desconhecido)', 300);
    case 'Bash':
      return oneLine(input.command || '(comando vazio)', 300);
    default:
      return '';
  }
}

async function main() {
  const raw = await readStdin();

  let payload;
  try {
    payload = JSON.parse(raw.replace(/^\uFEFF/, '')); // BOM: stdin do PowerShell
  } catch (_) {
    return safeExit(); // sem JSON válido, nada a registrar
  }

  const toolName = payload && payload.tool_name;
  const TRACKED = ['Write', 'Edit', 'NotebookEdit', 'Bash'];
  if (!TRACKED.includes(toolName)) {
    return safeExit(); // fora do escopo de auditoria
  }

  // cwd do projeto: preferir o informado pelo hook; fallback para process.cwd().
  const projectDir = (payload && payload.cwd) || process.cwd();
  const planningDir = path.join(projectDir, '.planning');
  const logFile = path.join(planningDir, 'EVENT-LOG.md');

  const summary = summarize(toolName, payload.tool_input);
  const timestamp = new Date().toISOString();
  const line = `[${timestamp}] [${toolName}] ${summary}\n`;

  try {
    fs.mkdirSync(planningDir, { recursive: true });

    // Semente com cabeçalho apenas na primeira criação (não trunca existentes).
    if (!fs.existsSync(logFile)) {
      const header =
        '# 🛫 EVENT-LOG — Flight Recorder do MAESTRO\n' +
        '> Append-only. Gerado pelo hook PostToolUse (flight-recorder.cjs). Não editar à mão.\n\n';
      fs.appendFileSync(logFile, header, 'utf8');
    }

    fs.appendFileSync(logFile, line, 'utf8');
  } catch (_) {
    // Falha de I/O nunca pode quebrar a sessão.
  }

  return safeExit();
}

main();
