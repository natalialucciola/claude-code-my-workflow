# Plano: revisão do Cap. 4 (EC 111) para envio ao orientador

**Status:** CONCLUÍDO em 17/11 (A1–A12, B, C e reorganização de H4); falta CoVe da cota de 30% e o commit
**Data:** 2026-11-17
**Arquivo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd` (no livro, Capítulo 4; versão do commit `e3bd793`)
**Pedido da autora (17/11):** (1) reduzir vícios de linguagem de IAG, dois-pontos, travessão, negrito e ponto e vírgula; (2) visibilidade das figuras, tabelas e equações, com subdivisão das muito extensas; (3) revisão substantiva da consistência entre argumentos e conclusões.

---

## Parte A. Consistência substantiva

Ordenada por gravidade. "A-crít." = afirmação que o orientador pode contestar com a própria tabela do capítulo.

### A1 (crít.). A Conclusão atribui à tendência anterior um ganho cujo pré-teste é nulo
- l. 365: "O aumento da parcela de mulheres negras entre os eleitos em 2026 segue a mesma tendência anterior e não pode ser atribuído ao voto em dobro."
- Na @tbl-funil-ec111, a parcela de cadeiras de mulheres negras tem pré-teste **+0,1** e efeito de 2026 **+3,5\***. O pré-teste que falha é o da *taxa de eleitas* (mulheres negras − homens brancos, −5,1 na @tbl-ddd-ec111), que é outro desfecho.
- Também em H5 (l. 329), "o pré-teste falha nesses desfechos" junta os dois.
- **Correção:** separar os dois desfechos. Para a parcela de cadeiras, dizer que o efeito de 2026 aparece só numa eleição, com 52 disputas e muitos testes, e que não há pré-tendência. Ajustar a frase da Conclusão e a da síntese (l. 361).

### A2 (crít.). H4 diz que o pré-teste "falha" para mulheres negras, mas ele não é significativo na competitividade
- l. 223 e l. 329. Na @tbl-ddd-ec111, a competitividade pelo voto de mulheres negras tem pré-teste −4,2 (sem negrito, IC inclui zero), e o efeito de 2026 é +9,1 com média +6,5, os dois significativos. Só a *taxa de eleitas* tem pré-teste significativo (−5,1).
- A conclusão de "não identificado" pode continuar de pé, mas pelo motivo certo: um pré-teste impreciso, de magnitude parecida com a do efeito. O HonestDiD de mulheres negras está pendente (comentário final do capítulo), e é ele que resolveria a questão.
- **Correção:** reescrever com a distinção "falha" × "impreciso e da mesma ordem". Decisão da autora: rodar já o HonestDiD de mulheres negras ou deixar como limitação declarada (ver as perguntas no fim).

### A3 (crít.). A síntese chama de "robusto" o resultado que a Metodologia diz não ter checagem
- l. 78: nos recursos, "que incluem o resultado mais forte do capítulo, a hipótese de tendências paralelas é suposta sem checagem direta".
- l. 361: "São efeitos causais robustos do voto em dobro a alocação de recursos do partido às mulheres…"
- **Correção:** chamar de "o resultado mais estável" (estável entre eleições, ponderações e fontes) e repetir na síntese que ele depende de tendências paralelas não testáveis e da ausência de transbordamento.

### A4 (crít.). A promessa sobre o transbordamento não é cumprida
- l. 84: "Os níveis de cada cargo, apresentados junto com os resultados, permitem avaliar essa possibilidade."
- Os resultados mostram níveis por cargo só para os votos (l. 219) e para as competitivas pelo gasto (l. 255). Para as *transferências do partido*, o desfecho mais exposto ao transbordamento, não há nível do estadual.
- **Correção:** acrescentar uma frase com a parcela das transferências a mulheres no estadual em 2018, 2022 e 2026, tirada do CSV de níveis do `ec111-did-2026`. Se o dado não estiver pronto, trocar a promessa da l. 84 pelo que de fato é mostrado.

### A5 (maior). Lógica invertida na Discussão sobre a cláusula de desempenho
- l. 297: a aproximação das mulheres aparece nos partidos **com folga** e não nos pressionados. Isso é evidência *contra* a explicação da cláusula.
- l. 347 usa o mesmo fato ("não aparece nos partidos pressionados") como razão para *não* ler a aproximação como efeito da emenda. O incentivo da EC 111 vale igual para todos os partidos, então a heterogeneidade não depõe contra ele.
- **Correção:** tirar esse item da lista da l. 347, ou reformular como "não é explicada pela cláusula".

### A6 (maior). O placebo decisivo contra a aproximação pelo voto não aparece em nenhuma tabela e contrasta com o pré-teste principal
- l. 303: na faixa de magnitude comum, a diferença aumenta 3,0 a 3,2 de 2018 para 2022, contra 3,5 de 2014 para 2018.
- O pré-teste da especificação principal é −0,8 (@tbl-ddd-ec111), e sem as UFs de 8 cadeiras é +0,9. O leitor vê uma especificação sem pré-tendência e um argumento, sem tabela, de que há pré-tendência numa subamostra.
- Esse é o pendente mc2 da revisão de 10/11. A Discussão (l. 347) e a Conclusão (l. 365) apoiam-se nele.
- **Conferido em 17/11** (`competitividade-eleitoral/output/magnitude_regressoes.csv`, script `R/09_magnitude_coligacoes.R`, regressão por distrito com EP agrupado por UF):
  - Faixa comum: 31 distritos, **só 7 federais** contra 24 estaduais. A subamostra desfaz o pareamento federal × estadual da mesma UF.
  - Placebo 2014→2018 na faixa comum: **3,48 (EP 2,18)**, sem significância, com IC de cerca de −0,8 a 7,8. Efeito 2018→2022: 3,15 (EP 1,25).
  - Amostra inteira: placebo 0,78 (EP 1,40) e efeito 3,39 (EP 1,34). **Controlando log(M):** placebo 1,07 (1,75) e efeito **4,64 (1,53)**. Controlar a magnitude *aumenta* o efeito.
- **Correção:** rebaixar o argumento. A faixa comum fica como evidência sugestiva e imprecisa, não como prova de que "o efeito tem o mesmo tamanho da tendência anterior". Reportar a linha na tabela de robustez com EP e n de federais, e dizer que, na amostra inteira com controle de magnitude, não há pré-tendência. A leitura de "frágil" continua apoiada na ponderação, na normalização de LSS, na composição das competitivas, na queda da taxa dos homens e no HonestDiD (M̄ < 0,25). Tirar esse item da lista da Discussão (l. 347) e da Conclusão (l. 365).

### A7 (maior). Equivalência com a regressão de efeitos fixos duplos enunciada de forma incorreta
- l. 76: o ATT(t) seria "igual … ao da regressão com efeitos fixos de unidade e de ano no painel completo, porque todas as unidades tratadas recebem o tratamento ao mesmo tempo."
- Com um só termo Federal × Pós no painel 2014–2026, a regressão estima uma média que usa 2014 e 2018 como base e junta 2022 e 2026. Ela não reproduz o ATT(2022) nem o ATT(2026) com base em 2018. A equivalência vale para a versão de estudo de evento, com uma interação por ano e 2018 omitido.
- A frase seguinte, sobre adoção escalonada, não se aplica ao caso, porque a adoção é única, e soa contraditória.
- **Correção:** "…e ao da regressão de estudo de evento com efeitos fixos de unidade e de ano, com uma interação Federal × ano e 2018 como referência". A justificativa para usar Callaway–Sant'Anna passa a ser prática: bandas uniformes e a função de influência para a persistência. É relevante porque a autora quer a regressão linear tradicional numa etapa futura.

### A8 (maior). H6 é declarada "confirmada" sem distinguir desfechos, e a ausência de diferença é lida como igualdade
- l. 333: "H6 é confirmada". Mas o efeito sobre os votos das mulheres perde significância em 2026 (H3), e o gasto cai de 7,1 para 5,0. A diferença não significativa não demonstra que os efeitos são iguais: os IC das diferenças têm cerca de ±2,5 pontos.
- **Correção:** "H6 é confirmada para candidaturas e recursos; nos votos, o efeito de 2026 é menor e impreciso", e dizer qual diferença os dados conseguiriam detectar (meia largura do IC da diferença).

### A9 (maior). A "recuperação parcial distinguível de zero" não é reportada
- l. 333: a queda das transferências a candidaturas negras competitivas, de −8,0 para −5,0, seria "uma recuperação parcial distinguível de zero". Nenhuma tabela mostra essa diferença nem o seu IC. É o MC4 de 10/11, só em parte resolvido.
- **Correção:** reportar o IC da diferença, que existe no CSV de persistência, ou tirar "distinguível de zero".

### A10 (maior). O número de contribuições muda de uma seção para a outra
- A Introdução (l. 24) fala em "duas principais contribuições": 2026 e a medida de competitividade. A Revisão (l. 40) fala em "três direções": medida, todos os estágios com o mesmo estimador e 2026.
- **Correção:** unificar em três, também na Introdução, já que o funil completo é o eixo do capítulo.

### A11 (menor). Afirmações que vão um pouco além do que os dados mostram
- l. 345: as mudanças comuns aos dois cargos ocorreram "como efeito das cotas de recursos". O desenho elimina choques comuns, mas não os identifica. Trocar por "compatível com as cotas de recursos e com outras mudanças comuns".
- l. 197: "O efeito é maior quanto mais a fonte é controlada pelo partido". O gasto (+7,1) é maior que a receita total (+6,1), mas o gasto não é uma fonte. Restringir a frase às três fontes.
- l. 215: "praticamente todo o aumento" ficou com as não competitivas. Na verdade, a parte não competitiva (+5,7) é *maior* que o total vindo do partido (+4,5), porque a parte competitiva é negativa. Dizer "todo o aumento, e um pouco mais".
- l. 327: estimativas "pequenas" nas cadeiras de pessoas negras (−5,0 e +1,9, diferença de +6,9). Trocar por "imprecisas e de sinal instável".
- l. 157: a queda de "cerca de 25%" em 2026 é de 24% no federal e de 30% no estadual. Dar os dois números.
- l. 90 e @tbl-hierarquia-ec111: "um desfecho principal por estágio", mas Recursos tem dois. Dizer "um ou dois".

### A12. Pendências de 10/11 que tocam a consistência e continuam abertas
- MC5: pesos diferentes entre @tbl-ddd-ec111 (número de candidaturas) e @tbl-honestdid-ec111 (magnitude do distrito). O leitor vê 2,3 numa tabela e 3,1 na outra para "o mesmo efeito ponderado".
- MC6: a frase "a restrição de magnitudes relativas é conservadora" (l. 323).
- MC3: inferência com 26 clusters (já citada nas Limitações, sem robustez).
- **Proposta:** em MC5, só o texto: dizer nas duas legendas qual peso cada tabela usa e por quê. Em MC6, reescrever a frase sem "conservadora". MC3 continua fora desta etapa.

---

## Parte B. Estilo

Medido só na prosa: cerca de 8.900 palavras, sem tabelas, legendas, equações nem comentários.

| Marca | Ocorrências | Por 1.000 palavras | Leitura |
|---|---:|---:|---|
| Negrito | 58 | 6,5 | Alto. A regra registrada em 16/08 aceita negrito só como rótulo de item de lista |
| Dois-pontos | ~60 | 6,7 | Alto. Muitos introduzem a "revelação" de uma frase curta |
| Ponto e vírgula | 47 | 5,3 | Alto. Usado para encadear três ou quatro orações paralelas |
| Travessão | 0 | 0 | Já resolvido na prosa (só aparece nas tabelas, como célula vazia) |
| Parênteses | 96 | 10,7 | Alto. Muitos números entre parênteses no meio da frase |

Padrões de IAG que encontrei, com exemplos:

1. **Antítese "X, não Y"** como fecho de parágrafo: "premia votos, não cadeiras"; "volume de dinheiro, não candidatas em posição de disputa"; "nas candidaturas e no dinheiro, não nas cadeiras"; "A emenda não mudou…; mudou quanto o partido lhes repassa". Manter a primeira ocorrência, que é a tese do capítulo, e desfazer as demais.
2. **Frase curta de efeito depois de dois-pontos ou ponto:** "Não aparecem." "É a versão monetária da colheita de votos." "A resposta, adiantada aqui, é que…". "É o que mostram…". Uma por seção, no máximo.
3. **Rótulos em negrito no início do parágrafo** (l. 295–305, 349–359), que imitam subseções. Nas Limitações, a regra de 16/08 aceita rótulos de lista. Em H4, viram frases de abertura normais.
4. **Hipóteses respondidas em negrito** (l. 193, 197, 219, 223, 327, 333): a frase inteira em negrito. Substituir por uma frase de abertura sem negrito. O rótulo "H1 · Candidaturas" já está no título da subseção.
5. **Negrito para termos definidos** (tendências paralelas, pré-teste, margem de votos…). A convenção acadêmica é itálico na primeira ocorrência, ou nada.
6. **Conectores em série:** "Além disso" (3), "No entanto" (3, sendo 2 na Introdução), "porém" (3, um deles logo depois de "Mas" na l. 28: "Mas o dinheiro… O dinheiro adicional, porém…").
7. **Repetição Introdução ↔ Discussão ↔ Conclusão:** o parágrafo de resultados da Introdução (l. 28), o primeiro da Discussão (l. 341) e o primeiro da Conclusão (l. 365) contam a mesma sequência, com as mesmas frases. Proposta: a Introdução fica com 4 ou 5 frases de resultado; a Discussão interpreta sem recontar; a Conclusão fica com a implicação.
8. **Listas com marcadores** onde caberia prosa: mudanças concorrentes (l. 86–88) e composição × cadeiras (l. 261–262). As hipóteses H1–H6 ficam em lista, por convenção.

**Regra de trabalho:** dois-pontos só antes de enumeração ou citação; ponto e vírgula só em série que tem vírgula interna; negrito só nos rótulos de lista das Limitações e nas tabelas (que passam a usar \* no lugar de negrito; ver C). Meta: cada marca abaixo de 2 por 1.000 palavras, exceto parênteses (abaixo de 6).

**Proteção:** toda frase reescrita que contenha número ou citação é comparada com a versão anterior por script (diff de números), e as frases com citação passam por `/verify-claims`. É a regra registrada em 16/08, depois que uma reescrita de estilo introduziu um erro factual.

---

## Parte C. Figuras, tabelas e equações

### Tabelas
| Tabela | Problema | Proposta |
|---|---|---|
| `tbl-funil` (21 linhas) | A coluna "Pré-teste" fica vazia em 12 das 21 linhas; mistura parcelas da lista com cadeiras | **Dividir em duas:** (a) candidaturas, votos e cadeiras, com pré-teste; (b) receita, transferências, recursos públicos e gasto, sem a coluna de pré-teste |
| `tbl-ddd` (19 linhas, IC entre colchetes) | Muito densa; mistura especificação principal, robustez e três grupos; usa negrito para significância, enquanto as outras tabelas usam \* | **Dividir em duas:** (a) principal, os três grupos × competitiva pelo voto, pelo gasto e eleita, com IC; (b) robustez de mulheres − homens (ponderação, sem 8 cadeiras, sem incumbentes, ABD, LSS, medidas de gasto, **+ faixa de magnitude comum**, ver A6). Trocar o negrito por \* |
| `tbl-amostra` (11 colunas) | Larga demais; coluna com "a / b / c" | **Dividir em duas:** (a) candidaturas e composição; (b) cobertura financeira por grupo. Muda o script `05_tabela_amostra.R` |
| `tbl-honestdid` | Valores "com peso / sem peso" na mesma célula | Duas colunas separadas por especificação |
| `tbl-hierarquia` + `tbl-variaveis` | Sobrepostas | **Fundir:** acrescentar a coluna "papel (principal / mecanismo / robustez)" a `tbl-variaveis` e remover `tbl-hierarquia` |
| `tbl-receita` | Cabeçalho longo, com 6 colunas "Grupo ano" | Cabeçalho em dois níveis não funciona bem em Markdown. Transpor (grupos × anos em linhas) ou abreviar ("M 2022") com nota |

### Figuras
| Figura | Problema | Proposta |
|---|---|---|
| `fig-faixas-margem` | 16 painéis, rótulos inclinados e pequenos | **Dividir em duas** (gênero e raça) ou reduzir a 3 faixas (eleita, a menos de 0,1, a mais de 0,1) |
| `fig-ddd` | 15 painéis. Mostra as faixas de 0,25 e 0,5 QE que o texto descartou. Tudo em laranja, inclusive os grupos raciais, o que quebra a convenção de cores do capítulo | Manter só "a menos de 0,1 QE" e "eleita" (6 painéis), com a cor de cada grupo. As outras faixas vão para o apêndice ou saem |
| `fig-magnitude` | **A legenda não bate com a figura:** fala em "listas por cadeira", mas os painéis são candidaturas, homens não competitivos e mulheres não competitivas | Corrigir a legenda, no texto, sem refazer a figura |
| `fig-honestdid` | Decimal com ponto (0.5) e o símbolo M̄ mal renderizado. Mostra só a versão com peso, enquanto a tabela tem as duas. A nota diz "2014–2018 é outro regime de financiamento", o que não se aplica a votos | Refazer: vírgula decimal, M̄ correto, nota corrigida |
| `fig-receita` | Títulos de painel com numeração interna ("3c.", "3."); "Recursos do partido" no painel × "Transferências do partido" no texto | Refazer os títulos (pendência já registrada) |
| `fig-decomposicao` | "Recursos do partido" × "Transferências do partido" | Uniformizar o nome |
| Todas as de estudo de evento | **A convenção das barras se inverte:** em `fig-receita` e `fig-decomposicao`, a barra fina é a banda uniforme; em `fig-ddd`, o traço fino é o IC pontual | Uma convenção única nas cinco figuras |
| `fig-funil-sintese` | O texto (l. 161) diz que ela resume "e sobre as cadeiras", mas as cadeiras não aparecem | Ajustar o texto ou incluir as cadeiras |

### Equações
- `eq-att`: a linha é longa por causa de `\qquad t \in {…}`. Mover a condição para o texto, para não estourar a largura em telas estreitas e no PDF futuro.
- `eq-reg`: $s \in \{2018, t\}$ com $t = 2014$ deixa "Pós" sem sentido no pré-teste. Uma frase resolve, ou passar para a forma de estudo de evento (ver A7).
- A tripla diferença é definida só em prosa (l. 82). Proposta: uma equação numerada curta para $Y_{u,c,t}$.

---

## Ordem de execução (depois da aprovação)
1. **Scripts das figuras e tabelas** (C): `05_tabela_amostra.R`, as figuras de estudo de evento (`03_did_event_study.R`), `ddd` e HonestDiD em `competitividade-eleitoral`. Só mudanças de apresentação, sem reestimar nada. Depois, conferir se os números das tabelas regeneradas batem com as atuais.
2. **Correções substantivas A1–A11** no `.qmd`, puxando os números novos (A4, A6, A9) dos CSVs já existentes. Se algum não existir, paro e aviso.
3. **Passada de estilo (B)**, seção por seção, com o diff de números a cada seção.
4. **Verificação:** `quarto render`, sem referências quebradas; `quality_score.py` ≥ 90; recontagem das marcas de estilo; `/verify-claims` nos parágrafos com citação que forem reescritos; leitura das figuras regeneradas.
5. Commit e atualização da página "Estado dos Capítulos" só com o seu pedido explícito.

## Fora desta etapa
HonestDiD formal do funil, inferência alternativa (MC3), regressão linear tradicional e EF de UF × ano, regra de cópias exatas nos Caps. 2 e 5.
