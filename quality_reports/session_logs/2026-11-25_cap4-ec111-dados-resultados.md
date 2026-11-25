# Sessão 2026-11-25 — Cap. 4 (03-ec111): revisão de Dados e Resultados

**Plano:** `quality_reports/plans/2026-11-25_cap4-ec111-dados-resultados.md` (aprovado; implementado)

## Objetivo
Responder às 11 perguntas da autora sobre Dados e Resultados e implementar os encaminhamentos.

## Decisões e mudanças
- **Dados (main):** `data/processed/` do main estava em 22/11, sem `viabilidade_ex_ante.rds`.
  Copiadas do worktree `cap4-cacaniquel-plano` as versões de 24/11 (cand_dep_2026,
  cand_ec111_2014_2026, did_2026_att_gt, painel_listas_2014_2026, receitas_cand_dep,
  viabilidade_ex_ante); antigas em `data/processed/_anterior_2026-11-22/`.
- **R/14 (novo):** recursos públicos (FEFC+FP por qualquer via; BITERS=25000, WILD=1999),
  cobertura do painel balanceado, descritiva de competitividade/viabilidade.
  Recursos públicos ≈ "versão ampla" (mulheres +8,4*/+7,4* vs +8,7/+7,3), substitui-a no texto.
  Pessoas negras: +5,1 em 2022 (IC exclui 0; p wild 0,06), +4,3 n.s. em 2026.
- **R/11 reescrito:** tabelas de regressão tradicionais (uma por grupo, colunas = variáveis do
  funil, EP por UF e p WCB); falsificação, composição e comparações adicionais no mesmo molde;
  decomposição e viabilidade com Federal × Pós; tabela descritiva nova; figuras
  `niveis_funil.png` e `niveis_taxas.png` substituem `niveis_por_cargo.png` (critério: dados
  brutos de cada variável dependente, ordem do funil). `principal.md` removida.
- **R/05:** amostra e cobertura numa só tabela, com % dos votos no painel; `cobertura.md` removida.
- **Texto:** Dados reescrita (painel balanceado definido e justificado; TSE como referência
  `TSE2026_dados_abertos`; versões dos arquivos e regra de cópias exatas em nota); nova subseção
  de competitividade e viabilidade; distribuição pela margem e calibração da banda → apêndice
  `chapters/A1-apendice-ec111.qmd` (`appendices:` no `_quarto.yml`); pré-teste só quando muda a
  leitura (disputa × lista em nota); H6 em um parágrafo; Discussão (pré-teste, dados 2026) encurtada.
- Conferido: 96–99% das transferências do partido são FEFC/FP (2018, 2022) — afirmação na Metodologia.

## Verificação
- R/14, R/05, R/11 rodam sem erro nem aviso. `quarto render Quarto/thesis` sem avisos; nenhuma
  referência cruzada não resolvida; apêndice com Figuras A.1–A.2.

## Revisão de redação (pedido da autora, 25/11)
- Trechos novos desta sessão reescritos com frases mais longas e conectores, sem dois-pontos nem
  travessões no texto corrido. Marcados com a classe nova `.revisao` (azul com fundo claro, em
  `alteracoes.css`), distinta de `.alterado` (rodadas anteriores). Supressões não têm marca.
- Legendas das tabelas geradas pelo R/11 não foram revisadas nesta rodada.

## Pendências
- Sem commit (aguarda a autora).
- `R/07` ainda gera `niveis_por_cargo.png` (não usada no livro).
- Pedido da autora de 25/11 ainda aberto: nenhum. Revisar visualmente as tabelas largas (9 colunas)
  quando o PDF (repUERJ) for ligado.
