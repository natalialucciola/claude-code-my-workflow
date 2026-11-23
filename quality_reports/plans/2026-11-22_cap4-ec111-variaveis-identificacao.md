# Plano: variáveis, grupo de comparação e inferência do Cap. 4 (EC 111)

**Status:** EXECUTADO em 22/11 (scripts R/10 e R/11; capítulo reescrito: Metodologia, Dados, Resultados, Discussão, Conclusão; H2 como realocação entre cargos). Sem commit.
**Data:** 2026-11-22
**Arquivo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd` (exibido como Cap. 4)
**Pedido da autora (22/11):** quatro itens da revisão da Metodologia:
1. reapresentar as variáveis;
2. igualar o grupo de comparação;
3. criar uma medida de investimento por candidatura;
4. tratar o agrupamento dos erros e o transbordamento.

Além disso: abandonar o jargão ("desfecho", "funil", "taxas", "parcelas") e descrever cada variável pelo nome. Avaliar se cada variável deve ficar e concentrar nas que importam: candidaturas, investimento e gasto, votos, competitividade (pelo voto e pelo gasto) e eleição. Avaliar se a distribuição das medidas de competitividade deve ir para Dados.

---

## 1. Diagnóstico do que existe hoje

São 14 variáveis em duas construções diferentes, com unidades e grupos de comparação diferentes:

| Variável atual | Construção | Unidade | Comparação implícita | Uso nos Resultados |
|---|---|---|---|---|
| Candidaturas | % do grupo na lista | lista | complemento (homens; não negras; demais) | H1, central |
| Receita total | % do grupo na lista | lista | complemento | H2, 16 menções |
| Transferências do partido | % do grupo na lista | lista | complemento | H2, resultado mais forte |
| Receita do partido / de outras fontes | % da receita total, por origem | lista | complemento | H2, mecanismo e falsificação |
| Recursos públicos (FEFC + FP) | % do grupo na lista | lista | complemento | 4 menções |
| Gasto | % do grupo na lista | lista | complemento | H2 |
| Votos nominais | % do grupo na lista | lista | complemento | H3 |
| Cadeiras | % do grupo entre os eleitos | disputa | complemento | H5, secundária |
| Competitiva pelo voto | taxa do grupo − taxa da comparação | disputa | **homens, brancas, homens brancos** | H4, central |
| Competitiva pelo gasto | idem | disputa | idem | H4 |
| Eleita | idem | disputa | idem | H5, principal |
| Parcela entre as competitivas | % do grupo entre as competitivas | disputa | complemento | H4, mecanismo |

Três problemas de método, além da linguagem:

- **P1. Duas medidas para a mesma pergunta, com respostas que podem divergir.** Nos estágios finais, competitividade e eleição são medidas por taxa, isto é, competitivas do grupo divididas por candidaturas do grupo. Nos estágios iniciais, a medida é a presença no total. O próprio capítulo mostra o efeito disso. A taxa de competitividade das mulheres "melhora" porque o federal ganhou muitos candidatos homens fracos, o que derruba a taxa dos homens (4.5.4.3), enquanto a presença das mulheres entre as competitivas não muda.
- **P2. As taxas dependem de uma variável que a própria emenda alterou.** O denominador de uma taxa é o número de candidaturas, e H1 mostra que a emenda mudou a composição das candidaturas. Uma medida condicionada à candidatura mistura o efeito sobre quem compete com o efeito sobre quem foi lançado: é um problema de seleção pós-tratamento. A presença do grupo no total de competitivas ou de eleitos não depende desse denominador.
- **P3. O grupo de comparação das mulheres negras muda entre as medidas.** Nas proporções, mulheres negras são comparadas com todas as demais candidaturas. Nas taxas, com homens brancos.

## 2. Proposta: uma só construção, variáveis com nome próprio

**Princípio.** Cada variável principal passa a ser *a proporção do grupo no total de X na lista ou na disputa*. O grupo de comparação é sempre explícito: é o complemento, ou seja, homens para mulheres, pessoas brancas e de outras cores para pessoas negras, e todas as demais candidaturas para mulheres negras. Uma proporção das mulheres que sobe 3 pontos é uma proporção dos homens que cai 3 pontos. A comparação com o grupo não beneficiado está, portanto, embutida em toda medida, e o texto passa a dizer isso com todas as letras.

A estimação continua a ser a diferença em diferenças entre o cargo federal e o estadual, antes e depois de 2018. O texto deixa de usar "tripla diferença" para as variáveis principais. A tripla diferença sobre taxas continua, como mecanismo (§2.2).

### 2.1 Variáveis principais (seis, uma por etapa)

| # | Nome no texto | Definição | Unidade | Anos | Situação |
|---|---|---|---|---|---|
| V1 | Proporção de candidaturas | % das candidaturas aptas da lista que são do grupo | lista | 2014–2026 | mantém |
| V2 | Proporção das transferências do partido | % dos recursos que a direção partidária transferiu às candidaturas da lista que foram para o grupo | lista | 2018–2026 | mantém; é a medida direta do investimento do partido |
| V3 | Investimento relativo por candidatura (**nova**, item 3) | valor médio transferido pelo partido por candidatura do grupo dividido pelo valor médio por candidatura do grupo de comparação, em % (100 = igualdade) | disputa | 2018–2026 | nova; ver §4 |
| V4 | Proporção do gasto | % da despesa contratada das candidaturas da lista feita pelo grupo | lista | 2018–2026 | mantém |
| V5 | Proporção dos votos | % dos votos nominais da lista dados ao grupo | lista | 2014–2026 | mantém |
| V6a | Proporção das candidaturas competitivas pelo voto | % das candidaturas eleitas ou a menos de 0,1 QE do limiar (margem de votos) que são do grupo | disputa | 2014–2026 | **promovida** (hoje é mecanismo) |
| V6b | Proporção das candidaturas competitivas pelo gasto | idem, pela margem de gasto | disputa | 2018–2026 | **nova construção**: conferir se o script 14 já calcula; se não, acrescentar |
| V7 | Proporção das cadeiras | % dos eleitos da disputa que são do grupo | disputa | 2014–2026 | **promovida** (hoje secundária); é o objetivo declarado da política |

São seis etapas (lançar, investir, gastar, votos, competitividade, eleição). A etapa do investimento tem duas medidas complementares, V2 (quanto do dinheiro vai para o grupo) e V3 (quanto cada candidatura do grupo recebe), e a competitividade tem duas (pelo voto e pelo gasto).

### 2.2 Variáveis que saem do corpo principal

| Variável | Destino | Justificativa |
|---|---|---|
| Receita total | sai do corpo; uma frase em V2 | Mistura a decisão do partido com a de doadores. A pergunta é sobre a estratégia do partido, e V2 mede isso diretamente. |
| Receita de outras fontes | fica só como **teste de falsificação** | É o único teste de falsificação propriamente dito: o voto em dobro não muda o incentivo dos doadores. |
| Recursos públicos (FEFC + FP) | apêndice | 4 menções e sobreposição com V2. |
| Taxa de competitivas e taxa de eleitas (grupo − comparação) | **mecanismo**, em H4/H5 | Explicam *por que* a taxa das mulheres sobe sem mudar a presença delas (P1, P2). Fica a seção 4.5.4.3, sem estatuto de resultado principal. |
| Decomposição competitivas × não competitivas (votos, gasto e transferências) | mecanismo, em H4 | É a evidência dos candidatos caça-níqueis: mantém. |

**Consequência para as hipóteses:** H1 a H6 continuam, cada uma ligada a uma variável nomeada (H2 = V2 + V3 + V4; H4 = V6a + V6b; H5 = V7). A conclusão de H4 ("não confirmada") não deve mudar, porque a presença entre as competitivas já não mudava. Isso será conferido. Para H5, a medida principal passa a ser a proporção das cadeiras. Mulheres negras nas cadeiras eram um "indício a confirmar" e passam a ser o resultado principal de H5 para esse grupo, com o pré-teste reportado.

## 3. Grupo de comparação das mulheres negras (item 2)

- **Recomendação revista:** usar o **complemento**, ou seja, todas as demais candidaturas, em todas as variáveis principais. É a única escolha coerente com o princípio do §2, em que toda variável é a proporção do grupo no total.
- Na resposta anterior recomendei homens brancos. Revejo essa recomendação porque as taxas saem do corpo principal (§2.2).
- O contraste com homens brancos, mais informativo do ponto de vista substantivo, entra como uma linha adicional para V7 (cadeiras) e V6a, reportada à parte. O mesmo vale para a tripla diferença do mecanismo, que já usa homens brancos.

## 4. Investimento relativo por candidatura (item 3)

**Por que é necessária:** V2 sobe se o partido investe mais em cada candidata, mas também se apenas lança mais candidatas e mantém o valor por cabeça. As magnitudes atuais (+3 p.p. em candidaturas, +12 p.p. em transferências) sugerem investimento real, mas o capítulo não separa as duas coisas.

**Definição proposta (V3):** razão entre as médias por candidatura, na disputa (UF × cargo):

  V3 = 100 × (transferências do partido ao grupo / nº de candidaturas do grupo) ÷ (transferências ao grupo de comparação / nº de candidaturas do grupo de comparação)

Por que a disputa e a razão das médias:
- na lista, muitas listas pequenas têm soma zero para um dos grupos, e a razão fica indefinida;
- a razão das médias não tem o problema dos zeros que o log individual teria;
- a leitura é direta: "em 2018, cada candidata federal recebia em média X centavos para cada real recebido por um candidato".

A estimação é a mesma diferença em diferenças, com o mesmo agrupamento por UF (§5).

**Alternativas avaliadas:**
- (a) diferença entre a proporção das transferências e a proporção das candidaturas. É simples e aditiva, mas depende da composição de partida;
- (b) regressão no nível da candidatura com log(1 + transferência). É sensível aos zeros e à escala.

Recomendo V3 como principal e (a) como conferência.

**Também:** V3 por faixa de competitividade (competitivas e não competitivas). Mostra se o valor por candidata subiu entre as candidaturas com chance ou só entre as caça-níqueis. Isso liga V3 ao mecanismo de H4.

**Script:** novo `explorations/ec111-did-2026/R/10_investimento_por_candidatura.R`. Lê `data/processed/` e usa a mesma função `estimar()` do script 03 (copiada ou extraída para `funcoes_persistencia.R`).

## 5. Inferência e transbordamento (item 4)

### 5.1 Agrupamento dos erros por UF

- Hoje as variáveis na lista usam `clustervars = "id"` (lista) em `03_did_event_study.R:101`. O tratamento varia por cargo dentro da UF, e as listas federais de uma mesma UF recebem o mesmo choque.
- Passa a ser `clustervars = c("id", "uf")`, a mesma convenção dos scripts 05 e 14 de competitividade (permitido pela regra de DiD do projeto: até 2, um igual a `idname`).
- Com 26 agrupamentos e um só cargo tratado, o bootstrap multiplicador pode subestimar a incerteza. Como conferência, o p-valor por *wild cluster bootstrap* (Webb, por UF, via `fwildclusterboot` na regressão da @eq-reg-ec111) entra numa coluna da tabela de conferência, não no texto. A decisão de 18/11 de tirar a inferência por randomização do corpo continua valendo.
- **Efeito esperado:** intervalos mais largos nas variáveis de lista. Pela randomização de 17/11, podem perder significância os votos das mulheres em 2022 e o gasto das mulheres em 2026. As transferências e as candidaturas devem resistir (p < 0,03 na randomização). O texto será ajustado ao que sair, sem decidir antes.

### 5.2 Transbordamento entre os cargos

O problema não se elimina, mas se torna visível e tem direção conhecida:

1. **Níveis por cargo para as seis variáveis principais**, não só para as transferências. O script 06 já faz isso para as variáveis na lista e precisa ser estendido para V3, V6 e V7. Os níveis entram como figura (já existe `niveis_por_cargo`) e sustentam um parágrafo em cada hipótese.
2. **Leitura condicional (corrigido em 22/11).** Se o estadual cai por causa do tratamento, a DiD superestima o efeito, porque soma o ganho do federal com a perda do estadual. A variação só do federal não é limite inferior: ela depende da tendência que o estadual teria sem a emenda, que não se observa. O texto reporta os dois componentes (variação do federal e do estadual) e diz que a DiD é um limite superior *se* a queda do estadual vier do deslocamento de recursos. Isso é feito para V2 e V3, onde o transbordamento já foi detectado.
3. **Pré-teste do estadual:** para V1, V5, V6 e V7, que existem em 2014, comparar a mudança do estadual entre 2018 e 2022 com a mudança entre 2014 e 2018. Uma quebra no estadual exatamente em 2022 é indício de transbordamento. Para recursos não há 2014, e isso fica declarado como limite.

## 6. Reorganização do texto

### Metodologia (4.3)

- **4.3.1 Estratégia de identificação:** comparação federal × estadual; hipótese de tendências paralelas; pré-teste.
- **4.3.2 Modelo e estimação:** equações; persistência (com o M4 corrigido).
- **4.3.3 Variáveis:** tabela nova (§2.1), organizada por etapa, com colunas Variável, Definição, Grupo de comparação, Unidade, Anos. Cada variável recebe um parágrafo curto, em linguagem direta, que diz o que mede e por que importa para a estratégia do partido. As margens de votos e de gasto ficam aqui, só a definição e o cálculo; a validação fica na nota de rodapé que já existe.
- **4.3.4 Falsificação, inferência e limites:**
  - receita de outras fontes como teste de falsificação (M2);
  - agrupamento por UF e poucos agrupamentos (M1);
  - transbordamento e mudanças concorrentes (M7, sem o "São três." solto).

### Dados (4.4), parte nova "Distribuição das medidas de competitividade"

**Recomendo mover.** Saem de Variáveis e vão para Dados:
- os números de 2018 (7,1% contra 15,9%; 8,2% contra 16,6%, já com o M5 corrigido);
- as duas figuras de faixas de margem;
- a comparação 27,6% contra 0,8% das bandas largas;
- a correlação de 0,51 a 0,75 entre as margens e os 50% a 66% de eleitos pelo gasto.

Em Variáveis fica só a justificativa da banda de 0,1 QE, em uma frase com remissão a Dados. A correlação entre as margens é descrição da amostra, e não definição, por isso também vai para Dados.

### Resultados (4.5)

- Uma tabela principal: as seis etapas (V1–V7) × três grupos, com as colunas pré-teste 2014, 2022, 2026, diferença 2026 − 2022 e média pós. Ela substitui `tbl-funil` e `tbl-funil-recursos`.
- A tripla diferença sobre taxas (`tbl-ddd`) e a decomposição (`tbl-decomposicao`) ficam em H4 como mecanismo.
- `tbl-receita` é reduzida à falsificação.
- Os títulos das subseções deixam de usar "funil" (hoje "H1 · Candidaturas" etc. podem ficar).

### Linguagem (todo o capítulo)

- Trocas: "desfecho" → nome da variável ou "variável"; "funil" → "etapas da candidatura" (da candidatura à eleição); "parcela" → "proporção"; "taxa" só para a taxa de eleição e a de competitivas no mecanismo, sempre com a definição na primeira ocorrência.
- Busca final: 0 ocorrências de "desfecho" e "funil" fora das citações.
- Introdução, Discussão e Conclusão revisadas para os números novos e para os nomes das variáveis.

## 7. Ordem de execução e verificação

1. **Scripts (sem tocar no texto):**
   - 03 com o agrupamento por UF;
   - V6b e V7 na mesma estimação;
   - novo script 10 (V3);
   - 06 estendido (níveis);
   - limites e pré-teste do estadual.

   Conferência: o ATT pontual de V1, V2, V4 e V5 não muda (só os EP); o ATT de V6a e V7 confere com `cmshare` e `cadeira` antigos.
2. **Tabela de números novo × antigo** (`quality_reports/merges/2026-11-xx_cap4_numeros.md`), para a autora ver o que muda de significância antes de qualquer reescrita.
3. **Ponto de checagem com a autora:** só então reescrever Metodologia, Dados, Resultados e as seções de abertura e fecho.
4. **Texto:**
   - diff de números (nenhum número antigo some sem estar na tabela do passo 2);
   - 0 referências não resolvidas;
   - rótulos `{#tbl-…}` presentes (o editor visual apagou-os em 21/11);
   - render sem avisos; score ≥ 90.
5. Antes de republicar: ler os comentários abertos (memória de feedback) e fazer o commit das edições da autora de 21/11 **separado** e antes deste trabalho.

## 8. Decisões pedidas à autora

- **D1.** Adotar a proporção no total como construção única das variáveis principais, com as taxas rebaixadas a mecanismo (§2)? *Recomendado.*
- **D2.** Variáveis que saem: receita total (frase em V2), recursos públicos (apêndice), receita de outras fontes (só falsificação)? *Recomendado.*
- **D3.** Comparação das mulheres negras com o complemento, e homens brancos como linha adicional (§3)? *Recomendado.*
- **D4.** V3 como razão das médias por candidatura na disputa (§4)? *Recomendado.*
- **D5.** Agrupamento por UF em todas as variáveis, aceitando possível perda de significância, com o wild bootstrap só na tabela de conferência (§5.1)? *Recomendado.*
- **D6.** Mover a distribuição das medidas de competitividade para Dados (§6)? *Recomendado.*
- Antes de tudo: posso fazer o commit das suas edições de 21/11 (com os rótulos de tabela recolocados), para separar o seu texto do trabalho novo?

---

## Revisão de 22/11 após objeção da autora (substitui D1 e o §2.2 no ponto das taxas)

A autora objetou que a entrada de candidaturas masculinas fracas é resposta partidária e, portanto, parte do efeito, e que comparar as taxas de sucesso entre grupos é desejável. **Ela tem razão no princípio.** A justificativa de "seleção pós-tratamento" estava errada para o que o capítulo afirma: a diferença de taxas na disputa é um desfecho agregado legítimo, e a sua diferença em diferenças é um efeito causal bem definido sobre essa diferença. A ressalva vale só para uma leitura individual ("cada candidata ficou mais perto da cadeira"), que o capítulo não precisa fazer.

O problema real é de **atribuição**, e a evidência é do próprio capítulo (4.5.4.3):
- a expansão de candidaturas no federal já ocorria de 2014 para 2018 (excesso de 1,7 a 3,1 por cadeira sobre o estadual), antes do voto em dobro;
- o fim das coligações com o limite de M + 1 explica de 20% a 35% do aumento.

Na diferença em diferenças, tudo o que é específico do federal depois de 2018 é atribuído à EC 111. Parte da queda da taxa dos homens pode responder a outros incentivos que também valem só para o federal (fundos e cláusula atrelados aos votos para a Câmara). Isso é uma questão de tendências paralelas, conferida pelo pré-teste da diferença de taxas, e não um motivo para rebaixar a medida.

**Nova recomendação (D1 revista):** competitividade e eleição passam a ter duas medidas principais cada, que respondem a perguntas distintas:
- **presença:** a proporção do grupo entre as competitivas e entre as cadeiras. Pergunta: a representação mudou?
- **sucesso relativo:** a diferença entre a taxa do grupo e a do grupo de comparação. Pergunta: as chances relativas mudaram?

As duas são lidas juntas. Taxa que se aproxima com presença parada indica que a mudança veio do grupo de comparação. Isso é parte da estratégia partidária, mas a atribuição dessa parte à EC 111 depende do pré-teste. O §2.2 deixa de rebaixar as taxas a mecanismo.

**D3 com a revisão:** o mesmo grupo de comparação nas duas medidas. Recomendação: o complemento nas duas, com homens brancos como linha adicional. A autora decide.
