# Revisão de redação: Cap. 4 (EC 111), Introdução a Metodologia

**Arquivo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd` (linhas 18–167, versão com as edições da autora de 24/11)
**Data:** 2026-11-24 · **Status:** propostas, nada aplicado

## A. Correções técnicas (quebras do modo Visual e restos de marcação)

| # | Linha | Problema | Correção proposta |
|---|---|---|---|
| A1 | 82 | Rótulo `{#tbl-esquema-ec111}` apagado da legenda; `@tbl-esquema-ec111` (l. 75) fica quebrado | Repor ` {#tbl-esquema-ec111}` no fim da legenda |
| A2 | 134 | Rótulo `{#tbl-variaveis-ec111}` apagado; `@tbl-variaveis-ec111` (l. 117) fica quebrado | Repor ` {#tbl-variaveis-ec111}` no fim da legenda |
| A3 | 58 | `@Gatto2025_resistance_quotas \[p. 119\]` (colchetes escapados: o localizador sai como texto) | `@Gatto2025_resistance_quotas [p. 119]` |
| A4 | 84–85, 107–108 | Blocos `::: alterado` vazios (restos dos parágrafos movidos) | Apagar |
| A5 | 117 | "caminhos.As variáveis" (sem espaço) | Ver B12 |
| A6 | 89 | O título "### Modelo e estimação {#sec-modelo-ec111}" saiu; nada o cita | Nenhuma (só registro; confirmar que foi intencional) |

## B. Redação

| # | Linha | Atual | Proposta | Tipo |
|---|---|---|---|---|
| B1 | 29 | "...e esse desvio parece decorrer de uma nova estratégia aqui teorizada como a do investimento em candidaturas "caça-níquel", que enchem o bolso dos donos, mas não levam." | "...e esse desvio parece decorrer de uma estratégia que chamo de investimento em candidaturas caça-níqueis, que enchem o caixa do partido, mas não chegam à cadeira." | frase incompleta ("não levam" o quê); grafia "caça-níqueis" como no resto do capítulo |
| B2 | 29 | "no plano federal" | "no cargo federal" | consistência |
| B3 | 29 | "Esse dinheiro, porém, não era novo. Somando o total investido..." | "Esse dinheiro, porém, não era novo. Saiu das candidatas estaduais, e, somando o total investido..." | a frase "não era novo" fica sem a evidência (o deslocamento entre cargos) |
| B4 | 29 | "mais pessoas negra, mas" | "mais pessoas negras, mas" | erro de digitação |
| B5 | 29 | "não eram percebidas como viáveis pelos partidos" | "que, pelo histórico eleitoral, não eram viáveis antes da eleição" | a medida é o histórico (mandato ou proximidade do limiar), não a percepção do partido |
| B6 | 31 | "com o aumento de candidaturas masculinas com poucas chances, em especial em listas pequenas" | "com o aumento de candidaturas masculinas com poucas chances, e se concentra nas listas pequenas" | ambiguidade: é a aproximação que se concentra nas listas pequenas |
| B7 | 35 | "candidatas deste grupo" / "corridas eleitorais estauduais" | "candidatas desse grupo" / "não parece ter saído das candidatas estaduais" | erro de digitação; precisão (a evidência é a proporção estável no estadual) |
| B8 | 35 | "Em termos de votos, elas também tiveram um crescimento e a proporção delas..." | "Os votos delas também cresceram, e a proporção delas..." | concisão; vírgula entre orações de sujeitos diferentes |
| B9 | 38 | "...entre os cargos de deputado federal e estadual e define as variáveis" | "...entre os cargos de deputado federal e estadual, e define as variáveis" | pontuação |
| B10 | 69 | "Como a decisão do partido é tomada antes do resultado, no caso de uma possível preferência por candidatas do tipo caça-níquel prevê ainda que o acréscimo de recursos para mulheres ou negros vá para candidatas que [...] e não para as percebidas pelo patido como viáveis." | "Como a decisão do partido é tomada antes do resultado, a leitura caça-níqueis prevê ainda que o acréscimo de recursos para mulheres e pessoas negras vá para candidatas que, antes da eleição, não tinham mandato nem haviam ficado perto de uma cadeira, e não para as viáveis." | frase sem sujeito para "prevê"; "patido"; "negros" → "pessoas negras" (termo do capítulo) |
| B11 | 75, 87 | "comparando a relação entre deputados federais [...] e deputados estaduais"; "candidaturas federais ou estaduais" | "comparando candidaturas a deputado federal [...] e a deputado estadual"; "candidaturas federais e estaduais" | o objeto são candidaturas, não deputados; "ou" → "e" |
| B12 | 117 | "...identificar esses caminhos.As variáveis seguem as etapas da candidatura, do lançamento à eleição (@tbl-variaveis-ec111)." | Mover para o início de "Variáveis" (antes da l. 113), repondo a frase apagada: "As variáveis seguem as etapas da candidatura, do lançamento à eleição (@tbl-variaveis-ec111). Cada uma é medida para três grupos, mulheres, pessoas negras (pretas e pardas) e mulheres negras." | ordem; definição dos grupos sumiu |
| B13 | 89 | "Para cada variável $Y$ medida na lista de candidaturas de cada partido $u$ no ano $t$" | "Para cada variável $Y$ medida na lista $u$, isto é, nas candidaturas de um partido a um cargo numa UF, no ano $t$" | $u$ é a lista (partido × UF × cargo), não o partido |
| B14 | 137 | "na lista $\ell$, $Y_{\ell t} = \text{taxa}^{\,\text{grupo}}_{\ell t} - \text{taxa}^{\,\text{comparação}}_{\ell t}$" | "na lista $u$, $Y_{ut} = \text{taxa}^{\,\text{grupo}}_{ut} - \text{taxa}^{\,\text{comparação}}_{ut}$" | notação: o modelo usa $u$ para a lista |
| B15 | 103 | "justamente nas variáveis em que o pré-teste falha" | "justamente nas variáveis em que o pré-teste falhasse" | medidas na lista, os pré-testes não falham nas variáveis principais |
| B16 | 155 | (início) "Como a margem de votos depende do resultado..." | Acrescentar ao fim da l. 152 ou ao início da l. 155: "Por isso, a viabilidade antes da eleição é medida pelo histórico eleitoral, e não pelo gasto." | ligação com o argumento da circularidade (l. 152) |

Todas as linhas alteradas ficariam marcadas com `{.alterado}` (azul).
