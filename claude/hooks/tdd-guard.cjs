#!/usr/bin/env node
/**
 * MAESTRO · TDD Guard — hook PreToolUse (MODO AVISO)
 * ------------------------------------------------------------------
 * Repatria o Gate 3 (Lei de Ferro do TDD) do MAESTRO v3.5 como aviso,
 * não como bloqueio (ANALISE-FABLE §2 e §8: começar em modo aviso e
 * endurecer depois, para não gerar atrito em spikes/protótipos).
 *
 * Regra:
 *   Para Write/Edit em arquivo de código-fonte de produção sob uma raiz
 *   de produção — src/, app/, pages/, lib/, components/ ou server/ —
 *   (**\/*.{ts,tsx,js,jsx,py}) que NÃO seja teste
 *   (*.test.*, *.spec.*, __tests__/, /tests/):
 *     - Se um arquivo de teste JÁ foi editado nesta sessão -> silêncio.
 *     - Caso contrário -> NÃO bloqueia; injeta additionalContext
 *       lembrando o Gate 3 (RED antes de GREEN) e a obrigação de
 *       registrar bypass no EVENT-LOG.
 *
 * Marcador de sessão: .planning/.tdd-session guarda o session_id em que
 * um teste foi tocado. Assim o aviso é escopado à sessão atual e não
 * "vaza" entre sessões.
 *
 * SEMPRE exit 0. Modo aviso: nunca nega a tool.
 *
 * Node puro, sem dependências. Windows-safe (path.join).
 */

'use strict';

const fs = require('fs');
const path = require('path');

function done() {
  process.exit(0);
}
process.on('uncaughtException', done);

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

// Normaliza para barras "/" para casar padrões independentemente do SO.
function toPosix(p) {
  return String(p || '').replace(/\\/g, '/');
}

function isTestFile(posixPath) {
  return (
    /\.(test|spec)\.[a-z]+$/i.test(posixPath) ||
    /(^|\/)__tests__\//.test(posixPath) ||
    /(^|\/)tests?\//.test(posixPath)
  );
}

// Raízes de produção reconhecidas: src/, app/, pages/, lib/, components/, server/.
const PROD_ROOTS = /(^|\/)(src|app|pages|lib|components|server)\//;

function isProductionSource(posixPath) {
  // Precisa estar sob uma raiz de produção e ter extensão de código suportada.
  const underProdRoot = PROD_ROOTS.test(posixPath);
  const codeExt = /\.(ts|tsx|js|jsx|py)$/i.test(posixPath);
  return underProdRoot && codeExt && !isTestFile(posixPath);
}

function markerPath(projectDir) {
  return path.join(projectDir, '.planning', '.tdd-session');
}

function testTouchedThisSession(projectDir, sessionId) {
  if (!sessionId) return false;
  try {
    const marked = fs.readFileSync(markerPath(projectDir), 'utf8').trim();
    return marked === sessionId;
  } catch (_) {
    return false;
  }
}

function recordTestTouched(projectDir, sessionId) {
  if (!sessionId) return;
  try {
    const planningDir = path.join(projectDir, '.planning');
    fs.mkdirSync(planningDir, { recursive: true });
    fs.writeFileSync(markerPath(projectDir), sessionId, 'utf8');
  } catch (_) {
    // marcador é best-effort
  }
}

function emitReminder(filePosix, onFlushed) {
  const context = [
    '🎼 Gate 3 (Lei de Ferro do TDD) — AVISO, não bloqueio.',
    `Você está prestes a editar código de produção (${filePosix}) sem que nenhum`,
    'arquivo de teste tenha sido tocado nesta sessão.',
    'A Lei de Ferro pede RED antes de GREEN: escreva/atualize um teste que falhe primeiro.',
    'Se este for um bypass legítimo (spike descartável, config pura, conteúdo estático,',
    'protótipo declarado), prossiga — mas ANUNCIE o bypass e registre-o no',
    '.planning/EVENT-LOG.md com o motivo (HARD RULE 2: todo bypass é registrado).',
  ].join(' ');

  const out = {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      additionalContext: context,
    },
  };
  process.stdout.write(JSON.stringify(out), () => {
    if (typeof onFlushed === 'function') onFlushed();
  });
}

async function main() {
  const raw = await readStdin();

  let payload;
  try {
    payload = JSON.parse(raw.replace(/^\uFEFF/, '')); // BOM: stdin do PowerShell
  } catch (_) {
    return done();
  }

  const toolName = payload && payload.tool_name;
  if (toolName !== 'Write' && toolName !== 'Edit') {
    return done();
  }

  const input = (payload && payload.tool_input) || {};
  const filePath = input.file_path || input.filePath || input.path || '';
  const posix = toPosix(filePath);
  if (!posix) return done();

  const projectDir = (payload && payload.cwd) || process.cwd();
  const sessionId = payload && payload.session_id;

  // Edição de um teste -> marca a sessão e segue em silêncio.
  if (isTestFile(posix)) {
    recordTestTouched(projectDir, sessionId);
    return done();
  }

  // Edição de código de produção sem teste tocado -> lembrete (não bloqueia).
  if (isProductionSource(posix) && !testTouchedThisSession(projectDir, sessionId)) {
    // Escreve e sai no callback do write (evita truncar stdout no pipe).
    return emitReminder(posix, done);
  }

  return done();
}

main();
