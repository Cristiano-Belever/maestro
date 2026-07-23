---
name: maestro-tdd
description: "🥁 Disciplina TDD do MAESTRO — impõe RED → GREEN → REFACTOR → COMMIT antes de qualquer código de produção. Carregue ao implementar feature ou lógica, ao corrigir bug (o teste reproduz o bug primeiro), ou sempre que for escrever/alterar código que não seja config pura ou conteúdo estático. É o Ato 3 (Ensaio) na prática."
---

# 🥁 maestro-tdd — Lei de Ferro do TDD

> **NENHUM código de produção sem um teste falhando primeiro.**
> Escreveu código antes do teste? → Delete e recomece. Bypass só com registro (ver abaixo).
> Princípio: "Se você não viu o teste falhar, não sabe se ele testa a coisa certa."

## Ciclo RED → GREEN → REFACTOR → COMMIT

Para cada unidade de comportamento:

### 🔴 RED — teste falhando
1. Escreva UM teste que descreve o comportamento desejado. O nome diz o que o código DEVE fazer.
2. Um comportamento por teste. Tem "e" no nome → divida.
3. Código real, não mocks (mock só quando inevitável).

```typescript
test('rejeita email vazio', async () => {
  const r = await submitForm({ email: '' });
  expect(r.error).toBe('Email obrigatório');
});
```

### ✅ Verificar RED (obrigatório, nunca pular)
Rode o teste com **Bash** (`npm test`, `pytest`, `cargo test`…) e confirme:
- Falha (não dá erro de sintaxe/import).
- A mensagem de falha é a esperada.
- Falha porque a feature não existe — não por typo.

Passou de primeira? Está testando comportamento já existente → conserte o teste. Deu erro em vez de falhar? Conserte o erro e re-rode até falhar direito.

### 🟢 GREEN — código mínimo
Escreva o **mínimo** para o teste passar. Sem features não pedidas, sem refatorar o existente, sem "melhorar" além do necessário. Feio mas verde está certo neste passo.

### ✅ Verificar GREEN (obrigatório)
Rode **todos** os testes via Bash e confirme: o novo passa, os anteriores continuam passando, output limpo (sem warnings). Falhou? Conserte o **código**, nunca o teste. Quebrou outro teste? Conserte agora.

### 🔵 REFACTOR — limpar (só após GREEN)
Remova duplicação, melhore nomes, extraia helpers, aumente legibilidade. Testes verdes o tempo todo; nenhum comportamento novo aqui.

### ⏎ COMMIT
Commit atômico com o teste + o código que o faz passar juntos. Depois, próximo RED.

## Testes são imutáveis durante a implementação
O agente pode RODAR testes, nunca MODIFICÁ-los para fazê-los passar. Se um teste falha após sua mudança → o problema é o **código de produção**. Anti-padrões proibidos: afrouxar assertion para casar com output errado, remover/`skip`/`todo` em teste que falha, mudar mock para retornar o que o código espera.

Exceção (requer **aprovação explícita do Produtor** antes): o teste está genuinamente errado (typo, lógica invertida), o requisito mudou, ou o teste é flaky. Explique o porquê e peça aprovação — nunca altere em silêncio.

## Racionalizações inválidas

| Desculpa | Realidade |
|---|---|
| "Simples demais pra testar" | Código simples quebra. O teste leva 30s. |
| "Testo depois" | Teste que passa de primeira não prova nada. |
| "Já testei manualmente" | Manual ≠ sistemático. Sem registro, sem re-execução. |
| "Deletar horas de trabalho é desperdício" | Custo afundado. Código não confiável é dívida. |
| "TDD é dogma, estou sendo pragmático" | TDD É pragmático: acha bugs antes do commit. |
| "Preciso explorar primeiro" | Explore. Depois delete o spike e recomece com TDD. |
| "O teste é difícil" | Teste difícil = design ruim. Ouça o teste, simplifique. |

**Sinais de alerta → PARE e recomece:** código antes do teste, teste adicionado "depois", teste passa de primeira, não sabe explicar por que o teste falhou, "só desta vez".

## Bug fix com TDD
1. 🔴 Escreva um teste que **reproduz** o bug.
2. ✅ Confirme que ele falha por causa do bug.
3. 🟢 Corrija com o código mínimo.
4. ✅ Confirme que passa e que nada regrediu.
5. 🔵 Limpe se necessário. Commit atômico (fix + teste de regressão).

Nunca corrija um bug sem teste — o teste prova que o bug existia, que foi corrigido e previne regressão.

## Exceções legítimas (bypass anunciado e registrado)
TDD não se aplica a: spike descartável declarado, config pura (`.env`, `config.json`), código gerado, markdown/documentação, conteúdo estático. Na dúvida, aplique TDD.

**Todo bypass é anunciado ao Produtor e registrado** em `.planning/EVENT-LOG.md` (HARD RULE 2 do CLAUDE.md):
```
[YYYY-MM-DDTHH:MM:SSZ] [GATE] Gate 3: SKIP (spike|config|gerado) | motivo: {...} | produtor: {confirmou}
```
Spike tem validade curta: se o código não virar código testado, alerte na próxima sessão.

## Gate 0 — infraestrutura de testes (pré-voo)
Antes do primeiro ciclo, detecte a stack (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`) e o framework de testes. Sem framework configurado, a Lei de Ferro não tem onde se ancorar → **pare e ofereça ao Produtor**: (A) configurar vitest/jest agora, (B) declarar spike descartável, (C) aceitar dívida técnica (registrada em STATE.md). Não prossiga com TDD sem resposta.

## Checklist antes de "done"
- [ ] Cada função/método novo tem teste, escrito **antes** do código.
- [ ] Vi cada teste falhar pelo motivo esperado.
- [ ] Código mínimo para passar; todos os testes verdes; output limpo.
- [ ] Testes usam código real; edge cases e erros cobertos.
- [ ] Reli o pedido original e comparei pedido vs entregue (Gate 6).

Não consegue marcar todas? Você pulou TDD — recomece.
