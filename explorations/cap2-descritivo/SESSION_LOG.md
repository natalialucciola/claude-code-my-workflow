# Session Log — cap2-descritivo

## 2026-10-13 — criação

**Pedido da autora:** excluir os Capítulos 2–5 (placeholders) e criar um novo Capítulo 2,
descritivo (sem hipóteses), sobre mulheres e negros nas eleições para deputado federal e estadual,
2014–2026, cobrindo todas as variáveis usadas depois na tese, com tendências por partido e por
região/UF/magnitude. Plano: `quality_reports/plans/2026-10-13_cap2-descritivo.md`.

**Decisões da autora (AskUserQuestion):** partidos = 12 maiores individualmente + blocos
ideológicos; financiamento/gasto até 2022 com 2026 marcado como pendente; Cap. 05b mantido entre
o 2 e o 6.

**Dados e validação:**
- CDN do TSE aceitou download direto: consulta_cand e consulta_vagas 2014/2018/2022,
  votacao_partido_munzona 2014. Votação por candidato 2014 da pasta do Lab no Desktop.
- 2014: arquivo de votação só tem QT_VOTOS_NOMINAIS → válidos = candidaturas DEFERIDAS (com ou
  sem recurso); votos de "INDEFERIDO COM RECURSO" (8.240) excluídos.
- Regra única de eleito/competitivo para 2014–2026: eleitos = vagas nos 8 recortes; concordância
  com as bases da autora 99,8%–100% (Est. 2014–2022, Fed. 2018–2022).
- Financiamento: 100% dos eleitos têm registro de receita; 5–16% das candidaturas não têm →
  tratadas como zero nos anos com prestação publicada.
- Classificação ideológica: Tabela 1 de Bolognesi, Ribeiro, Codato & Silva (2025, Opinião
  Pública 31, rodada 2022), extraída do PDF; extintos (DEM, PSL, PHS, PPL, PRP) pela rodada 2018
  (Bolognesi, Ribeiro & Codato 2023, Dados 66(2)). PRD = média PTB/Patriota (regra dos autores).

**Bugs encontrados e corrigidos na sessão:**
- 04: financiamento todo NA (candidaturas sem registro entravam como NA nas somas) → zero nos
  anos com prestação.
- 01: fatias de voto na base/capital NA porque `votos` era resumido antes no `summarise()` →
  reordenado; painel reconstruído (demais colunas inalteradas).
- `plot_annotation()` do patchwork incompatível com o ggplot2 4.0 instalado → legenda no painel.

**Texto:** conferido número a número contra as tabelas geradas; 5 afirmações corrigidas antes do
render (convergência mulheres brancas × homens negros só a partir de 2022; exceção nos recursos
públicos para negros estaduais 2014; recursos próprios/PF só desde 2018; magnitude inverte para
mulheres no estadual e UFs de 8 vagas no Norte/Centro-Oeste; quase paridade da esquerda só no
federal).

**Pendências:** financiamento e geografia do gasto de 2026 (após a publicação do TSE); CoVe nas
duas referências novas; `/proofread` no capítulo.
