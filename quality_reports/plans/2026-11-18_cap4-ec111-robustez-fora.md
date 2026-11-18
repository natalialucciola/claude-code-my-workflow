# Plano: retirar os testes de robustez do Cap. 4 (EC 111) antes do envio ao orientador

**Status:** EXECUTADO em 18/11 (robustez, sensibilidade e randomização fora do corpo; texto em chapters/_apendice-cap3/robustez.md). Sem commit.
**Data:** 2026-11-18
**Pedido da autora (18/11):** "Não estou segura dos testes de robustez feitos nesta seção e acho que prefiro enviar para o meu orientador sem isso."

## Inventário (o que é robustez e onde está)

| # | Teste | Onde | Peso no argumento |
|---|---|---|---|
| R1 | Ponderação pelos votos da lista em 2018 (candidaturas: +1,6; +0,4) | H1 | "concentrada em listas pequenas" depende dele |
| R2 | Ponderação nas transferências (+16,8 e +14,5) | H2 | ilustrativo |
| R3 | Aproximação da sensibilidade a tendências (≈0,6 vez a pré-tendência) | H3 | secundário |
| R4 | Tabela de robustez da tripla diferença: ponderação, sem UFs de 8 cadeiras, sem incumbentes, log da magnitude, magnitudes comuns, ABD, LSS, eleita pelo gasto, gasto ≥ metade | H4, 4.5.4.1 (`tbl-ddd-robustez`) | apoia a "fragilidade" pelo voto |
| R5 | Placebo nas magnitudes comuns (3,5 de 2014 a 2018) | H4, 4.5.4.3 | argumento já rebaixado em 17/11 |
| R6 | Sensibilidade formal (HonestDiD): `tbl-honestdid`, `fig-honestdid`, valores de quebra | 4.5.4.4 inteira | apoia a "fragilidade" e a robustez das não competitivas |
| R7 | Menções na Metodologia (ponderações, painel desbalanceado, normalizações ABD e LSS, bandas de 0,25 e 0,5 QE descartadas) | 4.3 | descritivo |
| R8 | Menções na Discussão (perda de significância com ponderação e LSS; "não resiste a violações"; Limitação "Um único período anterior" fala da restrição de suavidade; síntese "resiste a violações…") | 4.6 | conclusões |

**Fica no capítulo (não é teste de robustez):**
- o pré-teste de 2014, que é parte do desenho;
- as falsificações;
- a inferência por randomização (pendente de decisão);
- o mecanismo de 4.5.4.2 e 4.5.4.3: composição, decomposição, expansão das candidaturas fracas, cláusula e magnitude.

## Efeito na argumentação

- **H4:** a conclusão "não confirmada" passa a se apoiar no mecanismo. A composição das competitivas não muda, os ganhos ficam com as não competitivas e a queda da taxa dos homens produz a aproximação. É a leitura que a autora já escreveu na Introdução.
- **H1:** sem a ponderação, "concentrada em listas pequenas" sai. Fica só a magnitude do efeito.
- **Síntese da Discussão:**
  - "resiste a violações de tendências paralelas" sai;
  - "mais estáveis" passa a se referir à repetição nas duas eleições;
  - as categorias "frágil" e "não identificado" passam a ser justificadas pelo mecanismo e pelo pré-teste.

## Destino do material retirado

Os scripts e os CSVs ficam como estão. O texto retirado vai para um arquivo à parte do livro, fora da renderização, pronto para virar apêndice depois.

## Verificação

- Diff do .qmd: os números que somem são só os dos testes retirados, listados no commit.
- Nenhuma referência cruzada quebrada (`tbl-ddd-robustez`, `tbl-honestdid`, `fig-honestdid`, `sec-h4-sensibilidade`).
- Busca no texto por "pondera", "LSS", "ABD", "HonestDiD", "violações", "quebra" e "robustez": só o que for intencional.
- Render, quality score e leitura das passagens reescritas.
