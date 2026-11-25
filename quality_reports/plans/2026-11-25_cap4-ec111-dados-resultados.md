# Plano — Cap. 4 (arquivo 03-ec111): revisão de Dados e Resultados

**Status:** COMPLETED (2026-11-25; aprovado pela autora: "Salve o plano e comece sua implementação"). Registro: `quality_reports/session_logs/2026-11-25_cap4-ec111-dados-resultados.md`
**Arquivo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd`
**Scripts:** `explorations/ec111-did-2026/R/` (05, 07, 10, 11, 12)

Origem: 11 perguntas da autora sobre Dados e Resultados, respondidas na sessão de 25/11 com
justificativa e encaminhamento. Todos os encaminhamentos aprovados.

## Encaminhamentos (numeração das perguntas)

| # | Tema | Ação | Arquivos |
|---|------|------|----------|
| 1 | Painéis balanceados | Parágrafo em Dados: definição, razão (EF de lista + entradas/saídas de listas), cobertura do painel (% candidaturas e votos por cargo × ano). Corrigir nota da tbl-amostra (lista = partido × cargo × UF). Tirar do texto a enumeração de Ns (fica na coluna Listas). | qmd, R/05 |
| 2 | Duas tabelas de amostra | Fundir amostra + cobertura numa tabela (cobertura por grupo vira frase). | R/05, `_tabelas-cap3/amostra.md`, remover include de cobertura |
| 3 | Distribuição por competitividade | Figuras 4.1–4.2, calibração das bandas e validação da margem → apêndice do capítulo. Ponto de partida de 2018 fica na tabela descritiva (item 5). | qmd, novo apêndice, `_quarto.yml` |
| 4 | Datas/características TSE | Referência ao Repositório de Dados Eleitorais do TSE no .bib; versões dos arquivos, harmonização de siglas e regra de cópias exatas em nota de rodapé; parágrafo "Dados de 2026" da Discussão reduzido. | qmd, Bibliography_base.bib |
| 5 | Viabilidade e competitividade na amostra | Nova tabela descritiva grupo × complemento × cargo × ano: % competitivas pelo voto, pelo gasto, eleitas, viáveis antes da eleição. | novo script ou R/12/R/11 |
| 6 | Critério da Figura 4.3 | Critério = dados brutos de cada variável dependente, ordem do funil. 4.3a: candidaturas, transferências, gasto, votos. 4.3b: sucesso relativo (competitiva voto, gasto, eleita) por cargo. Sem receita total e recursos públicos. | R/07 ou R/11 |
| 7 | Transferências × recursos públicos | Transferências = medida principal; uma só conferência = recursos públicos (FEFC+FP por qualquer via), substituindo a "versão ampla". Reestimar com dados atuais antes de reescrever; checar pessoas negras. | R/10, R/11, qmd |
| 8 | Federal × Pós ausente | Padronizar colunas (pré-teste, 2022, 2026, diferença, Federal × Pós) nas tabelas de estimação, incl. decomposição e viabilidade. | R/11 |
| 9 | Tabelas de regressão tradicionais | Uma tabela por grupo: colunas = variáveis do funil; painel A = Federal × 2014/2022/2026 (EP por UF; p WCB); painel B = Federal × Pós; linhas: diferença 2026−2022, média dep. federal 2018, listas, obs., EF, cluster. Falsificação e composição no mesmo molde. | R/10, R/11 |
| 10 | Pré-teste | Coeficiente nas tabelas; no texto só quando falha ou muda a leitura; parágrafo disputa × lista → nota; limite na Discussão encurtado. | qmd |
| 11 | 2022 × 2026 | H6 reduzida a um parágrafo (diferenças distinguíveis, meia largura dos IC, o que mudou), remetendo à Figura 4.4 e à linha de diferença. | qmd |

## Ordem de execução

1. Entender R/10 e R/11 (estimação e saída das tabelas); descobrir o que já é salvo (EP, p WCB, N).
2. R: tabelas de regressão por grupo (9, 8), recursos públicos (7), tabela de amostra fundida + cobertura do painel (1, 2), tabela descritiva (5), figura 4.3 (6).
3. Texto: Dados (1, 2, 4, 5), apêndice (3), Resultados (6–11), Discussão (4, 10).
4. Render `quarto render Quarto/thesis`; conferir números do texto contra os CSVs; checar refs cruzadas.
5. Session log; atualizar CLAUDE.md (estado do capítulo) se necessário. Sem commit até a autora pedir.

## Verificação

- Scripts rodam sem erro no R 4.2.3; tabelas `.md` regeneradas.
- Números citados no texto conferem com os CSVs (diferenças zero).
- Render sem warnings de refs cruzadas; figuras e apêndice aparecem no HTML.
- Itens que dependem de decisão da autora (ex.: resultado de recursos públicos para pessoas negras muda conclusão) são relatados, não decididos.
