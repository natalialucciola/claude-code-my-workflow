# Revisão do Manuscrito: Cap. 3 — Os Efeitos da EC 111/2021 sobre Candidaturas, Recursos, Votos e Sucesso Eleitoral

**Data:** 2026-11-10
**Revisor:** review-paper (modo single-pass)
**Arquivo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd` (378 linhas, versão do commit `dc7ebd4`)

## Escopo e conferência mecânica

- **Figuras:** as 7 existem em `Quarto/thesis/Figures/03-ec111-competitividade/`.
- **Citações:** as 13 chaves resolvem em `Bibliography_base.bib`.
- **Referências cruzadas:** as 18 (`@sec`, `@tbl`, `@fig`) têm alvo.
- **Somas das decomposições:** conferidas à mão (tbl-receita, tbl-decomposicao, diferenças 2026 − 2022 da tbl-funil e tbl-ddd); fecham com diferença máxima de 0,1 (arredondamento).
- **tbl-ddd:** conferida contra `explorations/competitividade-eleitoral/output/ddd_resultados.csv` (09/11 20:43): estimativas, bandas e IC batem nas linhas principais.
- **tbl-honestdid:** conferida contra `honestdid_quebra.csv`. Ver MC5.
- **Cross-artifact (`/review-r`, `/audit-reproducibility`):** não executado nesta rodada; ver "Próximos passos".

## Avaliação geral

**Recomendação:** Revise & Resubmit (revisão menor a moderada para um capítulo de tese).

O capítulo é forte. A pergunta é clara, o funil candidatura → recursos → gasto → votos → competitividade → cadeira organiza o argumento, e as expectativas E1–E6 dizem antes dos resultados o que distinguiria "colheita de votos" de investimento em candidaturas viáveis. A margem de votos por busca, validada em 100% dos eleitos e contra a base de ABD, é uma contribuição metodológica real. A margem de gasto como *desfecho* (e não como classificação) resolve bem o problema de circularidade. O texto também é honesto sobre a fragilidade: a seção de fragilidade desmonta o próprio resultado de competitividade pelo voto, e isso dá credibilidade ao resto.

Os problemas principais são de três tipos: (i) uma caracterização imprecisa da regra de distribuição do FEFC, que sustenta a premissa "votos, não cadeiras"; (ii) duas ameaças de identificação não discutidas, o transbordamento entre o cargo tratado e o de controle e choques nacionais do cargo federal que o agrupamento por UF não captura; (iii) inconsistências internas entre tabelas (pesos, IC, números de transferências a candidaturas negras competitivas) que um leitor atento vai notar.

## Pontos fortes

1. **Desenho do funil com hierarquia de desfechos pré-declarada** (tbl-hierarquia). Isso disciplina as comparações múltiplas e torna explícito onde o efeito se perde.
2. **Medida de competitividade validada:** reprodução de 100% dos eleitos em 216 distritos, 99,98% de concordância com ABD 2014 e justificativa empírica para a banda de 0,1 QE (o exemplo da saturação em 0,25 QE é convincente).
3. **Autocrítica empírica.** A seção "Por que a aproximação ao limiar pelo voto é frágil" testa duas explicações alternativas (cláusula, magnitude), mostra a tendência anterior e faz um placebo 2014–2018. Poucos capítulos derrubam o próprio resultado com tanta clareza.
4. **Decomposições aditivas** (receita do partido × outras fontes; competitivas × não competitivas), com o callout sobre a classificação *ex post* e a direção do viés bem argumentada.
5. **Contribuição clara frente a Fonseca et al. (2026):** a extensão em três direções está bem delimitada.

## Problemas principais

### MC1: A regra do FEFC é descrita de forma imprecisa, e isso afeta a premissa "votos, não cadeiras"
- **Dimensão:** Argumento.
- **Problema:** A linha 28 diz que a distribuição do FEFC "segue, em grande parte, a votação obtida para a Câmara". Pela Lei 9.504/1997, art. 16-D, a divisão é: 2% em partes iguais, 35% pelos votos para a Câmara, 48% pelo número de deputados e 15% pelo número de senadores. Os votos (e, portanto, o dobro da EC 111) só entram nos 35%. No Fundo Partidário, os votos pesam muito mais (95%). As linhas 18 e 32 ("um voto conta o mesmo para o fundo esteja ele numa candidatura que se elege ou não") estão certas sobre o *bônus*, mas o partido também tem um incentivo forte por cadeiras na maior parte do FEFC.
- **Sugestão:** Descrever as duas fórmulas com precisão e reformular a premissa: *o bônus* da EC 111 premia votos, não cadeiras. Isso fortalece o argumento, porque mostra que o desenho acrescentou um prêmio marginal por voto sem mudar o prêmio por cadeira, que continua dominado pelos incumbentes. Vale incluir também que o voto de uma mulher negra conta em dobro *uma única vez* (não quatro vezes): não há incentivo adicional à interseção, o que é relevante para ler os resultados de mulheres negras.
- **Local:** l. 16, 18, 28, 32; Discussão l. 334, 356.
- **Verificar:** conferir as porcentagens no texto vigente da lei antes de citar.

### MC2: Transbordamento entre o tratado e o controle (SUTVA) não é discutido
- **Dimensão:** Identificação.
- **Problema:** Federal e estadual compartilham o mesmo orçamento partidário (o FEFC é repassado ao diretório e dividido entre os dois cargos) e o mesmo grupo de potenciais candidatas. Se o voto em dobro levou o partido a *deslocar* mulheres e dinheiro do estadual para o federal, o controle é contaminado e o DiD superestima o efeito (o tratado sobe e o controle cai). Isso pesa mais nos desfechos de parcela de recursos, que são o principal resultado positivo (+12 p.p. nas transferências).
- **Sugestão:** (a) Discutir a ameaça na seção "O que mais mudou" e nas Limitações. (b) Mostrar os níveis e não só a diferença: a parcela das transferências a mulheres no *estadual* caiu de 2018 para 2022? Se o estadual ficou estável ou subiu (como sugerem as competitivas pelo gasto, 9,4% → 12,4% → 16,4%), o transbordamento é pouco plausível, e isso deve ser dito. (c) Se possível, mostrar a variação do total de recursos destinados ao estadual.
- **Local:** l. 34, 132–138, 340–350.

### MC3: Choques nacionais do cargo federal e inferência com agrupamento por UF
- **Dimensão:** Econometria e identificação.
- **Problema:** A Limitação "Um único tratado" (l. 342) reconhece o problema, mas não tira a consequência para a inferência. O agrupamento por UF trata as 26 comparações federal × estadual como independentes. Um choque nacional específico do cargo federal (a estratégia nacional dos partidos para a cláusula, a federalização documentada na seção de fragilidade) é comum a todas as UFs e não entra no erro-padrão. Os IC medem a variabilidade entre UFs em torno de um contraste nacional, não a incerteza sobre esse contraste (problema do tipo Conley–Taber). Com 26 clusters, o bootstrap multiplicador também tende a subestimar a incerteza.
- **Sugestão:** Uma frase explícita nas Limitações ("os IC não incorporam choques nacionais específicos do cargo federal; por isso a evidência de tendência anterior pesa mais do que a significância") e, como robustez, wild cluster bootstrap (Webb) ou inferência por randomização sobre as UFs nos desfechos principais.
- **Local:** l. 111, 342.

### MC4: Números e denominadores diferentes para as "transferências a candidaturas negras competitivas"
- **Dimensão:** Escrita e consistência.
- **Problema:** A l. 196 diz que a parte que o partido transfere a candidaturas negras competitivas "cai 6,5 pontos em 2022 e 4,8 em 2026" (tbl-receita: parcela da *receita total*). A l. 253 diz que elas "caíram 8,0 pontos em 2022 e 5,0 em 2026" (tbl-decomposicao: parcela das *transferências*). São medidas diferentes, mas o texto chama as duas de "transferências". A l. 196 tem o mesmo problema para as mulheres: "+5,7 e +6,3" são parcela da receita total, enquanto a l. 284 usa "11,5 de 12,4" das transferências.
- A l. 253 também se contradiz: "Nenhuma das diferenças nos desfechos de parcela é distinguível de zero" e, duas frases depois, "A única diferença significativa no funil é uma recuperação parcial…". Essa diferença (−8,0 → −5,0) não aparece em nenhuma tabela, e o texto não diz se ela é significativa.
- **Sugestão:** Fixar a nomenclatura ("parte da receita total vinda do partido" × "parcela das transferências do partido") e usar uma só na l. 196. Na l. 253, ou reportar a diferença com IC ou tirar a frase "única diferença significativa".
- **Local:** l. 180, 196, 253, 284.

### MC5: Inconsistências entre tbl-ddd e tbl-honestdid (pesos e IC)
- **Dimensão:** Econometria e apresentação.
- **Problemas** (conferidos nos CSVs):
  1. **Pesos diferentes.** A tbl-ddd pondera "pelo nº de candidaturas" (média 2,3, n.s.). A tbl-honestdid pondera "pela magnitude do distrito" (3,1, IC [0,2; 6,0]). O peso por magnitude não é descrito em nenhum outro lugar.
  2. **IC diferentes para a mesma estimativa sem peso.** Para pessoas negras, competitivas pelo voto, média 2022–2026: na tbl-ddd, 3,3 [0,08; 6,53] em negrito; na tbl-honestdid, "n.s." (CSV: [−0,38; 6,98]). Para a taxa de eleitas das mulheres em 2026: banda uniforme de [0,07; 5,79] no `ddd_resultados.csv`, mas IC original de [−0,28; 6,15] no `honestdid_quebra.csv`. A banda *uniforme* deveria ser mais larga que um IC pontual. Os dois procedimentos usam matrizes de variância diferentes.
  3. **A l. 247 afirma o que a tabela não mostra.** Ela diz que a taxa de eleitas das mulheres em 2026 "não resiste a nenhuma violação (@tbl-honestdid-ec111)". A tabela traz só a *média* 2022–2026, e no CSV a versão sem peso de 2026 já tem IC original que inclui zero.
  4. **"∞" como valor de quebra** (pessoas negras não competitivas por cadeira, e também mulheres sem peso em 2022 no CSV). Sob magnitudes relativas, isso quase certamente significa "acima do maior M̄ da grade". Reportar como "> M̄ máx. (= X)".
  5. **A l. 326 diz "só se sustenta se M̄ < 0,25",** mas a quebra é 0,25: o IC ainda exclui zero *em* 0,25. Escrever "M̄ ≤ 0,25" ou "até um quarto" (como na l. 338).
- **Sugestão:** Usar a mesma matriz de variância (a do bootstrap do `did`) como insumo do HonestDiD, ou explicar a diferença numa nota. Usar o mesmo esquema de pesos nas duas tabelas, ou descrever o peso por magnitude em Dados e medidas.
- **Local:** l. 204–228, 247, 310–326.

### MC6: A justificativa da restrição de magnitudes relativas como "conservadora" é discutível
- **Dimensão:** Identificação.
- **Problema:** A l. 326 diz que, com um só período anterior estimado com imprecisão, a restrição RM "é conservadora, porque incorpora a incerteza do coeficiente de 2014". Com RM, o limite da violação é M̄ × |δ̂₂₀₁₄|. Quando o pré-teste fica perto de zero por acaso (como no desfecho principal das mulheres, −0,8), os limites ficam *estreitos*, e a análise tende a ser *anticonservadora* justamente quando o pré-teste "passa". Rambachan & Roth recomendam cautela com RM quando há um único período anterior.
- **Sugestão:** Reescrever: "com um único período anterior, a restrição RM ancora a violação permitida num coeficiente estimado com imprecisão; quando esse coeficiente é próximo de zero, ela pode ser pouco exigente". Isso reforça a conclusão do capítulo (o resultado pelo voto é frágil), não a enfraquece.
- **Local:** l. 326, 344.

## Problemas menores

### mc1: Classificação de "partidos pressionados" pela cláusula
- **Problema:** O corte de 4% da votação de 2018 (l. 300) não é justificado; a cláusula era de 2% em 2022. Os números (+4,5 a +5,8 com folga; +0,9 a +1,8 pressionados) não têm IC.
- **Sugestão:** Justificar o corte (margem sobre 2%?), mostrar a sensibilidade a 3% e 5% e trazer IC ou indicar onde estão (`clausula_did.csv`).

### mc2: O placebo na faixa de magnitude comum deveria estar numa tabela
- **Problema:** A l. 306 compara +3,0 a +3,2 (2018→2022) com +3,5 (2014→2018). Esse é o argumento mais forte contra a leitura causal, mas não tem IC nem tabela. Também chama atenção que o pré-teste da amostra completa seja −0,8 e o da faixa comum seja de −3,5. O leitor vai perguntar por que a amostra completa "passa" no pré-teste.
- **Sugestão:** Uma linha a mais na tbl-ddd ("faixa de magnitude comum, 24–70") com pré-teste, 2022, 2026 e IC, e uma frase sobre por que as amostras diferem.

### mc3: Assimetria no tratamento de magnitudes parecidas
- **Problema:** "Gasto ≥ metade do último eleito" dá +3,2 / +3,4, e o texto chama isso de "pequeno e sem significância" (l. 234). O efeito pelo voto, de +3,4 / +3,9, "fecharia 40% da distância" (l. 204). As magnitudes são quase iguais, e o pré-teste 2014 dessa medida também é 3,5.
- **Sugestão:** Distinguir pela significância e pelo pré-teste, não pelo tamanho. Ou dar a base de 2018 dessa medida para que o leitor compare a escala.

### mc4: A conclusão omite as mulheres negras nas cadeiras
- **Problema:** A tbl-funil traz +3,5\* nas cadeiras para mulheres negras em 2026. A conclusão (l. 354) diz que "a presença de mulheres e de pessoas negras … entre os eleitos não mudou". O ponto é tratado na l. 249 (pré-teste falha), mas a conclusão deveria repetir a ressalva.

### mc5: Lacunas na lista de mudanças concorrentes
- **Problema:** A seção "O que mais mudou" (l. 132–138) não cita a EC 117/2022 (constitucionalização da cota de 30% de recursos e de tempo para mulheres) nem a distribuição proporcional de recursos a candidaturas negras desde 2020 (TSE/STF, ADPF 738). As duas valem para os dois cargos e são eliminadas pelo desenho, mas um leitor vai procurá-las ali. Trindade (2025) já é citado sobre a EC 117.
- **Sugestão:** Um item curto: "choques comuns aos dois cargos, eliminados pela comparação".

### mc6: A unidade "lista" com federações
- **Problema:** A l. 110 diz que as siglas foram harmonizadas para as de 2026. Não fica claro se, em 2022 e 2026, a lista é a federação ou o partido dentro dela, nem como isso se compara a 2014 e 2018, quando as listas eram partidos dentro de coligações.
- **Sugestão:** Uma frase em Dados e medidas.

### mc7: Repetição e pequenos ajustes de redação
- l. 16: "incentivo financeiro inédito" e "esse incentivo inovador" no mesmo parágrafo; basta um.
- l. 210: "Idem, ponderado pelo nº de candidaturas" → por extenso: "número".
- l. 215: na linha 2026 de "competitiva pelo voto", a banda [0,0; 7,7] aparece em negrito porque o CSV dá 0,03. Arredondada, ela parece incluir zero. Usar duas casas ou uma nota.
- l. 284: "com pré-teste próximo de zero nas duas partes": os números não aparecem; dar os valores ou citar a figura.

### mc8: Pendências já registradas no comentário final (l. 363–376)
- A CoVe de Gatto, Fonseca et al., Evangelista et al. e Trindade pelo texto integral é especialmente importante para a l. 55 ("concentrado em candidaturas pouco competitivas, definidas pela posição na lista") e para a l. 36 (o papel da relatora).
- Os títulos dos painéis com numeração interna ("3c.", "4a.") nas figuras do funil precisam ser corrigidos antes de compartilhar o capítulo.

## Objeções de banca/parecerista

### RO1: "Seu controle não é controle: os partidos tiraram mulheres e dinheiro do estadual para pôr no federal."
**Por que importa:** Se for verdade, o principal resultado positivo (+12 p.p.) está inflado, talvez pela metade.
**Como responder:** Níveis do estadual ao longo do tempo (MC2). Se a parcela das mulheres no estadual não caiu, a objeção perde força.

### RO2: "Seus intervalos supõem 26 experimentos independentes, mas há um só contraste nacional."
**Por que importa:** A significância dos efeitos marginais (competitividade pelo voto, eleitas em 2026) pode desaparecer.
**Como responder:** Reconhecer explicitamente (MC3), rodar uma inferência alternativa e apoiar a conclusão na magnitude e estabilidade dos efeitos de recursos, como o capítulo já faz.

### RO3: "Se 48% do FEFC segue as cadeiras, por que um partido racional colheria votos em vez de eleger?"
**Por que importa:** Atinge a premissa teórica do capítulo.
**Como responder:** O bônus é marginal e só nos votos; eleger mulheres exigiria deslocar incumbentes, o que tem custo interno (mecanismo do Cap. 5). Lançar candidaturas adicionais sem chance é a resposta de menor custo para capturar o bônus sem perder cadeiras. Com a regra descrita com precisão (MC1), o argumento fica mais forte.

### RO4: "Com um só pré-período e o pré-teste falhando para negros, o que de fato é causal aqui?"
**Por que importa:** A banca vai pedir uma frase clara sobre o que é efeito e o que é descrição.
**Como responder:** Uma tabela-resumo final ou um parágrafo na Conclusão, com três categorias: (a) causal e robusto: transferências e recursos às mulheres, candidaturas não competitivas; (b) causal frágil: competitividade das mulheres pelo voto; (c) não identificado: competitividade e eleição de pessoas negras e de mulheres negras.

### RO5: "A margem de gasto supõe que o dinheiro distribui cadeiras, mas o gasto elege só 50–66% dos eleitos."
**Por que importa:** É a evidência principal de que o dinheiro foi "pulverizado".
**Como responder:** A medida de robustez (≥ metade do último eleito) já está lá. Acrescentar a robustez com D'Hondt puro, já listada como pendente, e mostrar uma medida de concentração direta (por exemplo, Herfindahl ou o gasto da candidata mais bem financiada da lista) como checagem independente do modelo contrafactual.

## Notas por dimensão

| Dimensão | Nota (1–5) |
|---|---|
| Estrutura do argumento | 5 |
| Identificação | 3 |
| Econometria | 3 |
| Literatura | 4 |
| Escrita | 4 |
| Apresentação | 4 |
| **Geral** | **4** |

## Próximos passos sugeridos (por prioridade)

1. **MC1:** corrigir a descrição do FEFC e do Fundo Partidário; é só texto, depois de conferir a lei.
2. **MC4 e MC5:** inconsistências internas; é texto e harmonização de pesos e IC (pode exigir rodar o script do HonestDiD de novo).
3. **MC2:** níveis do estadual; checagem descritiva rápida nos CSVs existentes.
4. **MC3 e MC6:** reescrever as Limitações; a inferência alternativa é opcional.
5. **Cross-artifact:** `/review-r` nos scripts de `explorations/ec111-did-2026/` e `explorations/competitividade-eleitoral/` e `/audit-reproducibility` em todas as tabelas, antes de graduar os scripts para `scripts/R/`.
6. Menores (mc1–mc8) junto com o proofread pendente.
