# Competitividade da candidatura medida pelo gasto

**Status:** exploração ativa (etapa 1 concluída em 2026-09-28)

## Objetivo

Repetir parte das análises da tese com uma medida de competitividade da **candidatura** que não dependa do resultado (votos), e sim do **volume de gasto de campanha**. Pergunta de fundo: o aumento de votos das mulheres candidatas a deputada (federal e estadual) entre 2018 e 2022 foi maior entre candidaturas mais ou menos competitivas?

Requisito: a medida precisa ser comparável entre Deputado Federal e Deputado Estadual, em todas as UFs.

## Medidas

| Variável | Definição | Compara cargos? | Compara UFs? | Compara anos? |
|---|---|---|---|---|
| `pct_teto` | gasto / limite legal do cargo | sim | **não** (limite igual em todas as UFs) | **não** (gasto real cresceu muito em 2022) |
| `razao_min` | gasto / menor gasto entre eleitos (ano × cargo × UF) | sim | sim | sim |
| `razao_p10` | gasto / p10 do gasto dos eleitos (ano × cargo × UF) | sim | sim | sim |
| `pctl_uf` | percentil do gasto (ano × cargo × UF) | sim | sim | sim |

- **p10 do gasto dos eleitos**: ordenando os eleitos de uma disputa (ano × cargo × UF) do menor para o maior gasto, é o valor de gasto que separa os eleitos em dois grupos: 10% deles gastaram menos que esse valor e 90% gastaram mais. Ex.: federal SP 2022, 70 eleitos, p10 ≈ R$ 534 mil — cerca de 7 eleitos gastaram menos e 63 gastaram mais. `razao_p10 = 0,5` = gastou metade disso.
- **Gasto** = despesas contratadas da prestação final do TSE, **excluindo** "Doações financeiras a outros candidatos/partidos". Candidatura apta sem despesa entra com gasto 0.
- **Limites legais** (iguais em todas as UFs): 2018 — R$ 2,5 mi (federal) e R$ 1,0 mi (estadual), Lei 13.488/2017; 2022 — R$ 3.176.572,53 e R$ 1.270.629,01, Portaria TSE 647/2022 (2018 + IPCA).
- `razao_min` transpõe para o gasto o critério de Wylie, dos Santos & Marcelino (2019), que usam votos < 1% do "quociente mínimo" (votos do eleito menos votado no distrito).

## Achados da etapa 1

1. `pct_teto` não serve como medida principal: a mediana de gasto dos eleitos (federal, 2022) varia de 11% a 71% do limite entre UFs, e sobe de 25% (2018) para 40% (2022) do limite com o limite só corrigido pelo IPCA.
2. `razao_min` é instável: há eleitos sem despesa e, em 14 combinações ano × cargo × UF, o eleito que menos gastou ficou abaixo de 0,5% do limite.
3. `razao_p10` é a medida mais estável entre cargos e anos. Corte 0,5 → 87–92% das competitivas pelo voto acima; 78–89% das não competitivas abaixo. `pctl_uf ≥ 75` tem desempenho parecido (robustez).
4. As mulheres gastam proporcionalmente mais que os homens em todos os grupos de resultado — inclusive entre as não competitivas pelo voto (estadual 2022: mediana 1,6% vs. 0,9% do limite). Uma medida pelo gasto classifica como competitivas mais mulheres sem votos (provável efeito da cota do FEFC); isso precisa ser discutido.
5. Repasses a outras candidaturas vêm sobretudo de homens competitivos a federal (44% dos eleitos em 2018 repassaram; 12% do gasto bruto). Entre mulheres não competitivas os repasses são pequenos (2–3% do gasto).

## Achados da etapa 2 — distribuição por gênero, raça e resultado (script 02)

Régua: `razao_p10`; patamar de referência 0,5× o p10 do gasto dos eleitos na UF. Sem médias: quantis, distribuições acumuladas e % acima do patamar (IC de Wilson). "Resultado" continua sendo a classificação **pelo voto** (≥ 10% do QE), usada só para descrever.

1. **Mulheres e candidaturas negras se aproximaram do patamar entre 2018 e 2022**, sobretudo por raça e no estadual. Lacuna no % acima de 0,5× (pp): gênero — federal −7,2 → −4,4; estadual −2,3 → −0,3. Raça — federal −13,4 → −9,1; estadual −16,4 → −7,5.
2. Maior avanço: mulheres negras (federal 12% → 17%; estadual 23% → 31%) e homens negros no estadual (20% → 28%). Homens brancos recuaram levemente (federal 31% → 29%; estadual 40% → 38%).
3. Parte da aproximação ocorre **entre não competitivas pelo voto**: a mediana de `razao_p10` das mulheres não competitivas dobrou (federal 0,033 → 0,084; estadual 0,088 → 0,17), mais que a dos homens. Mais gasto sem voto correspondente (provável efeito da cota do FEFC).
4. Entre eleitos e competitivos, a distribuição se comprimiu em 2022 para todos os grupos (a vantagem relativa de gasto das mulheres eleitas caiu: estadual, mediana 6,3 → 3,5).

## Achados da etapa 3 — de onde veio o crescimento da votação das mulheres (script 03)

Voto medido como participação nos votos nominais do cargo (soma das UFs). Participação das mulheres: federal 16,2% → 21,1% (+4,9 pp); estadual 18,7% → 20,3% (+1,6 pp).

1. **Todo o ganho veio de mulheres com gasto ≥ 0,5× o patamar.** Federal: faixa ≥ 1× +3,9 pp e 0,5–1× +1,1 pp; faixas abaixo de 0,1× perderam participação. Estadual: ≥ 1× +1,1 pp; 0,5–1× +0,6 pp.
2. **O ganho veio da renovação, não de candidatas que repetiram a disputa aumentando o gasto.** Federal: novas +12,9 pp, saíram −6,9 pp, permaneceram −1,1 pp (as que "cruzaram o patamar" contribuíram ~0 — são só 34). Estadual: novas +11,9, saíram −10,4, permaneceram +0,1.
3. Entre as novas candidatas de 2022, as que gastaram ≥ 0,5× o patamar são 17% (federal) e 30% (estadual) delas, mas concentram 77% e 82% da votação das novas.
4. Associação, não efeito: partidos dirigem recursos a candidaturas que já esperam ser viáveis.

## Achados da etapa 4 — DiD federal × estadual, 2018 → 2022 (scripts 04–06)

Desenho de Fonseca, Thomé & Guedes-Neto (2026): tratado = Deputado Federal (votos em dobro, EC 111/2021); controle = Estadual, mesma UF. Unidade: lista partido × UF (1.219 listas, painel balanceado, sem DF). DiD 2×2 via `did` (DR sem covariáveis = TWFE, checado no código). Plano: `quality_reports/plans/2026-09-28_competitividade-gasto-did.md`.

Medidas e patamar de viabilidade: m2 = % do limite (≥ 5%); m6 = recursos do partido ÷ divisão igualitária entre as candidaturas do partido no cargo e UF (≥ 1×); m8 = gasto ÷ menor gasto dos eleitos com gasto ≥ 1% do limite (≥ 50%).

Efeitos (pp, listas sem ponderação; ponderado por votos da lista em 2018 no CSV):

- **Mulheres — recursos:** % dos recursos do partido para mulheres +15,7 (IC 11,2 a 20,2); % dos recursos para mulheres **viáveis** +9,3 a +13,9 nas três medidas (todos significativos; ponderado: +14 a +18).
- **Mulheres — candidaturas viáveis:** % das candidaturas que são mulheres viáveis ≈ 0 (m2 +1,1; m6 +1,1; m8 −2,4, n.s.). → Mais dinheiro para as mulheres já viáveis, não mais mulheres viáveis.
- **Mulheres — votos:** % dos votos da lista +5,2 (IC 1,7 a 8,7), mesma direção de Fonseca et al. (+4,4). Por faixa (m8): o ganho vem das faixas baixas (< 10%: +2,0; 10–25%: +2,3); na faixa ≥ 100%, +0,0. Ponderado pelo tamanho da lista, o ganho desloca para ≥ 100% (+3,7, n.s.).
- **Negras/os:** sem efeito sobre votos (+2,0, n.s.) nem sobre recursos (+4,0, n.s.); a parcela de candidaturas negras viáveis caiu no federal em relação ao estadual (m8: −6,7) e os votos migraram da faixa ≥ 100% (−4,7) para < 10% (+4,7).
- **Recursos por fonte (etapa 6, 2018 → 2022):** parcela dos recursos da lista destinada a mulheres — todas as receitas **+7,5** (IC 3,8 a 11,1; base 25%), recursos públicos FEFC + FP **+9,6**, transferências do partido **+15,7**; para mulheres viáveis, todas as receitas +3,0 a +6,1 (m8 n.s. sem ponderação), públicos +5,3 a +8,3, partido +9,3 a +13,9. O efeito cresce quanto mais a fonte é controlada pelo partido. Negras/os: todas as receitas +2,7 (n.s.), públicos +4,9, partido +4,0 (n.s.); para negras/os viáveis (m8), −4,2 a −7,0. Comparável a Fonseca et al. (+12,3% na parcela do orçamento de campanha para mulheres; sem efeito para negras/os).
- **Leitura:** o incentivo está associado a mais recursos para mulheres, inclusive para as já viáveis, sobretudo nos recursos que o partido controla, mas não a mais mulheres viáveis. O ganho de votos da lista típica, decomposto por faixa de **gasto**, veio de mulheres com gasto baixo pelas medidas de gasto total (m8: < 25% do menor gasto dos eleitos; m2: 1–5% do limite), e ficou em zero na faixa competitiva de m8; pela medida de recursos do partido (m6) o ganho é mais espalhado, inclusive entre as mais financiadas (≥ 5×: +1,9). Fonseca et al. encontram padrão análogo com faixas de **voto**. Não há evidência de que o ganho de votos se deva a mais mulheres terem se tornado viáveis pelos recursos. Para recursos não há teste de pré-tendência válido (ver etapa 5).
- **Limites:** placebo com 2014 na etapa 5; tratamento no nível do cargo; muitos resultados (comparações múltiplas); faixas são resultado, não condição.

## Achados da etapa 5 — placebo com 2014 (script 07)

DiD com três eleições (`did`, base variável): placebo = federal × estadual de 2014 para 2018 (antes da EC 111); efeito = de 2018 para 2022. 1.116 listas presentes nas três eleições (739 com recursos do partido nas três). Só m6 e m8 (sem limite legal em 2014). Prestação de contas de 2014: `prestacao_final_2014.zip` (TSE, baixado pelo navegador; o CDN recusa clientes que não sejam navegador).

| Resultado (pp) | Placebo 2014→2018 | Efeito 2018→2022 | Leitura |
|---|---|---|---|
| Mulheres: votos da lista | −0,8 (n.s.) | **+5,2*** | passa no placebo — efeito sobre votos é crível |
| Mulheres: recursos do partido | **−22,6*** | +15,5* | **falha** — tendência oposta antes; efeito não atribuível à EC 111 |
| Mulheres: recursos para viáveis (m6/m8) | −22,2* / −19,7* | +13,0* / +11,1* | **falha** (idem) |
| Mulheres: candidaturas viáveis (m6/m8) | −3,5* / −1,9 | +1,9 / −1,7 | sem efeito |
| Mulheres: votos m8 10–25% | −0,9* | +2,4* | ganho em faixa baixa; placebo pequeno, de sinal oposto |
| Negras/os: votos da lista | −1,6 (n.s.) | +1,9 (n.s.) | sem efeito |
| Negras/os: candidaturas viáveis m8 | −0,7 (n.s.) | **−6,6*** | passa no placebo — queda crível |
| Negras/os: recursos para viáveis m8 | +1,1 (n.s.) | **−6,3*** | passa no placebo |
| Negras/os: votos m8 < 10% / ≥ 100% | −5,7* / +4,0 | +4,2* / −5,0* | **falha** — padrão de reversão, não efeito |

(* IC 95% não inclui zero.)

**Consequências para as conclusões da etapa 4:**
1. O aumento dos votos das mulheres no federal (+5,2 pp) resiste ao placebo.
2. **Decisão da autora (2026-09-28): 2014 não serve de referência de tendência para recursos.** O fim da doação empresarial (2015) é uma mudança muito maior que a cota de recursos públicos; o placebo de recursos (−22,6 pp) compara regimes de financiamento diferentes e não é interpretado. Os resultados de recursos ficam como DiD 2×2 sem pré-teste (etapa 4).
3. Para candidaturas negras, a queda de viáveis no federal (−6,6) e dos recursos para viáveis (−6,3) resiste ao placebo; o deslocamento de votos entre faixas, não.

## Literatura consultada (2026-09-28)

- Nenhum trabalho encontrado mede competitividade **da candidatura** pelo gasto comparando federal e estadual. A literatura brasileira classifica por voto: Wylie, dos Santos & Marcelino (2019, *Opinião Pública* 25(1)); Fabris et al. (2020, *RBPP*, 10% do QE); Fonseca, Thomé & Guedes-Neto (2026, *Electoral Studies* 101, também por % da votação).
- Número efetivo de candidatos calculado com receitas: Thomsen (2022, *APSR* 117(2)) — nível da disputa, EUA.
- Avelino & Biderman: sem medida de competitividade por gasto; o mais próximo é Avelino, Biderman & Desposato (2021, *BPSR* 16(1)), incumbência com regressão descontínua.
- Teto de gastos como denominador: Avis, Ferraz, Finan & Varjão (2022, *AEJ: Applied* 14(4)).

## Como rodar

A partir da raiz do repositório, nesta ordem:

```
Rscript explorations/competitividade-gasto/R/01_competitividade_gasto.R
Rscript explorations/competitividade-gasto/R/02_distribuicao_gasto_grupos.R
Rscript explorations/competitividade-gasto/R/03_voto_por_faixa_gasto.R
Rscript explorations/competitividade-gasto/R/04_receitas_partido.R      # requer data/raw/prestacao_de_contas_eleitorais_candidatos_{2018,2022}.zip
Rscript explorations/competitividade-gasto/R/05_medidas_perfil_decomposicao.R
Rscript explorations/competitividade-gasto/R/06_did_recursos_votos.R    # requer pacotes did e DRDID
Rscript explorations/competitividade-gasto/R/07_placebo_2014.R          # requer data/raw/prestacao_final_2014.zip e bases de 2014
```

Entradas em `data/raw/` (copiadas do projeto de análise da tese; não versionadas): `despesas_categorizadas_dep_{2018,2022}.rds` (gerado por `Analise_Despesas_Genero_Raca.R`), `candidatos{2018,2022}.rds`, `candidatos_estadual_{2018,2022}.rds`, `eleitos_e_compet_{2018,2022}_df.rds`, `eleitos_e_compet_est_{2018,2022}_df.rds`.

Saídas: `output/` (tabelas `.csv` e figuras `.png`/`.pdf`) e `data/processed/competitividade_gasto_cand.rds` (uma linha por candidatura apta, sem CPF; não versionado).

## Próximos passos

- [ ] Escolher o corte de `razao_p10` (entre 0,25 e 0,5) e fixar `pctl_uf` como robustez
- [ ] Modelar a variação dos votos das mulheres 2018 → 2022 por faixa de competitividade pelo gasto
- [ ] Comparar com a classificação por voto (≥ 10% do QE) já usada na tese
