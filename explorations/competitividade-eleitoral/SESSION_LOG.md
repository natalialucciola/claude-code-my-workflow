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
- Próximo passo: baixar votos de legenda e composição de coligações/federações do TSE; validar a
  distribuição contra os eleitos; replicar `rv` de ABD em 2014.
