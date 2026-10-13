# Session Log — ql-voto-2026

## 2026-10-13 — criação

**Pedido:** reproduzir o estudo do Cap. 6 incluindo as eleições de 2026.

**Bloqueio identificado:** o Cap. 6 inteiro (sobreposição, DDD, Modelos 2/3) se apoia em
`QL_gasto_eleit` (quociente locacional do gasto de campanha por município). A prestação de
contas de 2026 ainda não foi publicada (confirmado pela autora; prazo da final ~03/11/2026).
O `consulta_cand_2026.zip` que estava em `~/Downloads` (24/09) era pré-eleição, sem resultado.

**Decisão da autora (caminho 2):** refazer o estudo com QL do **voto** no lugar do QL do gasto,
para 2018, 2022 e 2026 (série inteira na mesma medida; 2018/2022 servem de validação contra o
capítulo). Modelo 3 (liderança/SGIP) fora do escopo desta rodada.

**Dados:** o CDN do TSE (`cdn.tse.jus.br`), que devolvia 403 em 08/2026 (ver
`explorations/senadoras-2026/SESSION_LOG.md`), voltou a aceitar download direto em 13/10/2026.
Baixados: `votacao_candidato_munzona_2026` (gerado pelo TSE em 13/10/2026), `votacao_partido_munzona_{2018,2022,2026}`, `consulta_cand_2026` (agora com resultado), `consulta_vagas_2026`. 2018/2022 da votação por
candidato vieram de `~/Desktop/Lab Eleições - Geografia Eleitoral/dados/brutos/`.

**Achados de dados ao inspecionar:**
- `competitivo` nas bases da autora = votos/QE ≥ 0,10 (verificado em fed. 2022 e est. 2018); eleito sempre competitivo.
- Vagas 2026 no `consulta_vagas` do TSE: 513 federais (não 531), 1.035 estaduais fora o DF.
- Legendas 2026 por número: 33 MOBILIZA = ex-PMN; 35 DEMOCRATA = ex-PMB; 14 MISSÃO (novo); 25 PRD.
  Decisão: 2018/2022 mantêm `harmonizar_partido()` original (replica o capítulo, evita
  sobreposição artificial entre legendas que eram distintas no ciclo); 2026 usa a sigla vigente.
- Estadual exclui DF, como no capítulo.

## 2026-10-13 — construção e validação

- `01_construir_ql_voto.R`: regra de QE/competitivo recalculada em 2022 concorda 99,9% com as
  bases da autora → aplicada a 2026. 2026: 7.051 cand. federais / 10.430 estaduais com voto;
  eleitos = 513 / 1.035 (= vagas). 2018: 296 fed. / 543 est. sem partido (PHS → NA, como no capítulo).
- **Validação falhou com QL_voto > 1 puro** (`05_validacao_gasto_voto.R`): base mediana de
  15–26 municípios (gasto: 2); sobreposição satura (54–70% no nível município vs. 26–36%);
  correlação candidato a candidato com a taxa do gasto 0,25–0,38; lacunas não se reproduzem
  (gênero quase some; raça inverte o sinal, ex. Fed. 2018 −3,6 vs. +5,8). Cobertura de 72% dos
  municípios-base de gasto pelo voto → problema é o tamanho da base, não a localização.
- **Calibração** (`05b_calibracao_base_voto.R`, só 2018/2022): base = QL_voto > 1 E fatia do
  município nos votos do candidato ≥ s, grade s ∈ {0; 2,5; 5; 10}%. Erro absoluto médio das 8
  lacunas vs. capítulo: 5,7 / **1,5** / 1,9 / 2,6 p.p. → **s = 2,5% principal** (mediana 3
  municípios, correlação 0,38–0,45), 5% robustez, 0 referência. Congelado antes de olhar 2026.
  Parametrizado em `R/config.R`; saídas em `output/fatia_025|050|000/`.

## 2026-10-13 — resultados (especificação principal: fatia ≥ 2,5%)

**Validação 2018/2022 vs. capítulo (gasto):** sobreposição no nível município 28–34% (gasto
26–36%); base mediana 3 municípios (gasto 2); correlação candidato a candidato 0,38–0,45 —
moderada: a medida de voto reproduz os agregados, não substitui o gasto candidato a candidato.
DDD réplica Federal × 2022 × Mulher: −3,2 p.p. (p = 0,005) vs. −2,9 (p = 0,057) no gasto.
Federal × 2022 × Negra: +2,6 (p = 0,057) vs. +0,7 (p = 0,72) no gasto — **diverge** do capítulo.

**2026 (descritivo):** lacunas persistem e são significativas em todas as células (p < 0,001):
mulheres − homens Fed. +5,8 (2022: +3,8), Est. +4,9 (5,1); negros − brancos Fed. +4,0 (3,7),
Est. +7,4 (6,7). Incumbentes seguem com sobreposição bem menor que não incumbentes
(Fed. 44,7% vs. 63,4%; Est. 50,4% vs. 69,5%). Sobreposição de eleitos < competitivos < não competitivos.

**2026 (DDD, três eleições, base 2018):** Federal × Mulher × 2022 −3,1 (p = 0,006), × 2026 −1,2
(p = 0,29) — a queda federal-específica de 2022 não se sustenta em 2026. Negra: 2022 +2,6
(p = 0,057), 2026 +2,5 (p = 0,10). Pós agrupado: mulher −2,3 (p = 0,02).
**Frágil:** com fatia ≥ 5% nenhum coeficiente da DDD é significativo (mulher 2022 −1,9, p = 0,26).

**Modelo 2 / alcance:** sem efeito para gênero; para raça, coeficiente de 2026 −1,4 p.p. (p = 0,013)
com EP ~3x menor que o de 2022 — tratar com cautela (provável efeito do nº/composição de
clusters de partido em 2026), não interpretar sem checar.

**Verificação:** 10 scripts fazem parse; 00 roda (pula zips existentes); run_all.R completo nas
3 variantes; sem caminhos absolutos; sem aleatoriedade. `quality_score.py` NÃO rodou — não há
Python instalado nesta máquina (só o alias da Microsoft Store); hook de pre-commit inativo.

**Pendências:** (1) refazer com QL do gasto quando o TSE publicar as despesas de 2026 (prazo
~03/11) — o pipeline do capítulo é o alvo; esta versão é preliminar/robustez; (2) Modelo 3
(liderança) não refeito; (3) investigar EP do Modelo 2 raça 2026; (4) decidir se/como entra
no texto do Cap. 6 (nada foi alterado no `.qmd`).
