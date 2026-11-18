<!-- Material retirado do Cap. 4 (03-ec111-competitividade-eleitoral.qmd) em 2026-11-18, por decisão da autora,
antes do envio ao orientador. Não é incluído no livro. Plano: quality_reports/plans/2026-11-18_cap4-ec111-robustez-fora.md.
Fontes dos números: explorations/ec111-did-2026/output/{regressao_did,regressao_did_robustez,randomizacao_did}.csv,
explorations/competitividade-eleitoral/output/{ddd_resultados,honestdid_*}.csv. Scripts: 08_regressao_did.R, 10_honestdid.R. -->

# Apêndice (rascunho): robustez, sensibilidade e inferência por randomização

## Tabela tbl-funil-ec111 com as colunas da inferência por randomização (versão de 17/11)

| Desfecho | Grupo | Pré-teste 2014 | 2022 | 2026 | Diferença 2026 − 2022 | Federal × Pós | p (rand.) |
|:---|:---|---:|---:|---:|---:|---:|---:|
| Candidaturas (% da lista) | Mulheres | −1,0 | +3,2\* | +2,6\* | −0,6 | +2,9\* | 0,028 |
|  | Pessoas negras | +2,6 | +5,0\* | +5,5\* | +0,5 | +5,3\* | 0,003 |
|  | Mulheres negras | +0,3 | +3,8\* | +4,1\* | +0,3 | +3,9\* | < 0,001 |
| Votos nominais (% da lista) | Mulheres | −0,4 | +4,0\* | +2,1 | −1,9 | +3,1 | 0,178 |
|  | Pessoas negras | −0,5 | +3,5 | +2,8 | −0,7 | +3,1 | 0,172 |
|  | Mulheres negras | +1,0 | +3,8\* | +3,9\* | 0,0 | +3,9\* | 0,010 |
| Cadeiras (% dos eleitos da UF) | Mulheres | −1,9 | −2,1 | +1,8 | +3,9 | −0,2 | 0,955 |
|  | Pessoas negras | −3,6 | −5,0 | +1,9 | +6,9 | −1,6 | 0,717 |
|  | Mulheres negras | +0,1 | +0,5 | +3,5\* | +3,0 | +2,0 | 0,113 |

: Efeito do voto em dobro sobre candidaturas, votos e cadeiras, federal × estadual, base 2018 (pontos percentuais). Candidaturas e votos: listas partido × UF, painel balanceado, sem ponderação; cadeiras: UF × cargo. O pré-teste é a mesma conta feita entre 2014 e 2018. \* IC de 95% exclui zero (erros agrupados por lista; por UF nas cadeiras). Federal × Pós: termo único da @eq-reg-ec111 (2018 contra 2022 e 2026), com \* quando o IC de 95% exclui zero. p (rand.): p-valor da inferência por randomização, com 10.000 sorteios da troca dos rótulos de cargo dentro de cada UF. {#tbl-funil-ec111}

## Tabela tbl-funil-recursos-ec111 com as colunas da inferência por randomização (versão de 17/11)

| Desfecho (% da lista) | Grupo | 2022 | 2026 | Diferença 2026 − 2022 | Federal × Pós | p (rand.) |
|:---|:---|---:|---:|---:|---:|---:|
| Receita total | Mulheres | +6,1\* | +5,6\* | −0,5 | +5,8\* | 0,033 |
|  | Pessoas negras | +3,2 | +3,7 | +0,5 | +3,4 | 0,200 |
|  | Mulheres negras | +4,5\* | +5,6\* | +1,0 | +5,0\* | 0,006 |
| Transferências do partido | Mulheres | +12,4\* | +12,2\* | −0,2 | +12,3\* | < 0,001 |
|  | Pessoas negras | +3,4 | +4,1 | +0,7 | +3,7 | 0,162 |
|  | Mulheres negras | +8,1\* | +8,4\* | +0,3 | +8,2\* | < 0,001 |
| Recursos públicos (FEFC + FP) | Mulheres | +8,4\* | +7,4\* | −1,0 | +7,9\* | 0,011 |
|  | Pessoas negras | +5,1\* | +4,3 | −0,8 | +4,7\* | 0,074 |
|  | Mulheres negras | +6,4\* | +5,4\* | −0,9 | +5,9\* | 0,003 |
| Gasto | Mulheres | +7,1\* | +5,0\* | −2,2 | +6,1\* | 0,034 |
|  | Pessoas negras | +3,6 | +3,0 | −0,6 | +3,3 | 0,239 |
|  | Mulheres negras | +5,3\* | +5,2\* | −0,1 | +5,2\* | 0,007 |

: Efeito do voto em dobro sobre recursos e gasto, federal × estadual, base 2018 (pontos percentuais). Listas partido × UF, painel balanceado, sem ponderação. \* IC de 95% exclui zero. Sem pré-teste, porque em 2014 vigorava a doação empresarial. Federal × Pós: termo único da @eq-reg-ec111 (2018 contra 2022 e 2026), com \* quando o IC de 95% exclui zero. p (rand.): p-valor da inferência por randomização, com 10.000 sorteios da troca dos rótulos de cargo dentro de cada UF. {#tbl-funil-recursos-ec111}

## Tabela tbl-ddd-ec111 com as colunas da inferência por randomização (versão de 17/11)

| Desfecho | 2014 (pré) | 2022 | 2026 | Federal × Pós | p (rand.) | Dif. 2026 − 2022 |
|:---|---:|---:|---:|---:|---:|---:|
| *Mulheres − homens* |  |  |  |  |  |  |
| Competitiva pelo voto | −0,8 \[−3,9; 2,4\] | 3,4\* \[0,4; 6,4\] | 3,9\* \[0,0; 7,7\] | 3,6\* \[0,9; 6,3\] | 0,012 | +0,5 \[−2,1; 3,1\] |
| Competitiva pelo gasto | 0,1 | 2,2 \[−0,5; 5,0\] | 0,4 \[−4,5; 5,4\] | 1,3 \[−1,6; 4,3\] | 0,373 | −1,8 |
| Eleita | −2,3 | 0,9 | 2,9\* \[0,1; 5,8\] | 1,9 | 0,104 | +2,1\* \[0,2; 3,9\] |
| *Pessoas negras − brancas* |  |  |  |  |  |  |
| Competitiva pelo voto | −5,8\* \[−10,7; −0,8\] | 0,9 | 5,7\* | 3,3\* | 0,057 | +4,8\* |
| Competitiva pelo gasto | −4,9\* | −1,3 | 0,8 | −0,2 | 0,891 | +2,1 |
| Eleita | −4,5\* \[−8,6; −0,4\] | 0,3 | 3,9\* | 2,1 | 0,138 | +3,6\* |
| *Mulheres negras − homens brancos* |  |  |  |  |  |  |
| Competitiva pelo voto | −4,2 | 3,9 | 9,1\* | 6,5\* | 0,005 | +5,2 |
| Competitiva pelo gasto | −1,9 | 2,0 | 1,9 | 1,9 | 0,374 | −0,1 |
| Eleita | −5,1\* | 1,5 | 6,7\* | 4,1\* | 0,011 | +5,2\* |

: Tripla diferença (grupo × cargo × período) na taxa de candidaturas competitivas (eleitas ou a menos de 0,1 QE do limiar, em votos ou em gasto) e na taxa de eleitas, base 2018 (pontos percentuais). Unidade UF × cargo, sem DF, sem ponderação. Colunas de ano: bandas uniformes de 95% (bootstrap multiplicador com 25.000 repetições, agrupado por UF). Federal × Pós (termo único da @eq-reg-ec111, igual à média dos efeitos de 2022 e 2026) e diferença: IC de 95% pontual, com erros agrupados por UF. p (rand.): p-valor da inferência por randomização (10.000 sorteios). \* Intervalo exclui zero. No gasto, 2014 não é lido como pré-teste (doação empresarial). {#tbl-ddd-ec111}

## Metodologia: parágrafo de inferência (versão com a randomização)

A correção usual é agrupar os erros no nível em que o tratamento varia, o que se faz aqui por lista nos desfechos de parcela e por UF nos de taxa. Essa correção, porém, se apoia numa aproximação que só funciona bem com muitos grupos. Com 26 UFs e um único cargo tratado em todas elas ao mesmo tempo, os erros agrupados tendem a apontar como significativos efeitos que não o são [@ConleyTaber2011_few_policy_changes; @MacKinnonWebb2020_randomization]. Por isso, os efeitos são acompanhados de um p-valor obtido por *inferência por randomização*, a alternativa indicada para esses casos [@BuchmuellerDiNardoValletta2011_hawaii; @Cunningham2021_mixtape; @MacKinnonWebb2020_randomization].

## Metodologia: parágrafo que explica a inferência por randomização

O raciocínio parte da hipótese de que a emenda não teve efeito nenhum. Sob essa hipótese, os rótulos de cargo tratado e de cargo de controle seriam intercambiáveis dentro de cada UF, e trocar os dois cargos de uma UF apenas inverteria o sinal da contribuição dela para o efeito estimado. Sorteia-se, então, para cada UF, se os rótulos são trocados ou mantidos, e o efeito é estimado de novo. Repetido 10.000 vezes, o procedimento produz a distribuição dos efeitos que surgiriam apenas por acaso, dada a variação observada entre as UFs. O p-valor é a proporção desses sorteios em que o efeito é, em valor absoluto, pelo menos tão grande quanto o observado. Como os rótulos são trocados por UF, e não por lista, o procedimento leva em conta que as listas de uma mesma UF compartilham choques locais, o que o agrupamento por lista não faz. O procedimento não depende de aproximações para muitos grupos, mas não resolve o problema de identificação. Um choque nacional que afetasse o cargo federal em todas as UFs no mesmo sentido também seria registrado como efeito, e separar a emenda de choques desse tipo continua a depender do pré-teste, das falsificações e da análise de sensibilidade.

## Metodologia: lista das especificações de robustez

Os demais desfechos são lidos como mecanismo ou como secundários, e as variações de especificação (ponderação pelos votos da lista em 2018, painel desbalanceado, medida no nível da disputa, normalizações de ABD e LSS, gasto relativo ao último eleito) como robustez.

## Variáveis: ponderações

As ponderações (pelos votos da lista em 2018, pelo número de candidaturas da disputa) entram como robustez, para verificar se os efeitos se concentram em listas ou UFs pequenas.

## Variáveis: normalizações de ABD e LSS

As normalizações originais de @AvelinoBidermanDesposato2022_incumbency (pelos votos da candidatura e do primeiro não eleito da lista) e de @LuechingerSchelkerSchmid2024_closeness (pelo eleitorado) entram como robustez.

## Variáveis: medida de gasto relativo ao último eleito

Como robustez, uso uma medida mais simples, o gasto da candidatura em relação ao do último eleito da sua lista (competitiva quando chega a metade dele).

## Dados: painel desbalanceado

presentes nas quatro eleições, com o painel desbalanceado como robustez, já que fusões e federações fazem listas surgirem e desaparecerem [@SantAnnaXu2023_compositional].

## H1 (versão com ponderação, nível da disputa e randomização)

H1 é confirmada para os três grupos, com magnitude modesta e concentrada em listas pequenas (@tbl-funil-ec111). A parcela de mulheres nas listas federais sobe cerca de 3 pontos em relação às estaduais, em 2022 e em 2026, com pré-teste próximo de zero. Partindo de 31,7% em 2018, é um aumento modesto, e ele se reduz à metade e perde significância quando as listas são ponderadas pelos votos que tiveram em 2018 (+1,6 nas duas eleições). A parcela de pessoas negras sobe cerca de 5 pontos, mas o efeito desaparece com a ponderação (+0,4 em 2022 e +0,1 em 2026), sinal de que o aumento se concentra em listas pequenas. Para mulheres negras, o efeito é de cerca de 4 pontos, sobre uma base de 14,0% em 2018, também concentrado em listas pequenas. No nível da disputa, que soma as listas, os aumentos se mantêm, de 2 a 4 pontos, com exceção do de pessoas negras em 2022 (+2,6, sem significância). No termo único, os efeitos são de 2,9, 5,3 e 3,9 pontos para mulheres, pessoas negras e mulheres negras, e os três se distinguem do acaso também pela inferência por randomização (p de 0,028, 0,003 e menor que 0,001).

## H2: ponderação

Ponderado pelos votos das listas, o efeito é ainda maior (+16,8 e +14,5).

## H2: randomização

Para pessoas negras, só os recursos públicos de 2022 sobem de forma distinguível de zero, e esse aumento não se distingue do acaso pela inferência por randomização (p = 0,061). Para as mulheres e as mulheres negras, os efeitos sobre as transferências resistem com folga a esse critério (p menor que 0,001 no termo único). Entre os efeitos sobre as mulheres, só o do gasto em 2026 perde significância por ele (p = 0,085).

## H3: abertura com a randomização

H3 é confirmada para mulheres negras e não é confirmada para pessoas negras (@tbl-funil-ec111). Para as mulheres, a evidência é fraca. O ganho de votos de 4,0 pontos em 2022 se distingue de zero com erros agrupados por lista, mas não pela inferência por randomização entre UFs (p = 0,13), e cai para 2,1 em 2026, sem significância por nenhum dos dois critérios. No termo único, o efeito é de 3,1 pontos (p = 0,18).

## H3: aproximação da sensibilidade

Uma aproximação da sensibilidade a violações de tendências paralelas (o conjunto identificado sob magnitudes relativas, somado a ±1,96 erro-padrão, sem a inferência completa de @RambachanRoth2023_parallel_trends) aponta na mesma direção. O efeito de 2022 resiste a violações de até cerca de 0,6 vez a pré-tendência observada, e o de 2026 não resiste a nenhuma.

## H3: randomização (mulheres negras)

, e resiste à inferência por randomização nas duas eleições (p = 0,017 e 0,040).

## H4: randomização

A inferência por randomização indica que esse padrão vai além do acaso (p = 0,012 no termo único). Ela não distingue, contudo, a emenda de um choque comum ao cargo federal em todas as UFs, e é dessa distinção que depende a leitura do resultado, examinada nas subseções seguintes.

## H4: parágrafo e tabela de robustez da tripla diferença

O resultado pelo voto é sensível à especificação (@tbl-ddd-robustez-ec111). Ponderado pelo número de candidaturas, o que dá mais peso às UFs grandes, o termo único cai para 2,3 pontos e deixa de ser significativo. Com a normalização de @LuechingerSchelkerSchmid2024_closeness, fica em 1,2 e também não é significativo. Ele se mantém quando se excluem as UFs com 8 cadeiras federais, onde a distância até o limiar é mais grosseira, e diminui um pouco quando se excluem os incumbentes.

| Especificação (mulheres − homens) | 2014 (pré) | 2022 | 2026 | Federal × Pós | Dif. 2026 − 2022 |
|:---|---:|---:|---:|---:|---:|
| *Competitiva pelo voto* |  |  |  |  |  |
| Principal (@tbl-ddd-ec111) | −0,8 | 3,4\* | 3,9\* | 3,6\* | +0,5 |
| Ponderado pelo número de candidaturas | 0,6 | 2,4 | 2,3 | 2,3 | −0,1 |
| Sem UFs com 8 cadeiras | 0,9 | 3,9\* | 4,9\* | 4,4\* |  |
| Sem incumbentes (2018–2026) | — | 3,0\* | 2,3 | 2,7 |  |
| Controlando o log da magnitude | −1,1 | 4,6\* | 6,6\* |  |  |
| Só magnitudes comuns aos dois cargos (24 a 70; 7 distritos federais) | −3,5 | 3,2\* | 4,0\* |  |  |
| Normalização de ABD | −2,4 | 1,9 | 3,1 | 2,5\* | +1,2 |
| Normalização de LSS | −2,0 | 0,5 | 1,8 | 1,2 | +1,2 |
| *Competitividade pelo gasto* |  |  |  |  |  |
| Margem de gasto, principal (@tbl-ddd-ec111) | 0,1 | 2,2 | 0,4 | 1,3 | −1,8 |
| Eleita pelo gasto | −0,5 | 0,8 | 0,0 | 0,4 | −0,8 |
| Gasto ≥ metade do último eleito da lista | 3,5 | 3,2 | 3,4 | 3,3 | +0,2 |

: Robustez da tripla diferença para mulheres − homens, base 2018 (pontos percentuais). Unidade UF × cargo, sem DF, sem ponderação salvo indicação; mesmas bandas e intervalos da @tbl-ddd-ec111. \* Intervalo exclui zero. As duas linhas de magnitude vêm de regressões por distrito da variação em relação a 2018, com erros agrupados por UF e IC pontual de 95%. No gasto, 2014 não é lido como pré-teste. ABD = @AvelinoBidermanDesposato2022_incumbency; LSS = @LuechingerSchelkerSchmid2024_closeness. {#tbl-ddd-robustez-ec111}

## H4: medidas alternativas de gasto

, assim como a eleição pelo gasto (+0,8 e 0,0) e o gasto em relação ao do último eleito da lista (+3,2 e +3,4; @tbl-ddd-robustez-ec111).

## H4 (4.5.4.3): placebo nas magnitudes comuns

Na taxa de competitivas, a evidência de uma tendência anterior é bem mais fraca. Nas magnitudes comuns aos dois cargos, a diferença entre mulheres e homens aumenta 3,2 pontos de 2018 para 2022 e já tinha aumentado 3,5 pontos de 2014 para 2018, período sem o incentivo que serve de placebo (@tbl-ddd-robustez-ec111). O placebo tem a mesma ordem de grandeza do efeito, mas é impreciso, com erro-padrão de 2,2 pontos. Além disso, essa faixa reúne só 7 distritos federais, os das UFs mais populosas, diante de 24 estaduais, e deixa de comparar os dois cargos dentro da mesma UF. Na amostra completa, controlando o logaritmo da magnitude, o placebo é de 1,1 ponto, sem significância, e o efeito de 2022 sobe para 4,6. Há, portanto, uma tendência anterior clara na expansão de candidaturas, mas não na aproximação das mulheres na taxa de competitivas. A fragilidade dessa aproximação vem dos outros resultados de H4: a sensibilidade à ponderação e à normalização, a composição das competitivas, que não mudou, e a queda da taxa dos homens.

## H4 (4.5.4.4): sensibilidade formal inteira (HonestDiD)

#### Sensibilidade formal {#sec-h4-sensibilidade-ec111}

A análise de sensibilidade de @RambachanRoth2023_parallel_trends formaliza a preocupação com tendências anteriores. Sob a restrição de magnitudes relativas, a violação de tendências paralelas depois de 2018 pode ser até M̄ vezes a observada de 2014 para 2018. O *valor de quebra* é o maior M̄ com que o intervalo robusto de 95% ainda exclui zero (@tbl-honestdid-ec111, @fig-honestdid-ec111).

| Desfecho (efeito médio 2022–2026) | Sem peso: estimativa | Sem peso: IC original | Sem peso: quebra M̄ | Com peso: estimativa | Com peso: IC original | Com peso: quebra M̄ |
|:---|---:|:---:|---:|---:|:---:|---:|
| *Mulheres* |  |  |  |  |  |  |
| Taxa de competitivas (mulheres − homens) | 3,6 | \[0,7; 6,5\] | 0,25 | 3,1 | \[0,2; 6,0\] | 0 |
| Taxa de eleitas (mulheres − homens) | 1,9 | n.s. | — | 2,2 | \[0,0; 4,3\] | 0 |
| \% de mulheres entre as competitivas | 1,7 | n.s. | — | 1,4 | n.s. | — |
| Mulheres não competitivas por cadeira | 2,2 | \[1,7; 2,7\] | 1,5 | 1,7 | \[1,0; 2,5\] | 0,75 |
| Não competitivas por cadeira (mulheres − homens) | −1,2 | \[−1,9; −0,5\] | 0,25 | −1,1 | \[−1,9; −0,3\] | 0,25 |
| *Pessoas negras* |  |  |  |  |  |  |
| Taxa de competitivas e % entre as competitivas | — | n.s. | — | — | n.s. | — |
| Pessoas negras não competitivas por cadeira | 3,5 | \[2,3; 4,7\] | ∞ | 2,8 | \[1,5; 4,1\] | 1,75 |

: Sensibilidade a violações de tendências paralelas (HonestDiD, magnitudes relativas). Sem peso: especificação principal. Com peso: cadeiras do distrito, e não o número de candidaturas usado na @tbl-ddd-robustez-ec111, por isso a estimativa ponderada da taxa de competitivas (3,1) difere da linha ponderada daquela tabela (2,3). "Quebra M̄" é o maior múltiplo da violação de 2014–2018 com que o IC robusto de 95% ainda exclui zero; "—" indica que o IC original já inclui zero. {#tbl-honestdid-ec111}

![Sensibilidade a violações de tendências paralelas (HonestDiD, magnitudes relativas): IC robusto de 95% para o efeito médio de 2022 e 2026, sem peso e com peso pela magnitude do distrito.](../Figures/03-ec111-competitividade/honestdid_sensibilidade.png){#fig-honestdid-ec111 width="100%"}

A aproximação das mulheres ao limiar pelo voto só se sustenta se a violação de tendências depois de 2018 for praticamente nula (M̄ \< 0,25). O aumento de candidaturas não competitivas no cargo federal resiste mais, até violações de 0,75 a 1,5 vez a de 2014–2018 no caso das mulheres e de 1,75 vez ou mais no das pessoas negras. Como há um único período anterior, estimado com imprecisão, os valores de quebra dependem muito desse coeficiente. Um pré-teste próximo de zero por acaso torna a restrição pouco exigente, e um pré-teste grande por acaso a torna muito exigente, de modo que os valores de quebra indicam ordem de grandeza, e não um limiar preciso. A restrição alternativa de suavidade não pôde ser calculada, porque com um só período anterior ela é degenerada e o procedimento recomendado nesse caso não roda na versão de R disponível.

## H5: randomização e sensibilidade (taxa de eleitas)

(@tbl-ddd-ec111; p = 0,032 pela randomização). É o único desfecho de eleição das mulheres com efeito distinguível de zero, aparece numa só eleição e não resiste a nenhuma violação de tendências paralelas (@tbl-honestdid-ec111). Por isso, deve ser lido com cautela, à luz das comparações múltiplas.

## H5: randomização (mulheres negras)

, com intervalo que exclui o zero e p = 0,041 pela randomização,

## Discussão: robustez da aproximação pelo voto

Ela perde significância quando as UFs são ponderadas pelo número de candidaturas e com a normalização de @LuechingerSchelkerSchmid2024_closeness, não tem correspondente pelo gasto e não resiste a violações de tendências paralelas maiores que um quarto da observada antes da emenda.

## Limitações: randomização

A inferência por randomização reforça essa leitura, porque os resultados centrais resistem a ela e alguns efeitos isolados, como o ganho de votos das mulheres em 2022, não.

## Síntese: robustez

O aumento de candidaturas não competitivas resiste a violações de tendências paralelas da ordem da observada antes da emenda. A alocação de recursos se repete nas duas eleições e com ponderação, mas não tem pré-teste,

