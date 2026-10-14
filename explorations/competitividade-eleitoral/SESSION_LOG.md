# Session log — competitividade-eleitoral

## 2026-10-13

- Pedido: estudar como implementar a medida de competitividade de Avelino, Biderman & Desposato
  (2022, BPSR) na tese; depois, comparar com Luechinger, Schelker & Schmid (2024, PA).
- Os dois PDFs estão em `Tese/Literatura/` (OneDrive FINEP). As fórmulas de ABD foram conferidas
  no XML JATS da BPSR, porque o PDF perde os símbolos na extração.
- Dataverse de ABD (5GVHTE): tem só `rv` pronta, sem o código que a constrói. A soma no
  denominador foi confirmada pela base (`rv` dos eleitos ≤ 1).
- Dataverse de LSS (FBZMWN): traz funções em R para as margens de partido e de candidato e a
  agregação.
- Decisão: implementar a margem por busca com distribuição completa por regra do ano, para cobrir
  as cláusulas de 10/80/20% do QE. Protótipo testado nos exemplos dos dois artigos.
- Banda de "20%" de ABD = |rv| < 0,1 (bate com os 1.324 candidatos da Tabela 03).
- Decisões da autora: margem ÷ QE como medida principal; tripla diferença no nível da
  candidatura; incluir 2026. Plano DRAFT em `PLANO_2026-10-13_margem-ec111.md` (cópia em
  `quality_reports/plans/`), com a medida em dinheiro (D1 preço médio, D2 elasticidade,
  D3 distância de gasto).
- Inventário de dados: 2014–2022 completos na pasta do Lab (Desktop); de 2026 falta
  `votacao_candidato_munzona_2026`. O `consulta_cand_2026` de 24/09 tem a situação `#NULO`.
  A prestação de contas de 2026 ainda não saiu.
- Plano retificado (só votação) e aprovado. 01 (importação 2014–2026) e 02 (validação: 100%
  dos eleitos em 216 distritos; 2022 com 3ª fase aberta, o resultado recalculado) rodados.
- 03 foi interrompido por falta de memória; reiniciado com 3 núcleos e cache por distrito em
  `data/processed/margens_por_distrito/`. Ao terminar, rodar 03b, 04 e 05.

## 2026-10-14

- 03 concluído (200 distritos no cache + 16 com 1 núcleo). 03b, 04 e 05 rodados.
- Bandas de 0,25/0,5 QE saturam para candidaturas fracas; o principal passa a ser 0,1 QE.
- Mulheres: pré-teste ok; efeito de +3,6 p.p. (0,1 QE, sem peso), não significativo
  ponderado. Raça: pré-teste falha. Resultados no README.
- (Anterior) Próximo passo: baixar votos de legenda e composição de coligações/federações do TSE; validar a
  distribuição contra os eleitos; replicar `rv` de ABD em 2014.

## 2026-10-14 — competitividade pelo gasto derivada da margem OLPR

- Pedido: definir uma medida de competitividade eleitoral baseada no gasto a partir da margem
  de votos OLPR. Branch `worktree-competitividade-margem-gasto` (a partir desta).
- Decisões da autora: as três medidas, com **A (margem de gasto OLPR) como principal** e D2
  (dinheiro faltante por elasticidade) e D3 (gasto ÷ eleito marginal da lista) como
  complemento; 2014–2022, descritivo + tripla diferença. Plano aprovado em
  `quality_reports/plans/2026-10-14_competitividade-margem-gasto.md`.
- R/10: gasto por candidatura. Cobertura de 99,9% em 2018/2022 e de 83–85% em 2014 (as aptas
  sem registro entram com 0; nenhum eleito de 2014 sem registro).
- R/11: teste de sanidade (votos no lugar do gasto reproduzem a margem do R/03). Uma diferença
  de 1 voto apareceu ao mudar a ordem das listas: é o empate resolvido pela ordem dos dados,
  convenção já documentada. Fixada a mesma ordem do R/03.
- 2014 entra no estudo de evento sinalizado, sem leitura de pré-teste (decisão de 2026-09-28).
- R/11: bug no cluster (dir_cache não exportado) corrigido; 159 distritos em 28 min.
  O gasto, sozinho, elege 47–66% dos eleitos; Spearman com a margem de votos de 0,49 a 0,74.
- R/12: ε voto–gasto dentro da lista ≈ 0,23–0,33; D2 explode longe do limiar (só a banda
  serve). R/13: bug de geom_vline corrigido. R/14: voto reproduz o R/05 (+3,4); A +1,9 n.s.;
  "só pelo gasto" +1,0 n.s. A EC aproxima as mulheres pelo voto, não pelo gasto.
  Resultados no README.
