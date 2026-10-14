# Plano — DiD da EC 111/2021 na geografia do voto (QL por município), a partir de Calzavara

**Status:** DRAFT (2026-10-14) — aguardando aprovação da autora. Decisões marcadas ASSUMIDO podem ser revistas.
**Branch:** `worktree-did-ec111-ql-municipio`
**Exploração proposta:** `explorations/ec111-did-ql-municipio/`
**Antecessores:** `2026-10-13_did-ec111-2026.md` (DiD no nível da lista) · `2026-10-13_ql-voto-2026-cap6.md` (QL do voto 2018–2026; branch `worktree-ql-voto-2026`, **ainda não incorporada à main**)
**Fonte:** Calzavara, Luana. Tese de doutorado, Cap. 3 "Fragmentação na arena eleitoral" — `master_supporting_docs/supporting_papers/Tese - Luana Calzavara.pdf`

---

## 1. O que a tese de Calzavara faz (e o que não faz)

**Não há diferenças em diferenças na tese.** O desenho geográfico do Cap. 3 é:

| Elemento | Calzavara (Cap. 3) |
|---|---|
| Pergunta | A filiação de deputados migrantes expande o partido para territórios novos? |
| Unidade geográfica | Região Geográfica Imediata (RGI, IBGE 2017; 510 regiões). Ela descarta o município por ser "detalhista demais" para medir sobreposição (p. 96–97, citando Silva & Davidian 2013; Avelino, Biderman & Silva 2016) |
| Medida de base | QL do candidato na RGI = (votos do candidato na RGI ÷ votos totais do candidato) ÷ (eleitorado da RGI ÷ eleitorado da UF); base = QL > 1. Testa limiares 2 e 3 (p. 100–102) |
| Painel | partido × RGI × eleição, Dep. Federal, 1998–2022 |
| 3.3 Sobreposição | "Conflito entre bases": o migrante entra num partido que já tem eleito com QL > 1 na mesma RGI? → 10,9% dos casos (Tab. 1) |
| 3.3.1 Expansão | Transição entre eleições consecutivas na RGI (o partido passa a ter, mantém ou perde candidato com QL > 1), com e sem migrante: crescimento de 29% → 62,9% (Tab. 2). **É a comparação mais próxima de um DiD**: antes/depois × com/sem migrante, mas descritiva |
| 3.4 Votação | VD = % de votos do partido na RGI; tratamento = presença de migrante; modelo de efeitos mistos (RGI em UF, eleição em período); efeito ≈ +10 p.p. (Gráf. 20). O resumo fala em "efeitos fixos" e o texto em "efeitos mistos" |
| 3.5 Fragmentação | Regressão linear simples: % dos votos do partido vindos de RGIs de migrantes → votação total |

**O que aproveitar dela:** (i) o **painel partido × território × eleição** como unidade; (ii) a **presença de uma base (QL > 1)** como variável de resultado, e não só o QL contínuo; (iii) a leitura **extensiva** (o partido ganha uma base num território onde não tinha) contra a **intensiva** (o partido fortalece uma base que já tinha); (iv) o percentual de votos do partido no território como resultado secundário. **O que não copiar:** a estratégia de identificação. O modelo de efeitos mistos com "presença de migrante" não separa seleção de efeito; aqui o DiD Federal × Estadual faz esse papel.

## 2. Pergunta

A EC 111/2021 (votos em mulheres e em pessoas negras contam em dobro na distribuição do FEFC/FP; **só Câmara dos Deputados**; 2022–2030) mudou a **geografia do voto** das candidaturas de mulheres e de pessoas negras **dentro dos partidos**? Em particular:

1. **Margem extensiva:** os partidos passaram a ter candidaturas de g com base eleitoral (QL > 1) em mais municípios?
2. **Margem intensiva:** subiu a fatia do voto do partido no município que vai para candidaturas de g?
3. **Sobreposição (ponte com o Cap. 6):** as novas bases de g aparecem em municípios "livres" (sem base de incumbente do partido) ou em municípios onde a lista já tem base de incumbente?

## 3. Desenho

- **Unidade:** partido × município × cargo × ano. Partido harmonizado para a sigla de 2026, como no DiD de listas.
- **Tratado:** Deputado Federal a partir de 2022 (`gname = 2022`). **Controle:** Deputado Estadual, mesmo partido e mesmo município, nunca tratado (`gname = 0`). DF fora.
- **Períodos:** 2014 e 2018 (pré) · 2022 e 2026 (pós). 2014 é necessário para o pré-teste.
- **Ganho do nível municipal:** cada partido × município aparece nos dois cargos. Assim, efeitos fixos **partido × município × ano** absorvem choques locais comuns aos dois cargos (prefeito do partido eleito em 2020/2024, mudança de liderança local, EC 133/2024 de cotas raciais etc.). O contraste passa a ser **dentro do mesmo partido, no mesmo município e no mesmo ano**, o que é mais forte que o DiD de listas.
- **Estimadores:**
  - Principal: `did::att_gt(yname, tname = ano, idname = id_pmc, gname, control_group = "nevertreated", base_period = "universal", panel = TRUE)`, com bootstrap multiplicador, bandas uniformes e `clustervars` na **lista (partido × UF × cargo)**, nível em que o tratamento opera. Agregações `dynamic` (e = 0 → 2022; e = 4 → 2026) e `group`.
  - Equivalente com efeitos fixos locais: `fixest::feols(y ~ i(ano, federal, ref = 2018) | id_pmc + partido^municipio^ano, cluster = ~lista)`. Sem covariáveis e com um só grupo tratado, o `att_gt` deve coincidir com o TWFE sem `partido^municipio^ano`; a versão com esses efeitos fixos é a especificação de robustez mais exigente.
- **Pesos:** não ponderado (cada partido × município conta igual) e ponderado pelos votos do partido no município em 2018 (o efeito "por eleitor").

## 4. Resultados (g = mulheres ou pessoas negras)

### 4.1 Resultado principal — entrada em território novo, decomposta por grupo (DECIDIDO 2026-10-14)

Pergunta da autora: *o partido avançou sobre territórios novos e esse avanço ocorreu por candidaturas de mulheres ou de pessoas negras?* Variável de transição, como na Tab. 2 de Calzavara, definida em **todo** o painel (sem condicionar ao conjunto em risco):

| Variável | Definição (partido × município × cargo, eleição t) |
|---|---|
| `nova_base` | 1 se o partido **não tinha** base no município em t−1 e **tem** base em t |
| `nova_base_g` | 1 se `nova_base` = 1 e ≥ 1 das bases novas é de candidatura de g |
| `nova_base_naog` | 1 se `nova_base` = 1 e nenhuma base nova é de g |

- **Identidade:** `nova_base = nova_base_g + nova_base_naog`, portanto **ATT(nova_base) = ATT(nova_base_g) + ATT(nova_base_naog)**. O primeiro termo responde se o partido avançou; a parcela ATT(nova_base_g) ÷ ATT(nova_base) responde quanto do avanço veio de g. A decomposição é linear e não depende de uma razão que fica indefinida quando não há base nova.
- **Por que não condicionar ao conjunto em risco** (partido × município sem base em t−1): a EC 111 altera quem está nesse conjunto em 2026, porque a base de 2022 já é pós-tratamento. Isso viraria um viés de seleção no segundo pós-período e desbalancearia o painel. A versão condicional fica como robustez só para 2022.
- **Pré-períodos:** a transição de 2018 (2014 → 2018) é um pré-período. Para ter também 2014 (2010 → 2014) e assim o pré-teste e o HonestDiD, é preciso o **voto por município de 2010**. Em 2010 basta saber se o partido tinha base (qualquer candidatura); gênero e raça só são exigidos para a candidatura que forma a base em t ≥ 2014, e a raça existe desde 2014.
- **Benchmark mecânico:** se a EC 111 só aumentou o número de candidaturas de g (`cand_g`, DiD de listas), parte do aumento de `nova_base_g` é mecânica. Para interpretar, reportar ao lado o ATT de bases novas de g **por candidatura de g** (`nova_base_g` ÷ nº de candidaturas de g da lista na UF).
- **Bases fracas:** com o QL, candidaturas com poucos votos mas concentrados formam "bases". Isso importa aqui porque a EC 111 pode inflar candidaturas de g pouco competitivas. Robustez obrigatória: só contam bases de candidaturas **competitivas** (votos ≥ 10% do QE) e bases com um mínimo absoluto de votos no município.

### 4.2 Resultados secundários

| Variável | Definição | Análogo em Calzavara |
|---|---|---|
| `base_g` | 1 se o partido tem ≥ 1 candidatura de g com base no município (QL_voto > 1 **e** fatia ≥ `fatia_min`); é o nível, que mistura território antigo e novo | presença de candidato com QL > 1 na RGI (Tab. 2) |
| `n_base_g` / `sh_base_g` | nº de bases de g / % das bases do partido no município que são de g | — |
| `voto_g_mun` | % dos votos nominais do partido no município obtidos por g | % de votos do partido na RGI (3.4) |
| `base_g_livre` | base de g em município **sem** base de incumbente do partido no mesmo cargo | "livre de disputa" (Tab. 1) |
| `base_g_sobrep` | base de g **sobreposta** à base de um incumbente do partido | "conflito entre bases" (Tab. 1) |

- **Heterogeneidade (margem extensiva × intensiva, à la Calzavara):** separar partido × município **sem** base de g em 2018 (ganho extensivo) de partido × município **com** base de g em 2018.
- **Base = QL > 1 e fatia ≥ 0,025** (ASSUMIDO): mesma regra calibrada em `ql-voto-2026/R/config.R`. Sem a fatia mínima, municípios pequenos geram QL > 1 com poucos votos, que é justamente o problema que leva Calzavara a rejeitar o município. Variantes de robustez: `fatia_min` = 0 e 0,05; limiares de QL 2 e 3 (como Calzavara).

## 5. Robustez e diagnóstico

- **Agregação em RGI** (unidade de Calzavara): refazer `base_g` e `voto_g_mun` com QL por RGI (tabela município → RGI do IBGE 2017). Se o sinal só aparecer no município, o resultado provavelmente é ruído de municípios pequenos.
- **Pré-teste 2014 → 2018** e sensibilidade de Rambachan & Roth (2023, magnitudes relativas M̄) via `HonestDiD`.
- **Painel balanceado** (partido × município presente nos dois cargos em todos os anos) × desbalanceado (`allow_unbalanced_panel = TRUE`).
- **Placebo de cargo:** municípios onde o partido não lançou candidaturas de g em nenhum cargo (resultado mecanicamente 0) ficam fora, para não inflar a amostra com zeros estruturais.
- **Ameaças específicas de 2026:** cláusula de desempenho de 2,5% (só federal); fusões (PRD, Podemos, Solidariedade). Mesmas notas do plano de listas.

## 6. Dados

| Ano | Votos candidato × município | Situação |
|---|---|---|
| 2018, 2022, 2026 | `ql_voto_{federal,estadual}_{ano}.rds` | **pronto** em `explorations/ql-voto-2026/` (branch não incorporada) |
| 2010 federal e estadual | `votacao_candidato_munzona_2010.zip` (TSE) | **baixar** — só para saber onde o partido tinha base em 2010 (transição 2010 → 2014) |
| 2014 federal | `data/raw/votos_mun_2014_df.rds` (projeto da autora) | conferir se é candidato × município com o voto nominal |
| 2014 estadual | `votacao_candidato_munzona_2014.zip` (TSE) | **baixar**: `eleitos_e_compet_est_2014_df` é no nível da candidatura, sem município |
| Gênero/raça, incumbência | candidaturas 2014–2026 já usadas no DiD de listas | pronto |
| RGI | tabela de composição municipal das RGIs (IBGE 2017) | baixar (robustez) |

Raça em 2014: a autodeclaração começou em 2014, então a série inteira é comparável. Ainda assim, registrar a taxa de não informado por ano.

## 7. Arquivos (`explorations/ec111-did-ql-municipio/R/`)

1. `00_dados.R` — baixa o voto por município de 2010 e 2014 (TSE) e a tabela de RGIs
2. `01_ql_2014.R` — QL_voto de 2014 com a função `calcular_ql_voto()` da exploração ql-voto-2026 (mesma regra)
3. `02_painel_partido_municipio.R` — empilha 2014–2026 e monta o painel partido × município × cargo com os resultados da §4
4. `03_did.R` — `att_gt` + `aggte`, TWFE com efeitos fixos locais, heterogeneidade extensiva × intensiva
5. `04_robustez.R` — RGI, `fatia_min`, limiares de QL, HonestDiD, desbalanceado
6. `05_figuras_tabelas.R` — event study por resultado e por grupo, tabela de resultados

## 8. Verificação

- QL de 2014: contagem de candidaturas e de votos válidos por cargo × UF conferida contra o TSE; a regra reaplicada em 2018 reproduz o `ql_voto_federal_2018.rds` existente.
- Painel sem duplicatas em `id_pmc × ano`; checagem `att_gt` = TWFE simples.
- Os achados da lista (DiD de listas, `voto_g`) devem ser coerentes com a soma de `voto_g_mun` ponderada; uma divergência grande aponta erro de construção.
- `/review-r` nos scripts; `quality_score.py` ≥ 80.

## 9. Decisões em aberto (para a autora)

1. **Base da branch:** criar a exploração a partir de `worktree-ql-voto-2026` (reaproveita o QL 2018–2026 já pronto) ou esperar o merge dela na `main`? *Recomendação:* partir da branch e fazer o merge depois.
2. ~~**Resultado principal**~~ — **DECIDIDO (2026-10-14):** decomposição `nova_base = nova_base_g + nova_base_naog` (§4.1). `base_g` e `voto_g_mun` passam a ser secundários. Exige o voto por município de 2010 para ter dois pré-períodos.
5. **Branch:** o trabalho fica em `worktree-did-ec111-ql-municipio`, **sem merge na main** até nova ordem da autora. O plano foi incluído com `git add -f`, porque `quality_reports/plans/` é ignorado no `.gitignore`.
3. **Município ou RGI como unidade principal:** você pediu município; Calzavara argumenta pela RGI. *Recomendação:* município como principal (é onde os efeitos fixos locais funcionam) e RGI como robustez obrigatória.
4. **Como citar Calzavara:** referência de mensuração e de desenho descritivo (QL, base como presença, extensivo × intensivo), **não** como precedente de DiD. Entrada a acrescentar no `Bibliography_base.bib` (ano e instituição a confirmar na folha de rosto).
