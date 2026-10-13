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
- (Anterior) Próximo passo: baixar votos de legenda e composição de coligações/federações do TSE; validar a
  distribuição contra os eleitos; replicar `rv` de ABD em 2014.
