# Fusão dos branches de exploração e novo sumário da tese

**Status:** COMPLETED (2026-11-07) — recriado em 2026-11-08 (o original ficou num worktree removido, porque `quality_reports/plans/` é ignorado pelo git)
**Branch de trabalho:** `worktree-fusao-sumario` (a partir de `main` @ 019814b), avançado no `main` como `fffbf0a`

## Decisões da autora (2026-11-07)

- Sumário aprovado: 00 Introdução · 01 Revisão · 02 Panorama descritivo · empíricos 03 EC 111 e competitividade · 04 Sobreposição territorial do voto · 05 Coordenação territorial das listas · 99 Conclusão.
- Os antigos placeholders (02 Dados e Métodos, 03 Índice G/QL, 04 Alinhamento gasto-voto, 05 Gasto na base territorial do partido) somem. Continham só título + `TODO`.
- Conteúdo de explorações que não entrou em capítulo deve continuar acessível em `explorations/` no `main`.

## Passos executados

1. Merge `worktree-ql-voto-2026` (Cap. 2 descritivo + capítulo do voto; remove placeholders) — sem conflito.
2. Merge `worktree-competitividade-abd-lss` (Cap. EC 111; já contém `worktree-did-ec111-2026`) — conflitos em `_quarto.yml`, `CLAUDE.md`, `Bibliography_base.bib` e rename/delete do `07-alinhamento` resolvidos pelo sumário aprovado; `.bib` une as entradas dos dois lados.
3. Merge `worktree-competitividade-margem-gasto` (só exploração) — sem conflito.
4. Commit do trabalho que estava sem commit no worktree `ql-voto-2026` (Resultados do capítulo do voto + 3 figuras).
5. Renumeração: `04-ec111…` → `03-`, `05b-…voto` → `04-`, `06-…partido` → `05-` (capítulos e pastas de figuras). "Capítulo 6" fixo no texto trocado por `Capítulo [-@sec-sobreposicao-territorial]`. Relatórios históricos em `quality_reports/` e SESSION_LOGs mantêm os nomes da época.
6. Merge `worktree-did-ec111-ql-municipio` (sandbox; plano com decisões em aberto).
7. Merge do `main` (arquivamento de `senadoras-2026` feito em outra sessão); `explorations/README.md` reescrito como inventário.
8. Limpeza: worktrees e branches locais/remotos já integrados removidos (incluindo `origin/claude/capitulo-acoes-afirmativas-x0hpuv`).

## Verificação

- `quarto render Quarto/thesis`: 8/8 arquivos, sem avisos; 18 imagens resolvem; nenhum `?@` não resolvido.
- Bug corrigido na verificação: a resolução do conflito do `.bib` perdeu a `}` final de `BolognesiRibeiroCodatoSilva2025_centro_ideologico`.
- `quality_score.py`: capítulos 01–05 com 100/100; `check-surface-sync.sh` ok.
