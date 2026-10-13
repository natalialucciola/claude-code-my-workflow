# Competitividade eleitoral pela margem de votos (ABD 2022 × LSS 2024)

**Status:** estudo + protótipo (exploração, 2026-10-13). Nada aplicado ainda aos dados da tese.

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
