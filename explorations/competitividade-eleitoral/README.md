# Competitividade eleitoral pela margem de votos (ABD 2022 × LSS 2024)

**Status:** aplicado a Deputado Federal e Estadual, 2014–2026 (exploração, 2026-10-14). Plano:
`PLANO_2026-10-13_margem-ec111.md`. Abaixo, primeiro os resultados; depois o estudo das medidas.

## Resultados (EC 111, 2014–2026)

**Execução.** Os scripts `R/01` a `R/05` rodam em sequência, a partir da raiz do repositório.
Os dados brutos do TSE ficam em `data/raw/tse/` e os processados em `data/processed/margem_*`;
os dois são gitignored.

**Validação.**
- A distribuição de cadeiras reproduz **100% dos eleitos do TSE** nos 216 distritos (UF × cargo
  × ano), em `output/validacao_distribuicao.csv`.
- Em 2022, a base do TSE traz os eleitos **recalculados** após as ADIs 7228/7263/7325 (3ª fase
  das sobras aberta a todas as listas). A regra original da totalização de 2022 erra 8 cadeiras
  federais (AP, DF, RO, TO).

**Comparação com ABD** (Federal 2014; `R/03b`, `output/comparacao_abd_2014.csv`). 5.796 dos 6.165
candidatos pareados.
- O resultado eleito/não eleito coincide em 99,98%.
- Para os eleitos, a medida é quase a mesma (diferença mediana de 0,009).
- Perto do limiar (|rv| < 0,1), 66% coincidem ao centésimo.
- Para os não eleitos longe do limiar, a margem calculada aqui é maior (diferença mediana de
  −0,15). Hipótese: o limiar entre listas de ABD não exige ultrapassar os colegas de lista. Não
  dá para confirmar, porque o código não foi publicado.

**Saturação das bandas largas.** Numa lista grande, a distância de uma candidatura fraca é dada
pela lista (o último eleito ou o primeiro não eleito), não pelos votos dela. Entre as
candidaturas com menos de 0,5% do QE em votos, 27,6% ficam "a menos de 0,25 QE" do limiar, mas só
0,8% a menos de 0,1 QE. Por isso o **desfecho principal é a banda de 0,1 QE**; as de 0,25 e 0,5
medem em boa parte a estrutura da lista.

**Efeitos** (`R/05`, `output/ddd_resultados.csv`, `output/ddd_estudo_evento.png`). Tripla
diferença, did::att_gt por UF × cargo, sem DF, base 2018, bandas uniformes de 95%. Efeitos em
p.p. sobre a diferença entre grupos.

| Mulheres − homens | 2014 (pré) | 2022 | 2026 | Geral |
| --- | --- | --- | --- | --- |
| Eleita ou a < 0,1 QE (sem peso) | −0,8 [−3,9; 2,4] | **3,4** [0,4; 6,4] | **3,9** [0,0; 7,7] | **3,6** [1,0; 6,3] |
| Idem, ponderado | 0,6 | 2,4 | 2,3 | 2,3 [−0,4; 5,1] |
| Idem, sem UFs com 8 cadeiras | 0,9 | **3,9** | **4,9** | **4,4** [1,3; 7,4] |
| Idem, sem incumbentes (2018–2026) | — | **3,0** [0,2; 5,7] | 2,3 | 2,7 [−0,1; 5,4] |
| Eleita (sem peso) | −2,3 | 0,9 | **2,9** [0,1; 5,8] | 1,9 [−0,3; 4,1] |
| TWFE por candidatura (eleita ou < 0,1 QE) | 0,5 (EP 1,1) | 2,6 (1,1) | 2,5 (1,5) | — |

Patamar de 2018, Federal: 7,1% das mulheres e 15,9% dos homens eleitas/os ou a < 0,1 QE.

**Leitura.**
- **Mulheres.** O pré-teste de 2014 é ≈ 0 em todos os desfechos. A EC está associada a uma
  aproximação das mulheres ao limiar no Federal, de cerca de 3–4 p.p., ou ~40% da distância de
  2018. O efeito aparece em 2022 e se mantém em 2026; para "eleita", só em 2026.
- **Sensibilidade.** O efeito é menor e não significativo com peso pelo número de candidaturas
  (as UFs grandes pesam mais) e com a normalização de LSS. Com ABD, a banda de 0,1 dá 2,5 p.p.,
  significativo. É evidência moderada para H_a (competitividade) contra H_b (só votos longe do
  limiar). Contrasta com a exploração de gasto (recursos sem mais mulheres viáveis) e com Fonseca
  et al. (efeito em candidaturas pouco competitivas). Vale discutir.
- **Raça.** O **pré-teste falha**: 2014 negativo e significativo (−5,8 p.p. em "eleita ou
  < 0,1 QE"; −4,5 em "eleita"), da mesma ordem dos efeitos positivos de 2026. Para pessoas negras
  e mulheres negras, o desenho não sustenta efeito da EC; há tendência prévia. HonestDiD não está
  instalado; a sensibilidade formal fica pendente.

**Composição e candidaturas não competitivas** (`R/06`, `R/07`; peso = magnitude do distrito,
constante no tempo em todas as UF × cargo).
- **Composição.** A fatia feminina entre as competitivas sobe nos dois cargos quase igual (Federal
  17,1 → 19,3 → 21,1%; Estadual 16,7 → 17,7 → 20,1%). Efeito: +1,4 a +1,7 p.p., sem
  significância.
- **Não competitivas** (não eleitas e a mais de 0,1 QE do limiar). De 2018 para 2022, as femininas
  no Federal passam de 2.201 para 3.090; no Estadual ficam em 4.666. Efeito: +1,7 a +2,2 por
  cadeira, em 2022 e 2026. As masculinas crescem ainda mais no Federal: a diferença
  mulheres − homens por cadeira é −1,1 a −1,2. A fatia feminina entre as não competitivas não muda
  de forma diferenciada (+0,5 a +1,1, sem significância).
- **Leitura.** Houve uma expansão geral de candidaturas fracas ao Federal, maior entre homens. A
  queda da taxa de competitividade dos homens (denominador maior) explica a maior parte da
  "aproximação" das mulheres no `R/05`. Um motor plausível e específico do Federal, além da EC:
  cláusula de desempenho e distribuição de fundos por votos na Câmara (EC 97/2017), a conferir.
- **Peso pela magnitude.** Dá resultados próximos aos sem peso (taxa: 3,1 contra 3,6 p.p. no
  geral).

**Cláusula de desempenho** (`R/08`; partido ou federação de 2022 classificado pela votação para a
Câmara em 2018; pressionado < 4%, robustez < 3%; 2014–2022).
- Não competitivas por cadeira, 2022 (sem peso / magnitude):
  - homens: +1,5 / +1,2 nos partidos com folga e +1,9 / +1,8 nos pressionados;
  - mulheres: +0,9 / +0,7 com folga e +1,2 / +1,1 pressionados.
- A expansão é geral e só um pouco maior nos pressionados. **A cláusula não explica a maior parte
  dela.**
- A "aproximação" das mulheres (diferença na taxa de competitivas) aparece nos partidos **com
  folga** (+4,5 / +5,8) e não nos pressionados (+1,8 / +0,9). A composição das competitivas não
  muda em nenhum grupo.
- Hipótese ainda não testada: o fim das coligações com limite de M + 1 candidaturas por partido
  (Lei 14.211/2021) pesa mais em distritos de magnitude pequena, que são mais comuns no Federal.
- Conferência: o "4.666" de mulheres não competitivas no Estadual em 2018 e 2022 é coincidência
  (4.993 − 327 e 4.960 − 294). As bases são distintas, nenhuma UF coincide e o gênero de 2022 bate
  100% com o `consulta_cand_2022`.

**Fim das coligações × magnitude** (`R/09`, `output/magnitude_candidaturas.png`).
- Regressão por distrito: Δy = a + b·log(M) + c·Federal. O excesso do Federal em candidaturas
  aptas por cadeira, de 2018 para 2022, é de 5,6 sem controle e 4,5 com log(M). Na faixa de
  magnitude comum (24 a 70 cadeiras, 7 distritos federais), fica em 3,6 a 3,7. Todos
  significativos.
- Não competitivas por cadeira (sem controle → com log(M) → faixa comum): homens 3,4 → 3,1 → 2,6;
  mulheres 2,2 → 1,7 → 1,3.
- A magnitude explica a maior parte do aumento de **listas** por cadeira (0,64 → 0,26 → 0,1),
  mas só 20 a 35% do aumento de **candidaturas**. Federal e Estadual seguem curvas separadas na
  mesma magnitude.
- **Tendência prévia:** de 2014 para 2018, com coligações nos dois anos, o Federal já crescia mais
  em candidaturas por cadeira (excesso de 1,7 a 3,1). Média por distrito: Federal 10,3 → 13,3 →
  17,8; Estadual 13,4 → 14,8 → 13,7. É uma "federalização" da estratégia partidária que começa
  antes da EC 111. Leitura plausível: fundos e cláusula de desempenho ligados à Câmara desde 2018.
- **Diferença na taxa de competitivas (mulheres − homens), na faixa comum:** +3,0 a +3,2 em
  2018–2022, contra +3,5 de 2014 para 2018 (placebo). Entre distritos comparáveis, o "efeito" é do
  mesmo tamanho da tendência anterior.

**Pendências.** Sensibilidade formal (HonestDiD); refazer 2022 com a regra original da
totalização; painel de listas (complemento do plano); decidir o capítulo de destino.

## Objetivo

Estudar como implementar, para Deputado Federal e Estadual (2014, 2018, 2022), a medida de
competitividade da candidatura de Avelino, Biderman & Desposato (2022), e compará-la com a de
Luechinger, Schelker & Schmid (2024). As duas medem a mesma coisa: **quantos votos faltam (ou
sobram) para a candidatura mudar de resultado** em lista aberta. Na tese, isso dá uma medida de
competitividade pelo voto mais fina que o corte atual (≥ 10% do QE ou eleita), útil para
perguntar quantas mulheres e pessoas negras estão perto do limiar de eleição.

## Fontes

| Artigo | Onde está | Replicação |
| --- | --- | --- |
| Avelino Filho, Biderman & Desposato (2022). Sources of the Incumbency (Dis)Advantage. *BPSR* 16(1): e0004. doi:10.1590/1981-3821202200010003 | `Tese/Literatura/AvelinoBidermanDesposato2021.pdf` (OneDrive FINEP; o nome do arquivo diz 2021, a publicação é de 2022) | Harvard Dataverse doi:10.7910/DVN/5GVHTE |
| Luechinger, Schelker & Schmid (2024). Measuring Closeness in Proportional Representation Systems. *Political Analysis* 32: 101–114. doi:10.1017/pan.2023.22 | `Tese/Literatura/measuring-closeness-in-proportional-representation-systems.pdf` | Harvard Dataverse doi:10.7910/DVN/FBZMWN |

Nenhum dos dois está ainda em `Bibliography_base.bib` nem em `master_supporting_docs/`.

## A medida de ABD (2022)

Variável de corte do candidato *i* na lista *j* (fórmulas conferidas no XML JATS do artigo):

$$R_{i,j} = \frac{V_{i,j} - \tau_{i,j}}{V_{i,j} + V_{L,j}}$$

- $V_{i,j}$: votos do candidato; $V_{L,j}$: votos do **primeiro não eleito** da lista *j*.
- $\tau_{i,j}$: nível de votos em que o resultado muda. Não eleito: $\tau = \min(\tau^{intra},
  \tau^{inter})$, o menor nível que o elegeria. Eleito: $\tau = \max(\tau^{inter},
  \tau^{intra})$, o maior nível com que ainda perderia.
  - *intra*: ultrapassar o último eleito da lista (ou cair abaixo do primeiro não eleito);
  - *inter*: fazer a lista ganhar (perder) uma cadeira e estar na posição de recebê-la.
- Positiva para eleitos (0 a 1), negativa para não eleitos.

Detalhes que importam para replicar:

1. **O denominador é a soma, não a média.** O texto diz "average of candidate i's votes and the
   first loser's vote", mas a fórmula traz $(V_{i,j} + V_{L,j})$ sem ½. A base de replicação
   confirma a soma: `rv` dos eleitos vai de 0 a 1,0 (com ½ iria até 2). A "banda de 20%" do
   artigo é **|rv| < 0,1**, ou seja, 20% da *média* (V + V_L)/2. Conferido: |rv| < 0,1 dá
   exatamente os 1.324 candidatos da Tabela 03 (258 inter, 1.066 intra), e o `.do` tabula
   `abs(rv)<0.1` nesse ponto.
8. **Bandas na estimação:** as estimativas principais usam a banda ótima de `rdrobust`
   (Imbens & Kalyanaraman 2012; Calonico et al.), regressão local linear (`p(1)`), kernel
   uniforme e erros agrupados por UF. Como robustez, há `h(1)` (todos os candidatos) e
   polinômios de grau 2 e 3. Na heterogeneidade por magnitude, aparecem bandas fixas de 2%, 4%,
   10% e 20%. As bandas ótimas do teste de balanço (Tabela 05) ficam entre 11,9% e 32,4%.
2. **Inconsistência no exemplo:** para Antonio (Tabela 02), o limiar interpartidário é "just 01
   vote" na p. 12 (o empate) e "02" na p. 15 (vitória estrita). A convenção de empate não é dita.
3. **Erro na nota 10:** "the only relevant threshold is the intraparty threshold" para partido
   sem cadeira; o certo é *inter*partidário.
4. **Só ±1 cadeira.** O limiar *inter* considera apenas ganhar ou perder uma cadeira da lista.
5. **O código que constrói `rv` não foi depositado.** O Dataverse traz `01_Analysis.do` (só
   estimação: `rdrobust y rv, vce(cluster uf) p(1) kernel(uniform)`) e a base com `rv` e
   `inter_intra_proximidade` prontos: 23.544 candidatos a Deputado Federal, 1998–2014 (6.165 em
   2014). A base tem `ano, uf, nome_candidato, numero_partido, votos, eleito`, sem código de
   coligação.
6. **"Lista j" fica implícito.** De 1998 a 2014 a distribuição de cadeiras era por coligação;
   para o limiar *inter* a lista tem de ser a coligação. O artigo não diz como trata isso.
7. **Regras cobertas:** 1998–2014, isto é, sobras só para listas que atingem o QE, sem cláusula
   individual de 10% do QE, coligações, sem federações.

## A medida de LSS (2024)

Mesmo experimento mental (só os votos do candidato mudam), mas com solução analítica e geral:

- **Margem de partido** para *cada* número possível de cadeiras *i* = 1…n (não só ±1), com
  fórmula fechada para D'Hondt (maiores médias) e para Hare-Niemeyer (maiores restos).
- **Margem de candidato** em relação ao *i*-ésimo colega de lista.
- **Agregação:** $\text{vote margin}_h = \max_i \{\min(\text{party margin}_i,
  \text{candidate margin}_{h,i})\}$, definida no ponto de empate (cara ou coroa).
- **Normalização:** margem ÷ **eleitorado** do distrito (Cox, Fiva & Smith 2020).
- Inclui todos os candidatos, também de listas sem cadeira e listas com todos eleitos.
- Extensão para alianças (apêndice A); código R com as funções de margem no Dataverse.

## Diferenças

| Dimensão | ABD (2022) | LSS (2024) |
| --- | --- | --- |
| Experimento mental | só os votos de *i* mudam | igual |
| Cadeiras consideradas no limiar entre listas | ±1 cadeira da lista | todas as *i* = 1…n |
| Cálculo | descrito em prosa, código não publicado | fórmulas fechadas + funções em R publicadas |
| Fórmula de distribuição | regra brasileira (QE/QP + sobras), implícita | D'Hondt e Hare-Niemeyer genéricos; Brasil não tratado |
| Normalização | $(V_i + V_{L,j})$: escala local, relativa à força da lista | ÷ eleitorado do distrito |
| Escala | eleitos em [0, 1]; não eleitos podem passar de −1 | contínua e simétrica em torno de 0 |
| Empate | não especificado (o exemplo usa as duas convenções) | margem no ponto de empate |
| Coligações | implícitas ("lista j") | extensão explícita para alianças |

**Em termos práticos, a margem em votos é quase a mesma; o que muda é a normalização.** Na
regra brasileira, com voto único, as duas agregações (min/max de ABD e max-min de LSS) dão o
mesmo número de votos na imensa maioria dos casos. Elas só se afastam quando a candidatura
precisaria que a lista ganhasse duas ou mais cadeiras, caso que ABD não consideram. A diferença
substantiva está na normalização:

- ABD rejeitam dividir pelo total de votos porque isso "infla" eleições apertadas nos distritos
  grandes. A escala deles é relativa ao patamar de votos da própria lista.
- LSS dividem pelo eleitorado, o que mantém uma escala comum dentro do distrito.

**Por que isso importa na tese.** O desenho DiD da tese compara Federal (tratado) com Estadual
(controle) **na mesma UF**. Com LSS, o denominador (eleitorado da UF) é idêntico nos dois cargos
e a margem tem a mesma escala. Com ABD, o denominador depende dos votos das listas, que diferem
muito entre os dois cargos. Assim, uma banda "|R| < 0,2" não corresponde à mesma proximidade nos
dois cargos.

**Ponto comum que nenhum dos dois resolve:** desde 2018 há cláusulas que dependem do QE, que por
sua vez depende do total de votos válidos. São elas: candidato com ≥ 10% do QE (Lei
13.165/2015), sobras abertas a todas as listas em 2018 (Lei 13.488/2017) e, em 2022, sobras só
para listas com ≥ 80% do QE e candidatos com ≥ 20% do QE (Lei 14.211/2021), mais as federações
(Lei 14.208/2021). As fórmulas fechadas de LSS supõem D'Hondt sem pisos. Somar votos a *i* muda
o QE e pode ligar ou desligar essas cláusulas.

## Como implementar (proposta)

**Abordagem:** calcular a margem em votos **por busca**, não pelas fórmulas fechadas. Para cada
candidatura, procura-se o menor número inteiro de votos que, somado (não eleito) ou retirado
(eleito), muda o resultado. A cada passo refaz-se a distribuição completa com a regra do ano. É
o experimento mental dos dois artigos e cobre as cláusulas de 2018/2022 sem caso especial. O
resultado é monótono nos votos do próprio candidato, então a busca binária vale. Da mesma margem
saem as duas normalizações: `rv_abd` e `rv_lss`.

Protótipo: `R/funcoes_margem.R`, com distribuição de cadeiras por regra (`"2014"`, `"2018"`,
`"2022"`, `"dhondt"`) e margem por busca. Teste: `scripts/testar_exemplos_artigos.R`. O protótipo
reproduz os eleitos da Tabela 02 de ABD e as margens do exemplo D'Hondt de LSS, a menos de 1 voto
pela convenção de empate. O mesmo exemplo de ABD sob a regra de 2014 elegeria Antonio no lugar de
Miriam, o que mostra o quanto a regra do ano importa.

Etapas:

1. **Dados que faltam** (TSE, dados abertos), para 2014, 2018 e 2022, Federal e Estadual:
   - votos de legenda por partido (`votacao_partido_munzona`);
   - composição das listas (`consulta_cand`: coligação em 2014/2018, federação em 2022);
   - eleitorado por UF (`perfil_eleitorado`), para a normalização de LSS.

   As bases atuais (`eleitos_e_compet_*`) têm votos nominais, `QE`, `VOTOS_UF` e `eleito`, mas
   não têm votos de legenda nem identificador de lista.
2. **Validar a distribuição:** reproduzir 100% dos eleitos do TSE em cada UF × cargo × ano antes
   de calcular qualquer margem. Divergência é erro de regra, de dados ou de caso especial (p.ex.
   a 3ª fase de 2022 ou candidaturas *sub judice*).
3. **Replicar ABD em 2014 (Federal):** cruzar com `ReplicationAvelinoBidermanDesposato.tab`
   (6.165 candidatos de 2014) por `uf + nome_candidato + numero_partido` e comparar `rv`. É o
   único teste externo possível, já que o código deles não foi publicado.
4. **Conferir com LSS** onde as cláusulas não se aplicam: comparar a margem por busca com a
   fórmula fechada D'Hondt do código R deles.
5. **Uso na tese:** proporção de mulheres e de pessoas negras com |margem| abaixo de faixas
   fixas, por cargo e ano; comparação com o corte atual (≥ 10% do QE) e com as medidas de gasto
   de `explorations/competitividade-gasto/`.

## Decisões em aberto (da autora)

- **Normalização principal:** LSS (÷ eleitorado), pela comparabilidade Federal × Estadual na
  mesma UF, com ABD como robustez? Ou ABD, para dialogar com a literatura brasileira?
- **Uso:** só descritivo (competitividade) ou também como variável de corte em RD, por exemplo
  para o efeito de eleger uma mulher por margem estreita?
- **Ressalva conceitual:** as duas medidas são *ex post*, ou seja, dependem do resultado. Medem
  proximidade do limiar, não viabilidade prévia da candidatura. A medida pelo gasto continua
  sendo a opção *ex ante*.
