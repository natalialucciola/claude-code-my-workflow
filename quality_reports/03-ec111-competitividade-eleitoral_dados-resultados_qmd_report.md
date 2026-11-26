# Proofread — Cap. 4 (03-ec111): Dados e Resultados

**Data:** 2026-11-25 · **Arquivo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd`
(seções Dados, linhas 175–199, e Resultados, linhas 201–361) e legendas em `_tabelas-cap3/`.
**Escopo:** gramática, digitação, consistência (terminologia, números, remissões), qualidade acadêmica.
**Nenhum arquivo-fonte foi editado.** Números citados conferidos contra as tabelas geradas
(`reg_*.md`, `descritivo_competitividade.md`, `amostra.md`, `transferencias_cargo.md`,
`composicao_lista.md`, `sucesso.md`, `decomposicao.md`, `viabilidade.md`, `matriz_viabilidade.md`):
todos conferem, salvo o indicado em C1 e C2.

## Resumo

| Categoria | Achados |
|---|---|
| Consistência de conteúdo (texto × tabela) | 2 |
| Consistência de terminologia | 3 |
| Gramática | 3 |
| Qualidade acadêmica / redação | 9 |
| **Total** | **17** |

Mais importantes: **C1** (afirmação de que a proporção de pessoas negras cresce em todo o período,
contradita pela Tabela de amostra) e **C2** (H4 omite o termo único significativo de mulheres negras
entre as competitivas pelo voto).

## Consistência de conteúdo

**C1 · L189 · importante**
- Atual: "A proporção de mulheres e de pessoas negras entre as candidaturas cresce nos dois cargos ao longo do período"
- Problema: a proporção de pessoas negras cai de 2022 para 2026 nos dois cargos (47,8% → 46,1% no federal; 51,8% → 49,4% no estadual, @tbl-amostra-ec111).
- Proposta: "A proporção de mulheres cresce nos dois cargos ao longo de todo o período, e a de pessoas negras, até 2022, o que mostra que parte do aumento observado no federal ocorreu também onde não havia voto em dobro."

**C2 · L266 e L276 · importante**
- Atual (L266): "A proporção desses grupos entre as candidaturas competitivas das listas não muda pelo voto"; (L276): "a proporção de mulheres negras entre as competitivas sobe 1,5 e 1,8 ponto, sem significância em cada eleição."
- Problema: na @tbl-composicao-lista-ec111, o termo único Federal × Pós de mulheres negras entre as competitivas pelo voto é +2,2 e se distingue de zero. O texto da L354 cita o termo único significativo para eleitas (2,5), mas não este.
- Proposta (L276): "...sobe 1,5 e 1,8 ponto, sem significância em cada eleição, embora o termo único, de 2,2 pontos, se distinga de zero." E na L266: "não muda pelo voto, salvo no termo único das mulheres negras, e, pelo gasto, ..."

## Consistência de terminologia

**T1 · L223 (legenda da @fig-efeitos-etapas-ec111)**
- Atual: "nas taxas, grupo menos complemento na mesma lista"
- Problema: Dados e Resultados usam "restante" (e a Metodologia, "grupo de comparação"); "complemento" só aparece aqui.
- Proposta: "nas taxas, grupo menos o restante das candidaturas da lista".

**T2 · L300**
- Atual: "É o padrão dos candidatos caça-níqueis, agora medido em reais."
- Problema: o capítulo define a categoria como *candidaturas caça-níqueis* (Revisão da Literatura, L54) e usa "candidatas caça-níqueis" na L320.
- Proposta: "É o padrão das candidaturas caça-níqueis, agora medido em reais."

**T3 · L227 × L231**
- Atual: H1 usa "cerca de 3 pontos"; a unidade "pontos percentuais" só é dita na L231.
- Proposta (L227): "sobe cerca de 3 pontos percentuais em relação às estaduais".

## Gramática

**G1 · L247 · tempo verbal**
- Atual: "em 2018, pouco chegava às mulheres, que receberam 15,8% dos repasses"
- Proposta: "em 2018, pouco chegava às mulheres, que recebiam 15,8% dos repasses"

**G2 · L184 · concordância/elipse**
- Atual: "o painel reúne as 799 listas presentes nas quatro eleições, das quais 413 federais e 386 estaduais"
- Proposta: "o painel reúne as 799 listas presentes nas quatro eleições, das quais 413 são federais e 386, estaduais"

**G3 · L211 (legenda da @fig-niveis-taxas-ec111) · pontuação**
- Atual: "competitivas pelo voto, competitivas pelo gasto e eleitas menos a taxa do restante"
- Proposta: "competitivas pelo voto, competitivas pelo gasto e eleitas, menos a taxa do restante"

## Qualidade acadêmica / redação

**R1 · L181 (nota) · repetição de "como"**
- Atual: "Como, nos arquivos de prestação de contas, cada despesa e cada receita é um item de um documento, como uma nota fiscal, um contrato ou um recibo, que pode reunir vários itens, ..."
- Proposta: "Como, nos arquivos de prestação de contas, cada despesa e cada receita é um item de um documento (nota fiscal, contrato ou recibo) que pode reunir vários itens, ..."

**R2 · L196 · construção pesada**
- Atual: "Como as candidaturas viáveis são poucas em qualquer grupo, com 71 mulheres no cargo federal em 2018 e 129 em 2022, a divisão ... deve ser lida tendo em conta esse tamanho."
- Proposta: "Como as candidaturas viáveis são poucas em qualquer grupo (no cargo federal, eram 71 mulheres em 2018 e 129 em 2022), a divisão das transferências entre viáveis e não viáveis (@sec-h4-ganhos-ec111) deve ser lida levando em conta esse tamanho."

**R3 · L214 · oração final desconexa**
- Atual: "...o p-valor do *wild cluster bootstrap*, e a @fig-efeitos-etapas-ec111 resume os efeitos de 2022 e de 2026."
- Proposta: encerrar a frase no bootstrap e abrir outra: "...o p-valor do *wild cluster bootstrap*. A @fig-efeitos-etapas-ec111 resume os efeitos de 2022 e de 2026."

**R4 · L223 (legenda da @fig-efeitos-etapas-ec111) · estilo**
- Atual: "Barra grossa: IC de 95%; barra fina: banda uniforme de 95% para os anos."
- Problema: único trecho dos Resultados ainda com dois-pontos e ponto e vírgula; as demais legendas foram reescritas.
- Proposta: "A barra grossa indica o IC de 95% e a barra fina, a banda uniforme de 95% para os anos, com erros agrupados por UF."

**R5 · L233 e L305 · artigo antes da remissão**
- Atual: "@tbl-transferencias-cargo-ec111 e @fig-transferencias-cargo-ec111 mostram..."; "@tbl-decomposicao-ec111 mostra a divisão."
- Proposta: "A @tbl-... e a @fig-... mostram..."; "A @tbl-decomposicao-ec111 mostra a divisão." (como nos trechos revisados).

**R6 · L247–249 · ordem dos parágrafos**
- Problema: o parágrafo dos recursos públicos fica entre o investimento relativo e o parágrafo que começa "As mulheres negras são a exceção", que se refere à realocação das transferências (L233). Com o parágrafo intermediário, o referente de "exceção" fica distante.
- Proposta: mover o parágrafo dos recursos públicos para depois do das mulheres negras, ou abrir este com "Na realocação das transferências, as mulheres negras são a exceção."

**R7 · L253 · parágrafo longo**
- Problema: o parágrafo do teste de falsificação reúne mulheres, mulheres negras e pessoas negras em cerca de 260 palavras.
- Proposta: abrir um novo parágrafo em "Para pessoas negras, o teste fica no limite em 2022."

**R8 · L333 · duas medidas próximas**
- Atual: "a taxa de competitivos entre eles caiu (no federal, de 15,9% em 2018 para 10,5% em 2022)"
- Problema: três linhas antes (L330) a mesma taxa aparece como média das listas (25,5% → 14,5%); os números da L333 são totais nacionais, o que não está dito.
- Proposta: "...caiu (no federal, em totais nacionais, de 15,9% em 2018 para 10,5% em 2022)".

**R9 · L337 · ponto e vírgula em série; L346 · frases curtas**
- Atual (L337): "...de 2018 para 2022; controlando pelo log da magnitude, 4,5; restringindo à faixa..., 3,6 a 3,7, todos significativos."
- Proposta: "...de 2018 para 2022, diferença que cai para 4,5 quando se controla pelo log da magnitude e para 3,6 a 3,7 na faixa de magnitude comum aos dois cargos (24 a 70 cadeiras), todas significativas."
- Atual (L346): "H5 não é confirmada para as mulheres e para pessoas negras. Para mulheres negras, há um indício."
- Proposta: "H5 não é confirmada para as mulheres e para pessoas negras, e há apenas um indício para as mulheres negras."

## Legendas das tabelas (`_tabelas-cap3/`)

Sem erros de gramática ou de digitação. Uma sugestão de redação:

**L1 · `reg_*.md` (R/11) · enumeração longa**
- Atual: "as colunas (7) a (9) são a taxa de candidaturas do grupo que terminam competitivas, isto é, eleitas ou a menos de 0,1 QE do limiar pela margem de votos ou de gasto, ou que se elegem, menos a taxa do restante..."
- Proposta: "as colunas (7) a (9) são a taxa de candidaturas do grupo que terminam competitivas (eleitas ou a menos de 0,1 QE do limiar, pela margem de votos ou de gasto) ou eleitas, menos a taxa do restante..." (mudança no R/11, que regenera as três tabelas).

## Conferido sem achados
Números de H1, H2 (transferências, investimento relativo, recursos públicos, gasto, falsificação), H3,
H4 (sucesso relativo, decomposição, viabilidade, matriz), H5 e H6; p-valores do wild bootstrap citados
(0,02; 0,03; 0,04; 0,003; 0,05; 0,06; 0,09; 0,12); remissões cruzadas (render sem referências
quebradas); uso de "ponto" no singular abaixo de 2.
