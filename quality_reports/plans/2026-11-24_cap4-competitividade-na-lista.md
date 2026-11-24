# Plano: competitividade e eleição medidas na lista (Cap. 4, EC 111)

**Status:** DRAFT (aguarda aprovação da autora)
**Data:** 2026-11-24
**Capítulo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd` (exibido como Cap. 4)
**Exploração:** `explorations/ec111-did-2026/` (R/10, R/11)
**Antecedente:** plano de 22/11 (`2026-11-22_cap4-ec111-variaveis-identificacao.md`), que pôs competitividade, eleição e investimento relativo na disputa (UF × cargo)

## Motivação (decisão da autora, 24/11)

A pergunta do capítulo é se os partidos adotaram uma **estratégia** para tirar proveito da EC 111. A estratégia é decidida na lista (partido × UF × cargo). A disputa mistura todos os partidos da UF: uma mudança nela pode vir de partidos que mudaram de comportamento ou só do peso relativo entre eles. **Todas as variáveis passam a ser medidas na lista.**

O obstáculo é estatístico. Proporções cujo denominador é o número de competitivas ou de eleitos da lista ficam indefinidas em 32% a 55% das listas federais, que não têm nenhuma competitiva ou nenhum eleito. Descartar essas listas selecionaria a amostra pelo próprio resultado. Por isso a medida principal é a **diferença de taxas dentro da lista** (opção 1, escolhida pela autora), que exige apenas a presença dos dois grupos na lista.

## Variáveis: de → para

| Hoje (disputa) | Passa a (lista) | Papel | Wild |
|---|---|---|---|
| `tcv_g`: taxa de competitivas pelo voto de g − taxa do complemento | **`ltcv_g`**: o mesmo, entre as candidaturas da lista | **H4, principal** | sim |
| `tcg_g`: idem pela margem de gasto (2018–2026) | **`ltcg_g`** | H4 | sim |
| `tel_g`: taxa de eleitas de g − taxa do complemento | **`ltel_g`** | **H5, principal** | sim |
| `tcv/tel/tcg_br` (negras − brancas), `_hb` (mulheres negras − homens brancos) | `ltcv/ltel/ltcg_br`, `_hb` | comparações adicionais | sim |
| `pcv_g`, `pcg_g`: % das competitivas que são g | `lpcv_g`, `lpcg_g`: % das competitivas **da lista** que são g, TWFE ponderado pelo número de competitivas da lista no ano, painel desbalanceado | mecanismo: quem fica com os lugares competitivos (opção 2) | não |
| `cadeira_g`: % dos eleitos que são g | `lcadeira_g`: idem na lista, ponderado pelo número de eleitos | mecanismo | não |
| `inv_g`: razão das médias por candidatura | **`excesso_g` na lista**: % das transferências da lista para g − % das candidaturas da lista que são g | H2, investimento relativo | sim |
| `inv_c_g`, `inv_nc_g` | saem; o "para quem" fica com `recp_c/nc` e com a viabilidade ex ante (`recp_v/nv`, R/13), já na lista | — | — |

**Definições.** Competitiva pelo voto: eleita ou a menos de 0,1 QE do limiar (`margem_resultado.rds`, mesma amostra do `tcv` atual: aptas, com margem, sem DF). Competitiva pelo gasto: `margem_gasto_qe ≥ −0,1` (`margem_gasto_medidas.rds`, 2018–2026). As duas bases são ligadas à lista harmonizada (`partido_h`) por `ano` e `sq_candidato`, via `cand_ec111_2014_2026.rds`. Complemento: homens; não negras; todas as demais candidaturas.

**Ponderação.** Principal sem ponderação, com cada lista pesando igual, como nas demais variáveis de lista. Robustez: TWFE ponderado pelo número de candidaturas da lista em 2018, porque nas listas pequenas a taxa vale quase sempre 0 ou 100.

## Amostra (contagem de 24/11, painel balanceado do R/10, 799 listas)

Listas com os dois grupos presentes em todos os anos, que é a condição para a diferença de taxas existir:

| Comparação | Federal 2014–26 / 2018–26 | Estadual 2014–26 / 2018–26 |
|---|---|---|
| mulheres × homens | 273 / 328 (de 413) | 349 / 367 (de 386) |
| negras × não negras | 189 / 239 | 299 / 318 |
| negras × brancas | 187 / 238 | 296 / 314 |
| mulheres negras × demais | 137 / 188 | 248 / 283 |
| mulheres negras × homens brancos | 99 / 144 | 203 / 242 |

Saem as listas pequenas, uma seleção pelo tamanho e não pelo resultado. O número de listas de cada estimativa vai nas tabelas. O pré-teste de 2014 (`ltcv`, `ltel`) usa a amostra de 2014–2026. `ltcg` usa a de 2018–2026.

## Implementação

### Passo 1: R/10, variáveis de lista novas

- Montar `cand_m`: candidaturas de `margem_resultado.rds` (filtro atual) com `partido_h` e `lista` (junção com `cand_ec111` por `ano` e `sq_candidato`). Fazer o mesmo para `margem_gasto_medidas.rds` (`cand_g`). Conferir que ≥ 99% das candidaturas com margem recebem a lista.
- Agregar por lista e ano: `ltcv_*`, `ltel_*`, `ltcg_*` (com `dif_taxa()` do R/10), `lpcv_*`, `lpcg_*`, `lcadeira_*` com os seus pesos (n competitivas, n eleitos) e `excesso_*` (de `cand_ec111`).
- Juntar ao painel `listas` por `ano` e `lista`. As listas do painel não mudam.
- **Grade:** as linhas novas entram **no fim** da grade. As linhas da disputa ficam onde estão e continuam sendo estimadas, para que todas as linhas já existentes reproduzam exatamente as réplicas da rodada final de 24/11 (mesma regra usada pela sessão das categorias de receita). Os resultados na disputa ficam no CSV para comparação e saem do capítulo.
- `lpcv`, `lpcg`, `lcadeira`: TWFE `feols(y ~ i(ano, federal, ref = 2018) | id + ano, weights = ~n_den, cluster = ~uf_id)`, painel desbalanceado e sem wild, numa função `estimar_ponderado()` em `funcoes_estimacao.R`. É uma função nova e não altera `estimar()`.
- Robustez da ponderação pelo tamanho da lista para `ltcv`, `ltel` e `ltcg`: o mesmo TWFE, com peso igual ao número de candidaturas em 2018.

### Passo 2: R/10, conferências

- Todas as linhas antigas de `variaveis_principais_resultados.csv` idênticas às da rodada de 24/11 (ATT, EP, bandas, `p_wild`), com diff.
- Níveis por cargo das variáveis novas e conferência ATT = diferença das variações médias (o mesmo `stopifnot` atual).
- Taxas no intervalo [−100, 100] e `excesso` no intervalo [−100, 100].
- Ponderado sem ponderação ≈ CS (para `ltcv`, o TWFE sem peso deve reproduzir o CS, como já se confere).
- Comparação disputa × lista lado a lado (`output/competitividade_lista_vs_disputa.csv`): o sinal e a ordem de grandeza devem ser parecidos. Uma divergência é um achado e vai para o texto.

### Passo 3: R/11, tabelas

- `principal.md`: as linhas de competitividade, eleição e investimento passam a ser as de lista (`ltcv`, `ltcg`, `ltel`, `excesso`), com uma coluna "listas".
- `sucesso.md`: as diferenças de taxas passam para a lista. `lpcv`/`lcadeira` entram como bloco de mecanismo.
- Legendas: "Listas partido × UF" no lugar de "disputas UF × cargo".
- `transferencias_cargo.md` (razão por candidatura, totais nacionais) é descritiva e fica como está.
- Diff das outras tabelas, que devem ficar iguais byte a byte.

### Passo 4: texto (só depois de a autora ver os números)

Seção de Variáveis (`tbl-variaveis-ec111`: coluna "unidade" toda "lista", com justificativa de um parágrafo, o da Motivação acima), Métodos (unidade de análise e amostra por comparação), H4 e H5, a "aproximação das mulheres pelo voto" (hoje explicada pela queda da taxa dos homens na disputa; conferir se o mesmo vale dentro das listas), os limites e a Introdução, se algum número mudar. Combinar os trechos com a outra sessão antes de editar o `.qmd`.

## Rodadas

- Teste: `BITERS=200 WILD=199`. Final: `BITERS=25000 WILD=1999`, com cerca de 27 min do R/10 atual mais as linhas novas (estimativa: +10 a 15 min).
- Ordem: R/10 → R/13 (só confere ATTs do R/10; não muda) → R/11 → render.

## Riscos

1. **Ruído nas taxas de listas pequenas.** Os IC devem alargar em relação à disputa. A robustez ponderada mostra quanto do resultado vem das listas grandes.
2. **Mulheres negras × homens brancos no federal:** 99 listas em 2014–2026. Pode não haver potência, e o texto diria isso.
3. **A "aproximação" das mulheres pelo voto** (+3 a 4 p.p. na disputa) vinha da expansão de candidaturas masculinas fracas. Dentro da lista, o resultado pode mudar de tamanho ou de sinal, e a interpretação teria de ser refeita.

## Decisões para a autora

1. **Robustez ponderada pelo tamanho da lista** (n de candidaturas em 2018): incluir? *Recomendação:* sim, só no apêndice ou no CSV.
2. **Resultados na disputa:** saem do capítulo, ficam no CSV. Mencionar no texto que a disputa dá resultado parecido (ou não)? *Recomendação:* uma frase nos limites e uma coluna no apêndice, se houver divergência.
