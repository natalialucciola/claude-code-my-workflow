# Coordenação Territorial de Listas Partidárias (sobreposição de gasto)

> **→ Graduado para Capítulo 6 da tese**: `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd`.
> Scripts de produção em `scripts/R/sobreposicao_territorial_partido/`. Esta pasta continua sendo o
> registro do processo investigativo completo (bugs, correções metodológicas, scripts de diagnóstico) — ver `SESSION_LOG.md`.

## Goal

Testar se partidos coordenam a alocação territorial do gasto de campanha entre os próprios candidatos — isto é, se há concentração de dois ou mais candidatos do mesmo partido, cargo e ano acima do QL do gasto em um mesmo município ("sobreposição"), em vez de cada candidato ocupar um território próprio dentro da legenda. Complementa a análise de "gasto na base territorial do partido" já existente (`Analise_Gasto_Base_Partido.R`), que olha a base do partido em t-1; aqui o recorte é sincrônico — sobreposição *entre candidatos do mesmo partido no mesmo pleito*.

## Status

IN PROGRESS (iniciado 2026-08-15)

## Hypotheses to Test

1. Há diferença na taxa de sobreposição entre Deputado Federal e Estadual.
2. Há diferença entre os ciclos 2018 e 2022.
3. Mulheres estão mais expostas à sobreposição do que homens (i.e., quando concentram gasto em um município, mais frequentemente dividem esse território com um correligionário).
4. Candidatos negros estão mais expostos à sobreposição do que candidatos brancos.

## Método

- **Dados:** `ql_gasto_eleit_{2018,2022}.rds` (Federal) e `ql_gasto_eleit_est_{2018,2022}.rds` (Estadual), nível candidato-município, copiados de `OneDrive/Tese/Gasto/` para `data/raw/` em 2026-08-15. Filtrado por `partidos_sel` (PT, PSB, MDB, PSD, UNIÃO, PP, REPUBLICANOS, PL) — mesmo recorte usado no resto da tese.
- **partido_harm:** as bases estaduais não trazem `partido_harm` pré-calculado (só as federais trazem); recalculado aqui via `harmonizar_partido()` (copiado de `Codigo de Apoio.R`, sem caminho absoluto — ver `R/harmonizar_partido.R`).
- **Nível município:** para cada (cargo, ano, partido_harm, UF, município), conto `n_cand_ql1` = número de candidatos distintos do partido com `QL_gasto_eleit > 1` nesse município. `overlap = n_cand_ql1 >= 2`.
- **Nível candidato — `taxa_sobreposicao`:** para cada candidato, entre os municípios em que ele tem `QL_gasto_eleit > 1`, qual fração desses municípios é "overlap" (compartilhada com ≥1 correligionário)? Essa é a métrica comparada por gênero/raça/cargo/ano.
- **Testes:** teste t (Welch) para FEMININO vs. MASCULINO e para NEGRA vs. BRANCA, dentro de cada célula cargo × ano.

**Limitação conhecida:** `taxa_sobreposicao` só é definida para candidatos com pelo menos 1 município com QL_gasto_eleit > 1 (14.752 de todos os candidatos dos partidos selecionados) — candidatos sem nenhuma concentração territorial de gasto ficam de fora dessa métrica, o que é o comportamento esperado (não há "sobreposição" para quem não concentra gasto em lugar nenhum).

## Success Criteria

- Script roda sem erro e produz as 4 tabelas comparativas.
- Resultados plausíveis (taxas entre 0–100%, direção e magnitude interpretáveis).

## Findings (1ª rodada, 2026-08-15)

- **Sobreposição é alta em geral**: 27–39% dos municípios com ao menos 1 candidato acima do QL têm 2+ candidatos do mesmo partido (Tabela A) — indício de que a coordenação territorial da lista é fraca ou os partidos não conseguem (ou não tentam) evitar sobreposição entre seus próprios candidatos.
- **Mulheres têm taxa de sobreposição maior que homens em todas as 4 células** (cargo × ano), com gap de 1,7 a 8,6 p.p., estatisticamente significativo em todas (p < 0,02). Maior gap: Federal 2018 (77,1% vs. 68,5%, p ≈ 3,4e-8).
- **Candidatos negros têm taxa maior que brancos em 3 das 4 células** (não significativo em Federal 2022, p ≈ 0,20); gap chega a 9,5 p.p. em Federal 2018.
- **Gênero × raça (Tabela D):** hierarquia não é uniformemente aditiva — em Federal 2022, mulheres negras (77,7%) ficam *empatadas* com homens negros (77,7%), ambos abaixo de mulheres brancas (79,3%); nos demais recortes, mulheres negras têm a taxa mais alta do grupo.
- Consistente com o achado já documentado no `AGENTS.md` (alinhamento espacial gasto-voto): mulheres e negros parecem ter menos controle sobre "seu" território de gasto dentro do partido.

**Leitura como hipótese, não conclusão** — ainda não testado: robustez a outros thresholds de QL (só testei >1), controle por competitividade/eleição, e se a sobreposição é geograficamente ampla (muitos municípios pequenos) ou concentrada (poucos municípios grandes, onde qualquer candidato tende a passar do QL).

## Findings (2ª rodada, 2026-08-15) — capital, resultado eleitoral, incumbência

### Nota metodológica importante (correção pós-2ª rodada)

A primeira versão das tabelas B1/B2/B3 misturava duas unidades de análise sem deixar isso explícito, e a correção mudou um dos resultados substancialmente:

- **B0** (município-level — mesma definição da Tabela A, uma linha por município): responde a pergunta original ("% de municípios com 2+ candidatos do partido acima do QL"), quebrada por capital/não-capital.
- **B1** (candidato×município ponderado): cada candidato entra 1x por município em que concentrou gasto — um candidato ativo em muitos municípios pesa mais. Útil para "exposição bruta a pares candidato-município compartilhados", mas **infla artificialmente** o efeito capital (municípios com muitos candidatos acima do QL contam muitas vezes, sempre como sobreposição).
- **B2/B3** (gap de gênero/raça por tipo de município): recalculadas para pesar cada candidato igualmente (taxa pessoal de sobreposição, restrita a capital ou a não-capital, depois média por grupo) — mesma convenção das tabelas do 1º round. A versão inicial (não corrigida) pesava por par candidato-município, e **inflava o gap de raça** de 0,4pp real para 4,9pp aparente fora das capitais.

### B0. % de municípios com 2+ candidatos do partido acima do QL, por tipo de município

| | Não-capital | Capital |
|---|---|---|
| Estadual 2018 | 29,2% (2.091/7.164) | 96,6% (198/205) |
| Estadual 2022 | 38,3% (3.593/9.393) | 99,5% (199/200) |
| Federal 2018 | 28,1% (2.193/7.803) | 83,9% (167/199) |
| Federal 2022 | 36,3% (3.708/10.207) | 99,0% (195/197) |

Nas capitais a sobreposição está **quase saturada** (84–99,5% dos municípios-capital com candidato acima do QL têm 2+); fora delas, é minoria (28–38%). Só 26 municípios são capitais — o efeito é real mas concentrado em muito poucos casos (mecânico: capital concentra tanto eleitorado que é difícil um único candidato "dominar" o QL sozinho ali).

### B2/B3. Gap de gênero/raça, por tipo de município (taxa pessoal por candidato — corrigido)

| | Não-capital | Capital |
|---|---|---|
| Gênero (F − M) | **+3,6pp** (67,5% vs. 63,9%), **p < 0,001** | +0,3pp (99,8% vs. 99,5%), p = 0,005 (magnitude irrelevante apesar de "significativo") |
| Raça (Negra − Branca) | +0,4pp (65,3% vs. 64,9%), **p = 0,51 — não significativo** | +0,2pp (99,7% vs. 99,5%), p = 0,09 — não significativo |

**Correção em relação à leitura inicial**: o gap de **gênero** é real e robusto fora das capitais (3,6pp, altamente significativo) — a leitura original se sustenta para gênero. O gap de **raça**, porém, **não é estatisticamente significativo em nenhum dos dois tipos de município** depois de pesar cada candidato igualmente — a versão inicial (0,4pp virou 4,9pp por erro de peso) estava incorreta. **Não há evidência, nesta exploração, de um gap de raça na taxa de sobreposição territorial** — diferente do gap de gênero, que se mantém.

### C. Resultado eleitoral no ano do gasto

Sobreposição cai monotonicamente com o sucesso eleitoral, nas 4 células cargo×ano — Eleito < Competitivo, não eleito < Não competitivo (ex. Federal 2022: 59,0% → 61,3% → 73,7%). Candidatos que se saem pior têm gasto menos "exclusivo" — coerente com menos estrutura de campanha própria.

Dentro de "Eleito", o gap de gênero **não é estável em direção**: mulheres eleitas têm taxa *maior* em Federal 2022 (63,5% vs. 58,4%) mas *menor* em Federal 2018 (45,4% vs. 48,7%) e Estadual 2018 (52,0% vs. 51,6%, ~empate). Isso sugere que o gap geral de gênero (1ª rodada) é em boa parte **composicional** — mulheres estão desproporcionalmente no grupo "não competitivo" (onde a sobreposição é alta para todos), não que mulheres eleitas especificamente tenham menos território exclusivo.

### D. Incumbência (eleito no mesmo cargo na eleição anterior)

| | Incumbente | Não-incumbente |
|---|---|---|
| Estadual 2018 (vs. 2014) | 50,1% | 67,8% |
| Estadual 2022 (vs. 2018) | 60,2% | 75,5% |
| Federal 2022 (vs. 2018) | 58,3% | 69,9% |
| Federal 2018 (vs. 2014) | **não calculado** — candidaturas federais de 2014 não estão preparadas neste projeto (só estaduais 2014 foram extraídas) | |

Incumbentes têm território bem mais exclusivo (gap de 11 a 18pp) do que não-incumbentes, em todas as 3 células calculáveis. Como mulheres e candidatos negros são incumbentes com menos frequência (a própria sub-representação que é o tema da tese), parte do gap de gênero/raça da 1ª rodada pode ser efeito de composição via incumbência — precisa de uma regressão/controle formal para separar, não dá para concluir só com médias cruzadas.

### Leitura consolidada (revisada após correção de peso)

A 1ª rodada mostrou mulheres **e negros** com mais sobreposição em média. Depois de corrigir o peso (candidato, não par candidato-município) e comparar dentro de capital/não-capital:

- **Gênero**: o gap se sustenta e é robusto — real fora das capitais (+3,6pp, p<0,001), efetivamente nulo dentro delas (municípios saturados para todo mundo).
- **Raça**: o gap **não sobrevive** à correção de peso — não é significativo nem dentro nem fora das capitais. O que parecia um efeito de raça no 1º round era em boa parte artefato de peso (candidatos negros com mais pares candidato-município na amostra, não necessariamente taxa pessoal mais alta).

Para gênero, ainda é preciso separar do efeito de **incumbência** e de estar no grupo **não competitivo** (ambos possivelmente confundidos, ver seções C e D) — mulheres são menos incumbentes e mais concentradas em "não competitivo", e ambos aumentam a sobreposição para qualquer candidato. Um próximo passo natural é uma regressão de `overlap`/`taxa_sobreposicao` em gênero + incumbência + resultado + capital, para isolar o efeito líquido de gênero desses confundidores — em vez de comparações de médias bivariadas. Para raça, dado que o gap não é significativo nesta métrica, não há o que isolar por enquanto.

## Análise de tripla diferença (DDD) — incentivo financeiro de 2022 (2026-08-15)

### Hipótese testada
O incentivo financeiro de 2022 (fundo eleitoral proporcional a votos de mulheres/negros) reduziu a sobreposição territorial especificamente para Deputado Federal, e não para Estadual (já que o incentivo não se aplicaria da mesma forma ao cargo estadual).

### Especificação
`taxa_sobreposicao ~ Federal × Ano2022 × Mulher(ou Negra) + FE(partido_harm, SG_UF)`, erros-padrão clusterizados em (partido_harm, SG_UF). Unidade: candidato. Coeficiente de interesse: a tripla interação `Federal:Ano2022:Grupo`.

**Controles (efeitos fixos) em todas as especificações**: `partido_harm` (9 partidos) e `SG_UF` (26 estados), com erros-padrão clusterizados nas mesmas duas dimensões. Ambos são pré-determinados (escolhidos antes da campanha, não consequência da estratégia de gasto) — controles legítimos, não "bad controls".

**Decisão metodológica sobre incumbência/resultado eleitoral — revisada em 2026-08-15**: a especificação principal não controla por nenhum dos dois, pelo mesmo motivo ("bad control" — se o incentivo atua via composição, controlar por composição enviesaria o efeito total para baixo). Inicialmente eu tinha incluído "+ resultado eleitoral" como checagem de robustez, mas isso está **errado**: incumbência é medida na eleição *anterior* (pré-determinada antes da campanha atual), enquanto resultado eleitoral do ano corrente é decidido pelo *mesmo* processo eleitoral que produz `taxa_sobreposicao` — é plausivelmente consequência da mesma estratégia de campanha que a variável dependente, não uma característica pré-tratamento. Controlar por ele pode bloquear parte do próprio canal causal de interesse; a estabilidade do coeficiente ao incluí-lo **não é evidência válida de robustez**. Por isso essa especificação foi **removida da tabela de robustez** — mantida só como nota abaixo. A decomposição por incumbência (pré-determinada) continua válida.

**Preparação de dados nova**: para viabilizar o controle de incumbência nas 4 células (Federal e Estadual, 2018 e 2022), foi necessário baixar candidaturas de Deputado Federal 2014 via `electionsBR::elections_tse(2014, type="candidate")` — não existiam neste projeto. Status eleitoral de 2014 já estava disponível em `Votacao/2014/votos_mun_2014_df.rds` via `DS_SIT_TOT_TURNO` (verificado: 1 status por candidato, sem conflito). Script: `scripts/08_baixar_candidatos_federal_2014.R`. Dados salvos tanto no projeto de análise original (`Candidaturas/2014/candidatos2014.rds`, `Votacao/2014/eleitos_2014_df.rds`) quanto em `data/raw/` desta exploração. Cobertura: 513 eleitos Federal 2014, 100% com CPF identificado.

### Resultado — robusto nas 2 especificações metodologicamente válidas

| Especificação | Gênero (β: Federal×2022×Mulher) | Raça (β: Federal×2022×Negra) |
|---|---|---|
| Principal (sem controles) | −2,8pp, p=0,117 | **−5,4pp, p=0,002** |
| + incumbência (4 células completas, pré-determinada) | −2,6pp, p=0,125 | **−5,7pp, p=0,0029** |

*Nota (não é checagem de robustez válida, ver acima): + resultado eleitoral do ano corrente — gênero −2,3pp (p=0,123), raça −5,5pp (p=0,0018). Mantido só como registro, não como evidência.*

### Conclusão

**A hipótese se confirma para raça, e a evidência é robusta**: o efeito da tripla interação para candidatos negros no Federal é forte, estável (−5,4 a −5,7pp) e estatisticamente significativo nas duas especificações metodologicamente válidas — não é explicado por incumbência (controle legítimo). Também vale notar: `incumbente` tem coeficiente grande e altamente significativo em ambos os modelos (≈ −14,6pp, p<0,00001) — incumbentes têm território bem mais exclusivo, mas isso não é o que explica o efeito de raça.

**Para gênero, a hipótese não se sustenta**: o sinal é sempre o esperado (negativo), mas nunca estatisticamente significativo (p entre 0,117 e 0,125) em nenhuma especificação — a queda de sobreposição para mulheres 2018→2022 não é *especificamente* federal; acontece de forma parecida nos dois cargos (o DiD 2x2 dentro do Estadual, feito antes de ter os dados federais completos, já mostrava isso: −3,8pp, p=0,028, dentro do próprio Estadual).

## Tabelas e gráficos consolidados (2026-08-15)

Script: `R/04_tabelas_graficos_consolidacao.R`. Convenção visual seguida (mesma do resto da tese, ver `AGENTS.md` do projeto de análise original): dumbbell com círculo aberto = 2018, círculo preenchido = 2022; forma **e** cor distinguem o grupo (não só cor), para o gráfico continuar legível em preto e branco / impressão. Paleta Okabe-Ito (referência revisada por pares para segurança a daltonismo) — não foi possível rodar o validador automático desta sessão porque não há Node.js instalado na máquina.

**Tabelas** (`.csv` + `.tex` via kableExtra, mesmo padrão dos outros scripts da tese):
- `tabela_consolidada_r1.csv/.tex` — gap de gênero/raça por cargo × ano, com teste t.
- `tabela_consolidada_ddd.csv/.tex` — coeficientes da tripla interação (principal e + incumbência), gênero e raça.

**Gráficos** (`.pdf` + `.png`, 300dpi):
- `grafico_sobreposicao_genero.{pdf,png}` — dumbbell por cargo × gênero × ano.
- `grafico_sobreposicao_raca.{pdf,png}` — dumbbell por cargo × raça × ano.
- `grafico_ddd_coeficientes.{pdf,png}` — coefficient plot da tripla interação (IC 95%), duas especificações.

**Nota de revisão visual**: no gráfico de raça, os pontos Federal/Negra 2018 (77,4%) e 2022 (77,7%) quase coincidem — a sobreposição de dois círculos tão próximos criava uma ilusão de padrão (pareidolia) na primeira versão. Resolvido com um "halo" branco entre as marcas (técnica padrão para marcas sobrepostas, ver skill de dataviz usada nesta sessão) — não é um bug de dado, é puramente uma correção de renderização.

## Modelo 2 e alcance territorial total — 2026-08-16

*(Nesta seção, chamados H6/H7 na numeração original desta exploração — no capítulo final, após a remoção de H1/H2 sobre cargo/tempo, correspondem a H4/H5. Ver `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd` para a numeração vigente. Os números desta seção também refletem a amostra de 8 partidos, depois substituída — ver seção seguinte.)*

Reformulação do capítulo: em vez de medir sobreposição com **qualquer** correligionário (Modelo 1, acima), o Modelo 2 mede especificamente a sobreposição com correligionários **incumbentes** (proxy de "candidato tradicional/consolidado" do partido) — teste direto do mecanismo de que lideranças partidárias protegem seus quadros mais fortes enquanto aproveitam o incentivo da EC 111/2021 para mulheres/negros. Scripts: `R/05_modelo2_incumbente.R` (Modelo 2 + H7), `R/06_tabelas_graficos_modelo2.R` (tabelas/gráficos).

## Amostra final: universo completo de partidos (não mais `partidos_sel`) — 2026-08-16

`partidos_sel` (8 partidos) nunca teve justificativa teórica documentada — era herança de conveniência de `AGENTS.md` do projeto original. Ao testar a mesma análise causal sem esse filtro, **o achado que parecia mais forte do capítulo não sobreviveu**: o efeito federal-específico de raça no Modelo 1 (−5,4pp, p=0,002 com 8 partidos) inverteu de sinal e ficou nulo (+0,7pp, p=0,72) no universo completo de 34 partidos.

Decisão: em vez de manter `partidos_sel` como amostra principal e reportar essa instabilidade como um robustness check à parte, o filtro foi **removido por completo** de `01_overlap_partido.R` — desde então, todo o pipeline (01–06) roda sobre o universo completo de partidos (34 legendas, 37.158 candidatos) como única amostra. `02_overlap_extensoes.R` também foi corrigido nesta sessão: a Tabela D (incumbência) tinha um cálculo local desatualizado que excluía Federal 2018 mesmo depois de os dados de candidaturas Federal 2014 já estarem disponíveis desde a sessão anterior — agora completa nas 4 células.

Os scripts `07_versao_b_universo_completo.R` e `08_grafico_versaoB.R` (criados para o teste de robustez) estão marcados como SUPERSEDED no cabeçalho — a "Versão B" que calculavam é, desde esta sessão, a única versão. Resultado final (achados descritivos H1/H2 mais fortes com a amostra correta; evidência causal H3/H4/H5 fraca para os dois grupos) documentado em `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd`.

## Next Steps

- [x] ~~Preparar candidaturas de Deputado Federal 2014~~ — feito em 2026-08-15 (`scripts/08_baixar_candidatos_federal_2014.R`), permitiu a DDD completa com controle de incumbência.
- [x] ~~Redigir a DDD como achado do capítulo~~ — feito (graduado para Capítulo 6).
- [x] ~~Testar se a queda de sobreposição é especificamente sobre candidatos tradicionais (incumbentes)~~ — feito em 2026-08-16 (Modelo 2 + H5).
- [x] ~~Checar se `partidos_sel` tem justificativa teórica; se não, corrigir a amostra~~ — feito em 2026-08-16. Sem justificativa teórica encontrada; o filtro foi removido e todo o pipeline roda sobre o universo completo de partidos.
- [x] ~~Corrigir a Tabela D (incumbência) para incluir Federal 2018~~ — feito em 2026-08-16 (`02_overlap_extensoes.R`).
- [ ] Testar sensibilidade a outros thresholds de QL_gasto_eleit (ex.: > 1.5, > 2).
- [ ] Buscar literatura sobre gatekeeping partidário especificamente na dimensão racial da EC 111 (a história documentada por Gatto 2025 cobre a dimensão de gênero; ver Limitações do capítulo).
- [ ] Ver se a sobreposição em não-capitais está concentrada em municípios médios/grandes (não só capitais) — cruzar com tamanho do eleitorado de forma contínua, não binária.
- [ ] Dados diretos sobre a distribuição do fundo eleitoral por candidato/partido/ano, se disponíveis, permitiriam testar o mecanismo do incentivo financeiro de forma mais direta.

## Timeline

- 2026-08-15 (manhã): Migrados os 4 arquivos QL-gasto necessários; script `R/01_overlap_partido.R` escrito e rodado; achados iniciais documentados acima.
- 2026-08-15 (tarde): Migrados candidaturas (2018/2022 federal e estadual, 2014 estadual), dados de eleito/competitivo 2014/2018 estadual, e crosswalk de nomes de município (extraído de `gasto_brasil_2018.rds`, depois descartado). Script `R/02_overlap_extensoes.R` escrito e rodado: capital vs. não-capital, resultado eleitoral, incumbência. Achado central: o gap de gênero/raça da 1ª rodada é majoritariamente um fenômeno de município não-capital, possivelmente confundido com incumbência e resultado eleitoral.
