#!/usr/bin/env node
/**
 * MAESTRO · Cortina — hook Stop
 * ------------------------------------------------------------------
 * Repatria o Handoff/Gate 7 morto do MAESTRO v3.5 (ANALISE-FABLE §2).
 * Cobra a "Cortina" (Gate 7+8 do CLAUDE.md) ao fim de uma sessão que
 * produziu código: atualizar HANDOFF.md, append em STATE.md e 0-3
 * insights em .planning/wisdom/inbox.md.
 *
 * Lógica:
 *   1. Anti-loop: se stop_hook_active === true, exit 0 imediato (não
 *      reentra depois que já cobramos uma vez).
 *   2. Lê o transcript da sessão (transcript_path do JSON do hook) e
 *      verifica se houve uso de Write/Edit.
 *   3. Se houve E .planning/HANDOFF.md NÃO foi modificado nos últimos
 *      30 min -> retorna { "decision": "block", "reason": ... } para
 *      instruir o Claude a executar a Cortina antes de encerrar.
 *   4. Caso contrário -> exit 0 (deixa encerrar).
 *
 * Contrato do hook (Claude Code):
 *   - Recebe o JSON do evento via STDIN.
 *   - Saída de bloqueio em STDOUT: {"decision":"block","reason":"..."}.
 *   - Falha do próprio script nunca deve travar a sessão -> exit 0.
 *
 * Node puro, sem dependências. Windows-safe (path.join).
 */

'use strict';

const fs = require('fs');
const path = require('path');

const HANDOFF_FRESH_MS = 30 * 60 * 1000; // 30 minutos

// ------------------------------------------------------------------
// Em qualquer erro inesperado, deixamos a sessão encerrar (exit 0).
// Fail-open: um hook de cortina jamais deve prender o Produtor.
// ------------------------------------------------------------------
function allowStop() {
  process.exit(0);
}
process.on('uncaughtException', allowStop);

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

// Varre o transcript JSONL procurando qualquer tool_use de Write/Edit.
function sessionEditedCode(transcriptPath) {
  if (!transcriptPath) return false;
  let content;
  try {
    content = fs.readFileSync(transcriptPath, 'utf8');
  } catch (_) {
    return false; // sem transcript legível, não cobramos nada
  }

  const EDIT_TOOLS = new Set(['Write', 'Edit', 'MultiEdit', 'NotebookEdit']);

  // Procura por objetos { type: "tool_use", name: <editor> } em qualquer
  // profundidade de cada linha JSON. Parsing robusto com fallback textual.
  const lines = content.split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    let obj;
    try {
      obj = JSON.parse(trimmed);
    } catch (_) {
      // Fallback: heurística textual se a linha não for JSON puro.
      if (/"type"\s*:\s*"tool_use"/.test(trimmed) &&
          /"name"\s*:\s*"(Write|Edit|MultiEdit|NotebookEdit)"/.test(trimmed)) {
        return true;
      }
      continue;
    }

    if (findEditToolUse(obj, EDIT_TOOLS)) return true;
  }
  return false;
}

// Busca recursiva (com limite de profundidade) por tool_use de edição.
function findEditToolUse(node, editTools, depth) {
  depth = depth || 0;
  if (depth > 12 || node === null || typeof node !== 'object') return false;

  if (!Array.isArray(node)) {
    if (node.type === 'tool_use' && typeof node.name === 'string' && editTools.has(node.name)) {
      return true;
    }
    for (const key of Object.keys(node)) {
      if (findEditToolUse(node[key], editTools, depth + 1)) return true;
    }
    return false;
  }

  for (const item of node) {
    if (findEditToolUse(item, editTools, depth + 1)) return true;
  }
  return false;
}

// HANDOFF.md foi tocado nos últimos 30 min?
function handoffIsFresh(projectDir) {
  const handoff = path.join(projectDir, '.planning', 'HANDOFF.md');
  try {
    const stat = fs.statSync(handoff);
    return Date.now() - stat.mtimeMs < HANDOFF_FRESH_MS;
  } catch (_) {
    return false; // não existe -> precisa ser criado -> não é fresh
  }
}

async function main() {
  const raw = await readStdin();

  let payload;
  try {
    payload = JSON.parse(raw.replace(/^\uFEFF/, '')); // BOM: stdin do PowerShell
  } catch (_) {
    return allowStop();
  }

  // 1. Anti-loop: já estamos dentro de um ciclo de Stop cobrado.
  if (payload && payload.stop_hook_active === true) {
    return allowStop();
  }

  const projectDir = (payload && payload.cwd) || process.cwd();
  const transcriptPath = payload && payload.transcript_path;

  // 2. Houve código nesta sessão?
  if (!sessionEditedCode(transcriptPath)) {
    return allowStop(); // sessão sem edições -> nada a cobrar
  }

  // 3. HANDOFF já atualizado recentemente?
  if (handoffIsFresh(projectDir)) {
    return allowStop(); // Cortina já foi feita
  }

  // 4. Bloqueia e instrui a Cortina (Gate 7+8).
  const reason = [
    '🎼 CORTINA (Gate 7+8) pendente — esta sessão editou código, mas .planning/HANDOFF.md',
    'não foi atualizado nos últimos 30 min. Antes de encerrar, execute a Cortina do MAESTRO:',
    '',
    '  1. Reescreva .planning/HANDOFF.md: o que foi feito, o que falta, próximo passo',
    '     concreto e um prompt de retomada.',
    '  2. Faça append em .planning/STATE.md do resultado verificado',
    '     (formato: [DATA] ✅ [tarefa] | build: PASS | tests: X/X), apenas na seção',
    '     do Workstream ativo.',
    '  3. Registre 0-3 insights em .planning/wisdom/inbox.md (o Gate de Admissão NÃO',
    '     se aplica ao inbox — append livre).',
    '  4. Encerre com uma linha de despedida apontando o próximo passo.',
    '',
    'Depois de fazer isso, pode encerrar normalmente.',
  ].join('\n');

  // IMPORTANTE: escrever e SÓ então sair, no callback do write. Chamar
  // process.exit(0) imediatamente truncaria o stdout no pipe (Windows).
  process.stdout.write(JSON.stringify({ decision: 'block', reason }), () => process.exit(0));
}

main();
