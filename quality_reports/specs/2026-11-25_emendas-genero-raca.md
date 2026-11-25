# Especificação de Pesquisa: Emendas parlamentares, gênero e raça do legislador e retorno eleitoral

**Data:** 2026-11-25
**Status:** DRAFT (aguardando aprovação)
**Produto:** capítulo (tese/livro), ~10–12 mil palavras, com apêndice empírico replicável

---

## Objetivo

Mostrar se, e como, gênero e raça do(a) deputado(a) federal condicionam (1) **com o que** as emendas parlamentares são gastas, (2) **onde** são alocadas e (3) **quanto rendem em votos** nos municípios que as recebem na eleição seguinte.

---

## 1. Perguntas e hipóteses

### Bloco A — Com o quê (composição do gasto)

**PA.** Deputadas e deputados negros (pretos + pardos) alocam emendas a funções orçamentárias diferentes das de homens brancos, uma vez descontado o piso constitucional de saúde?

- **HA1 (agenda/representação substantiva):** mulheres alocam mais a saúde (acima do piso), assistência social, educação e direitos/cidadania; menos a urbanismo/pavimentação e agricultura.
- **HA2 (representação racial):** deputados(as) negros(as) alocam mais a assistência, educação e saneamento/habitação e a entidades sem fins lucrativos ligadas a comunidades negras/periféricas.
- **HA3 (modalidade):** grupos sub-representados usam menos "transferências especiais" (emendas Pix) e mais convênios/fundo a fundo — ou o contrário, se Pix reduzir a dependência de intermediação ministerial. (Hipótese bidirecional; tratar como exploratória.)

> Cuidado de desenho: desde a EC 86/2015 metade das emendas individuais deve ir para saúde. A variável de interesse em A é a **parcela discricionária** (excedente ao piso) e a composição *dentro* de saúde (atenção básica × MAC × custeio de entidades).

### Bloco B — Onde (geografia da alocação)

**PB.** O padrão espacial difere por gênero e raça: concentração vs. dispersão, recompensa à base eleitoral vs. conquista de novos redutos, e alinhamento com prefeitos?

- **HB1 (base eleitoral):** todos recompensam municípios onde tiveram mais votos em *t−1*, mas mulheres e negros(as), com bases eleitorais mais dispersas e menos "redutos" (Ames), têm alocação mais dispersa (HHI menor).
- **HB2 (intermediação local):** a alocação de homens brancos segue mais o alinhamento partidário com o prefeito; para mulheres/negros(as) a elasticidade ao alinhamento é menor (redes de *brokers* mais frágeis).
- **HB3 (destinação a entidades):** mulheres/negros(as) destinam maior fração a entidades privadas sem fins lucrativos e a capitais/grandes cidades.

### Bloco C — Retorno eleitoral

**PC.** Um real a mais de emenda paga em um município aumenta a votação do autor ali na eleição seguinte, e esse retorno é menor para mulheres e negros(as)?

- **HC1 (retorno médio):** efeito positivo e pequeno na votação municipal do autor (*credit claiming* local).
- **HC2 (penalidade de atribuição):** retorno por R$ menor para mulheres e negros(as) — eleitores e prefeitos atribuem menos crédito, ou prefeitos se apropriam do crédito.
- **HC3 (mecanismo via prefeito):** o retorno é maior quando o prefeito é aliado; a diferença por gênero/raça é mediada pelo alinhamento com o prefeito.
- **HC4 (visibilidade/modalidade):** obras visíveis (pavimentação, equipamentos) rendem mais que custeio; emendas Pix (menos rastreáveis) rendem mais ao prefeito que ao deputado.

---

## 2. Unidade de análise, escopo e período

| Dimensão | Escolha proposta | Status |
|---|---|---|
| Casa | Câmara dos Deputados (Senado como extensão) | ASSUMED |
| Tipo de emenda | Individuais (RP6) como núcleo; bancada (RP7), comissão (RP8) e relator/RP9 (2020–22) como contexto/robustez | ASSUMED |
| Período orçamentário | 2015–2026 (início do orçamento impositivo) | ASSUMED |
| Ciclos eleitorais | Legislaturas 2015–18, 2019–22, 2023–26 → eleições de 2018, 2022, 2026 | ASSUMED |
| Unidade A | deputado × ano × função/subfunção | CLEAR |
| Unidade B | deputado × município × legislatura | CLEAR |
| Unidade C | deputado candidato à reeleição × município × eleição | CLEAR |
| Raça | autodeclaração TSE (disponível desde 2014); negros = pretos + pardos; robustez com categorias separadas e com heteroclassificação | ASSUMED — **ver BLOCKED abaixo** |
| Valor | **pago** (inclui restos a pagar pagos), deflacionado (IPCA), per capita; empenhado como robustez | ASSUMED |

---

## 3. Dados

| Fonte | Conteúdo | Uso |
|---|---|---|
| Portal da Transparência — Emendas Parlamentares | autor, ano, função/subfunção, localidade do gasto, empenhado/liquidado/pago | A, B, C |
| Transferegov (antiga Plataforma +Brasil) | convênios e transferências especiais com município/entidade beneficiária, objeto | B, C (localização fina; objeto da obra) |
| SIOP / LOA | RP, valores autorizados, cotas por parlamentar | denominador; restrição orçamentária |
| FNS (fundo a fundo) | emendas de saúde por município | A (decomposição de saúde), B |
| TSE — candidatos | gênero, cor/raça, partido, ocupação, bens, reeleição | variáveis de tratamento e controles |
| TSE — votação por município/zona/seção | votos do deputado por município, *t−1* e *t+1* | B (base eleitoral), C (desfecho) |
| TSE — eleições municipais 2016/2020/2024 | partido e margem do prefeito | alinhamento (B, C; RDD) |
| API Câmara | mandatos, suplências, comissões, liderança | controles, exposição |
| IBGE / Atlas / Siconfi / DataSUS | população, renda, IDHM, % negros, capacidade fiscal, cobertura de saúde | controles e heterogeneidade |

**Problemas de dados a tratar explicitamente:**
- "Localidade do gasto" pode ser estado/"nacional": regra de imputação ao município via Transferegov/FNS; reportar % não localizável por grupo.
- Suplentes e trocas de mandato: atribuição da emenda a quem a indicou.
- Mudança de autodeclaração racial entre 2014, 2018 e 2022 (fenômeno documentado em 2020/2022, associado a cotas de financiamento): usar declaração **anterior** ao mandato e testar sensibilidade.
- RP9 (2020–22) não tem autoria pública confiável — tratar como ruído/controle, não como tratamento.

---

## 4. Estratégia empírica

### A — Composição
- Frações por função (soma 1) por deputado-ano: modelo de composição (fracional multinomial ou log-razões em relação a saúde-piso) com efeitos fixos de UF × ano e partido × ano; controles: senioridade, ideologia (escala de Power/Zucco ou IDEAL), ocupação prévia, bancada temática.
- Descritivo central: gráfico de distância por função (mulheres−homens; negros−brancos) e interseccional (4 grupos).

### B — Geografia
- Medidas por deputado-legislatura: HHI municipal, % para os top-5 municípios de votação, elasticidade alocação ↔ voto em *t−1*, % para municípios com prefeito do mesmo partido/coligação.
- Modelo diádico deputado × município: `Emenda_{dm} = β·Voto_{dm,t−1} + γ·(Voto × Mulher) + δ·Alinhado_{dm} + ... + FE_d + FE_m`.
- Alinhamento com prefeito identificado por **RDD em eleições municipais apertadas** (aliado vence por pouco vs. perde por pouco), heterogêneo por gênero/raça do deputado.

### Portão de decisão (descritivo → causal)

Fase 1 é descritiva: A, B e uma versão descritiva de C (correlação condicional entre emenda paga em *t* e variação da votação municipal em *t+1*, por grupo, com EF de deputado e de UF × ano). Avança-se para a Fase 2 (identificação causal abaixo) se ao menos uma das condições valer:
- diferença por gênero ou raça na composição (A) ou na elasticidade alocação–voto (B) estável entre legislaturas e não explicada por partido × UF × senioridade;
- diferença por grupo no gradiente emenda → votação (C descritivo) de magnitude substantiva, com IC que exclui zero.

Caso contrário, o capítulo fecha como descritivo, e o resultado nulo é um achado.

### C — Retorno eleitoral (Fase 2, condicional)
Endogeneidade óbvia: deputados enviam recursos onde esperam votos. Estratégias, em ordem de credibilidade:

1. **Painel diádico com EF deputado × município** (duas+ legislaturas): `ΔVoto_{dm,t+1} = β·EmendaPaga_{dm,t} + θ·(EmendaPaga × Grupo) + FE_{dm} + FE_{UF×t} + ε`. Explora variação temporal *dentro* do par.
2. **Choques de execução (timing de pagamento):** pagamento depende de contingenciamento, calendário do ministério e restos a pagar — fatores pouco controláveis pelo deputado. Comparar emendas indicadas com execução antes vs. depois da eleição (event study; desfecho: voto em *t+1*). Variante: empenhado mas não pago até a eleição como grupo de comparação.
3. **Instrumento shift-share:** cota total do deputado (choque agregado, ex.: aumento do valor das individuais e criação das emendas Pix em 2019/2020) × participação predeterminada do município na alocação da legislatura anterior.
4. **RDD prefeito aliado** como canal (HC3): retorno das emendas em municípios onde o aliado venceu por pouco.

Desfecho principal: participação do deputado nos votos válidos do município; secundários: reeleição (nível do deputado), votos do prefeito aliado nas municipais seguintes.

Inferência: erros-padrão agrupados por deputado (e two-way deputado/município); correção para múltiplos testes nas heterogeneidades interseccionais.

**Ameaça central para gênero/raça:** grupos diferem em partido, senioridade, região e tipo de base — a comparação é *condicional*, não causal sobre gênero/raça em si. O capítulo deve afirmar o efeito causal das emendas (Bloco C) e a **heterogeneidade descritiva-condicional** por grupo, sem atribuir causalidade à identidade do legislador. Robustez: reweighting/matching em partido × UF × senioridade × votação prévia.

---

## 5. Literatura de partida (verificar antes de citar — rodar `/lit-review` e `/verify-claims`)

- Pork e conexão eleitoral no Brasil: Ames (bases eleitorais concentradas/dispersas); Pereira & Mueller (emendas e apoio ao Executivo); Samuels (*pork barreling* e carreira); Firpo, Ponczek & Sanfelice (emendas e poder eleitoral local); Baião & Couto (eficácia do *pork barrel*).
- Alinhamento partidário e transferências: Brollo & Nannicini (transferências e prefeitos aliados, RDD).
- Gênero: Brollo & Troiano (prefeitas e políticas, RDD); Wylie (mulheres e partidos no Brasil); literatura de *credit claiming* e viés de atribuição por gênero.
- Raça: Bueno & Dunning (raça, recursos e representação no Brasil); trabalhos sobre autodeclaração racial de candidatos e cotas de financiamento (TSE 2020).

---

## 6. Requisitos

### MUST
- [ ] Base deputado × município × ano de emendas **pagas**, com regra de localização documentada e taxa de não-localização por grupo.
- [ ] Gênero e raça do TSE vinculados por CPF/ID entre ciclos; regra para mudanças de autodeclaração.
- [ ] Separação piso de saúde × parcela discricionária no Bloco A.
- [ ] Pelo menos uma estratégia de identificação para C além do painel com EF.
- [ ] Pipeline R numerado e reprodutível (`scripts/R/`), com outputs que alimentam as tabelas do capítulo.

### SHOULD
- [ ] Análise interseccional (mulher negra, mulher branca, homem negro, homem branco).
- [ ] RDD de prefeito aliado.
- [ ] Classificação do objeto das emendas (texto do Transferegov) em "visível" vs. "custeio".

### MAY
- [ ] Extensão ao Senado e às emendas de bancada.
- [ ] Mapa interativo da alocação por grupo.

---

## 7. Clareza

| Aspecto | Status | Nota |
|---|---|---|
| País / nível | ASSUMED | Brasil, deputados federais |
| Período | ASSUMED | 2015–2026; 2026 só entra se os dados de votação por município já estiverem consolidados |
| Tipo de emenda | ASSUMED | RP6 núcleo |
| Medida de raça | CLEAR (2026-11-25) | Autodeclaração TSE (desde 2014); usar a declaração do registro de candidatura anterior ao mandato; heteroclassificação descartada |
| Ênfase do capítulo | CLEAR (2026-11-25) | **Descritiva primeiro** (Blocos A, B e C descritivo). Identificação causal (C, estratégias 1–4) só se houver diferença descritiva relevante — ver "Portão de decisão" na seção 4 |
| Dados já disponíveis | CLEAR (2026-11-25) | Nenhum dado baixado. Partir de bases e códigos de trabalhos publicados — ver `quality_reports/lit_review_emendas_dados.md` |

---

## 8. Critérios de sucesso

- Três figuras-âncora: (1) composição por função × grupo; (2) elasticidade alocação–voto prévio × grupo; (3) coeficiente de retorno eleitoral × grupo com IC.
- Cada número citado no texto rastreável a um script (`/audit-reproducibility` PASS).
- Capítulo ≥ 80 no gate de qualidade antes de circular a coautores/orientador(a).

## Aprovação

[ ] Aprovado pela autora: ____
