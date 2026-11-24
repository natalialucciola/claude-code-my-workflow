# Plano de implementação: item 1, viabilidade *ex ante* (Cap. 4, EC 111)

**Status:** APROVADO (D1–D4 em 24/11). Passos 1, 3 e 4 feitos; Passo 2 (R/10 usar funcoes_estimacao.R) adiado por coordenação com a sessão das categorias de receita; Passo 5 aguarda a autora
**Data:** 2026-11-24
**Plano-mãe:** `quality_reports/plans/2026-11-24_cap4-cacaniquel-viabilidade-concentracao.md` (item 1: 1a e 1b; as Etapas 0–3 daquele plano, restritas ao item 1)
**Exploração:** `explorations/ec111-did-2026/`
**Fora deste plano:** item 3 (concentração, C1–C4), que fica para um plano próprio e reaproveita as Etapas 2 e 3 daqui.

---

## Etapa 0 já rodada (contagem exploratória de 24/11, script descartável fora do repositório)

Ligação por CPF e, na falta dele, pelo título (`consulta_cand_{ano}.zip`, cargos 6 e 7, valores `-4`/`-1` tratados como ausentes). V1–V3 em *t − 4* a partir de `margem_resultado.rds`, com V3 em qualquer um dos dois cargos de deputado. **Todas as 65.659 candidaturas aptas de 2018–2026 têm identificador.**

Candidaturas viáveis ex ante (todas as candidaturas aptas, sem DF):

| Ano | Cargo | V1 incumbentes | V2 outro cargo | Viáveis (V1 ∪ V2 ∪ V3) | % das candidaturas |
|---|---|---:|---:|---:|---:|
| 2018 | Federal | 374 | 100 | 614 | 8,2 |
| 2022 | Federal | 420 | 119 | 806 | 8,7 |
| 2026 | Federal | 404 | 93 | 682 | 9,7 |
| 2018 | Estadual | 731 | 7 | 1.070 | 6,7 |
| 2022 | Estadual | 765 | 5 | 1.135 | 7,5 |
| 2026 | Estadual | 811 | 8 | 1.127 | 10,6 |

Por grupo (viáveis por disputa = viáveis ÷ 26 UFs):

| Grupo | Cargo | Viáveis 2018 / 2022 / 2026 | Por disputa | UFs com zero viáveis | % das transf. do grupo às viáveis ex ante | idem, às competitivas ex post |
|---|---|---|---|---|---|---|
| Mulheres | Federal | 71 / 129 / 136 | 2,7 / 5,0 / 5,2 | 5 / 1 / 3 | 36,3 / 23,7 / 28,6 | 46,3 / 26,9 / 31,4 |
| Mulheres | Estadual | 131 / 173 / 200 | 5,0 / 6,7 / 7,7 | 0 / 0 / 0 | 19,1 / 18,3 / 23,8 | 34,3 / 29,3 / 32,1 |
| Pessoas negras | Federal | 154 / 242 / 189 | 5,9 / 9,3 / 7,3 | 2 / 0 / 0 | 51,8 / 32,1 / 35,2 | 54,6 / 29,7 / 34,1 |
| Pessoas negras | Estadual | 311 / 384 / 373 | 12,0 / 14,8 / 14,3 | 1 / 1 / 1 | 25,2 / 21,3 / 26,7 | 36,6 / 31,6 / 32,1 |
| Mulheres negras | Federal | 18 / 43 / 44 | 0,7 / 1,7 / 1,7 | **16** / 10 / 7 | 28,3 / 16,6 / 21,8 | 37,6 / 22,2 / 22,6 |
| Mulheres negras | Estadual | 42 / 56 / 81 | 1,6 / 2,2 / 3,1 | 6 / 5 / 4 | 14,1 / 13,5 / 21,8 | 26,9 / 23,0 / 25,2 |

Matriz 2 × 2 das transferências às mulheres (% do total delas, por ano e cargo):

| Viável ex ante → competitiva ex post | Fed. 2018 | Fed. 2022 | Fed. 2026 | Est. 2018 | Est. 2022 | Est. 2026 |
|---|---:|---:|---:|---:|---:|---:|
| Viável → competitiva | 27,1 | 16,2 | 21,4 | 16,7 | 15,4 | 20,5 |
| Viável → não competitiva (investimento que falhou) | 9,2 | 7,5 | 7,2 | 2,4 | 2,9 | 3,3 |
| Não viável → competitiva (aposta que deu certo) | 19,2 | 10,8 | 10,0 | 17,6 | 13,9 | 11,6 |
| **Não viável → não competitiva (caça-níquel)** | **44,5** | **65,5** | **61,4** | 63,3 | 67,8 | 64,6 |

**O que a Etapa 0 diz:**

1. **A regra de parada do plano-mãe dispara**: mulheres federais têm 2,7 viáveis por disputa em 2018 (limiar de ~5), e mulheres negras têm 0,7, com 16 UFs zeradas. Resolvido pela D1 (medir na lista, sem divisão pelo número de viáveis).
2. **O sinal é forte e não vem da composição.** A fatia das mulheres viáveis cai cerca de 12 p.p. no federal em relação ao estadual (DiD bruto: −11,8 em 2022, −12,4 em 2026), enquanto o número de mulheres viáveis federais *sobe* (71 → 129). Por candidatura, a razão viável/não viável das transferências cai de 18,4 para 7,6 no federal e de 8,8 para 6,4 no estadual.
3. **A célula caça-níquel cresce 21 p.p. no federal** (44,5 → 65,5) e 4,5 p.p. no estadual. A célula "investimento que falhou" é pequena e cai, de modo que a leitura ex post não estava confundindo intenção com ineficácia.
4. **Ressalva sobre o ponto de partida:** o federal de 2018 é muito mais concentrado nas viáveis que o estadual (36 contra 19). Sem pré-teste para as transferências, não se distingue um 2018 atípico de um efeito. Isso precisa constar do texto.

---

## Decisões da autora (24/11)

| # | Decisão |
|---|---|
| D1 | **Medir na lista.** Decomposição aditiva `recp_v_g + recp_nv_g = rec_partido_g` (idem gasto e votos), três grupos, mesmo painel balanceado do R/10. Sem medidas na disputa (fatias `fc`/`fv` e razão por candidatura saem do DiD). O 1a usa a decomposição já existente (`recp_c_g`) com a coluna "esperado". A razão viável/não viável por candidatura fica só como descritivo nacional (ressalva de composição) |
| D2 | **2022 e 2026 medidos da mesma forma**, como as demais medidas do capítulo (2026 classificado com os resultados de 2022) |
| D3 | V3 em qualquer cargo de deputado (principal); "mesmo cargo" e "só V1" como robustez |
| D4 | Esperado = $s_{2018} 	imes 	ext{ATT}_{	ext{total}}$, com $s_{2018}$ = média federal de 2018 de `recp_c_g` (ou `recp_v_g`) ÷ média federal de 2018 de `rec_partido_g`, nas listas balanceadas; sem erro-padrão |

---

## Implementação

Rodar da raiz do repositório, com os dados do checkout principal (`data/` não é versionado). O worktree precisa de `data/processed/` e `data/raw/` (cópia ou junção). Testes com `BITERS=200 WILD=199`; rodada final com `BITERS=25000 WILD=1999`, como no R/10 (decisão de 22/11).

### Passo 1: `R/12_viabilidade_ex_ante.R` (classificação)

- `ler_ids(ano)`: lê `consulta_cand_{ano}_BRASIL.csv` de dentro do zip (cargos 6 e 7, todas as situações) e devolve `ano, sq_candidato, cpf, titulo, pessoa = coalesce(cpf, "T" + titulo)`. CPF com 11 dígitos (preenchido com zeros à esquerda, como `cpf11()` do R/05).
- `ant`: de `margem_resultado.rds` (cargos 6 e 7, **todas** as candidaturas com margem, aptas ou não), por pessoa e eleição: `eleito_fed`, `eleito_est`, `perto` (não eleita e `margem_qe ≥ −0,1`), `perto_mesmo_cargo`. Deslocar `ano + 4`.
- Juntar a `cand_ec111_2014_2026.rds` (2018–2026) e criar `V1`, `V2`, `V3`, `V3_mesmo_cargo`, `viavel` (principal), `viavel_v1` (robustez só V1) e `viavel_mc` (robustez D3).
- Salvar `data/processed/viabilidade_ex_ante.rds` (chave `ANO, DS_CARGO, sq_candidato`).
- Saídas: `output/viabilidade_tamanhos.csv` (as tabelas da Etapa 0, já com contagens V3 corretas) e `output/viabilidade_matriz_2x2.csv` (três grupos, fatias de transferências, gasto e votos).

**Verificações (`stopifnot` ou mensagem):**

- Nenhuma chave duplicada, e 100% das candidaturas com `pessoa`.
- Concordância CPF × título: entre as pessoas com os dois, mesmo CPF ⇔ mesmo título em ≥ 99%. Pares discordantes vão para o log.
- Concordância com o `mapa_cpf` do R/05 da competitividade (CPF de `candidatos{ano}.rds`): ≥ 99% das candidaturas de 2014–2022.
- Incumbentes que voltam a concorrer: 374 a 420 no federal, contra cerca de 400 deputados que buscam reeleição a cada eleição. Entre eles, reeleitos (`eleito == 1`) entre ~230 e 300. *Correção do plano-mãe:* o intervalo de ~250 a 300 era de reeleitos, não de candidaturas incumbentes, e o campo `ST_REELEICAO` não existe no `consulta_cand` de 2014–2026 (conferido).
- Uma pessoa eleita em *t − 4* não pode ter V3 = verdadeiro.

### Passo 2: `R/funcoes_estimacao.R` (extração sem mudança de resultado)

- Mover `webb`, `wild_p()` e `estimar()` do R/10 para o novo arquivo. Parâmetros que hoje são globais (`biters`, `n_wild`) passam a argumentos com padrão lido do ambiente.
- O R/10 passa a usar `source()` no arquivo.
- **Verificação:** rodar o R/10 com `BITERS=200 WILD=199` antes e depois da extração, com a mesma semente, e comparar `variaveis_principais_resultados.csv` (diff vazio). Não refazer a rodada final do R/10.

### Passo 3: `R/13_cacaniquel_viabilidade.R` (medidas e estimação)

Entradas: `painel_listas_2014_2026.rds`, `cand_ec111_2014_2026.rds` e `viabilidade_ex_ante.rds`.

**Lista** (mesmas chaves e mesmo filtro do R/02: `ANO, DS_CARGO, federal, uf, partido_h`, `votos_lista > 0`; juntar ao painel por `ano` e `lista` para herdar `id`/`uf_id`):

| Variável | Definição | Anos |
|---|---|---|
| `recp_v_g`, `recp_nv_g` | % das transferências da lista para g viáveis / não viáveis ex ante | 2018–2026 |
| `gasto_v_g`, `gasto_nv_g` | idem, gasto | 2018–2026 |
| `voto_v_g`, `voto_nv_g` | idem, votos | 2018–2026 (sem 2014: exigiria 2010) |
| `recp_v1_g`, `recp_nv1_g` | robustez: viável = só V1 | 2018–2026 |

**Estimação:** `estimar()` com `anos_rec`, base 2018, erros por UF. Wild bootstrap em `recp_v_g` e `recp_nv_g` (testes principais do item 1); as demais partes (gasto, votos, robustez) sem wild, como `recp_c`/`recp_nc` no R/10.

**Checagens no código:**

- `recp_v_g + recp_nv_g == rec_partido_g` em cada lista e ano (tolerância 1e-8), e o mesmo para gasto e votos.
- ATT(`recp_v_g`) + ATT(`recp_nv_g`) = ATT(`rec_partido_g`), e este ATT bate com o de `variaveis_principais_resultados.csv`.
- ATT de `recp_c_g` recalculado bate com o R/10. Isso confere que a junção ao painel não mudou a amostra.
- Níveis por cargo de `recp_v_mulher` conferem com a diferença das variações médias (mesma conferência do R/10).
- Coluna "esperado" (D4) calculada com os níveis federais de 2018 das mesmas listas balanceadas.

**Saídas:** `output/cacaniquel_viabilidade.csv` (ATTs) e `output/cacaniquel_viabilidade_niveis.csv` (níveis por cargo e "esperado").

### Passo 4: tabelas para o capítulo (`R/11`, novo bloco)

- **`tbl-viabilidade-ec111`**, com linhas para mulheres, pessoas negras e mulheres negras e colunas: nível federal de 2018, ATT 2022, ATT 2026 e esperado pela divisão de 2018. Dois blocos: (a) competitivas ex post, que é a base de comparação para a `tbl-decomposicao-ec111` atual; (b) viáveis ex ante.
- **`tbl-matriz-viabilidade-ec111`**: a matriz 2 × 2 descritiva de mulheres, federal e estadual, 2018, 2022 e 2026 (D2).
- Arquivos `chapters/_tabelas-cap3/viabilidade.md` e `matriz_viabilidade.md`. Render do capítulo para conferir.

### Passo 5: texto (só depois de a autora ver os números)

Pontos a revisar, sem redação antecipada: o parágrafo da previsão (l. 63) ganha a previsão sobre a fatia das viáveis; "Onde ficaram os ganhos" (l. 243–247) ganha a tabela nova e a matriz; o limite "Medidas de competitividade" (l. 301) deixa de dizer que a classificação é só ex post; a Discussão (l. 283) passa a se apoiar na célula caça-níquel. A ressalva do ponto de partida (federal de 2018 mais concentrado e sem pré-teste) entra nos limites.

---

## Ordem, custo e commits

| Passo | Tempo estimado | Commit |
|---|---|---|
| 1 | curto (a contagem rodou em menos de 1 min) | `feat(ec111): classificação de viabilidade ex ante (R/12)` |
| 2 | 2 rodadas de teste do R/10 | `refactor(ec111): estimar() e wild_p() em funcoes_estimacao.R` |
| 3 | teste rápido; rodada final ~poucas dezenas de variáveis × 25.000 réplicas | `feat(ec111): decomposição por viabilidade ex ante (R/13)` |
| 4 | render do capítulo | `feat(cap3): tabelas de viabilidade ex ante` |
| 5 | depois da revisão da autora | `revise(cap3): …` |

README da exploração atualizado no Passo 3 (nova seção "Viabilidade ex ante", com achados e veredito graduado).
