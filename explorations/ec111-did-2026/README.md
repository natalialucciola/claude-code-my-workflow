# EC 111/2021 com 2026: DiD federal × estadual com dois períodos pós-tratamento

**Status:** exploração ativa (2026-10-13). Plano: `quality_reports/plans/2026-10-13_did-ec111-2026.md`.
**Antecessor:** `explorations/competitividade-gasto/` (DiD 2×2 2018→2022 e placebo 2014, à la Fonseca, Thomé & Guedes-Neto 2026).
**Destino (2026-11-07):** o funil (candidaturas → recursos → votos → cadeiras) e a decomposição competitivas × não competitivas foram levados ao Cap. 3, `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd`, junto com `explorations/competitividade-eleitoral/`. Figuras copiadas para `Quarto/thesis/Figures/03-ec111-competitividade/`.

## Pergunta

A EC 111/2021 conta em dobro, na distribuição do FEFC e do Fundo Partidário, os votos dados a mulheres e a pessoas negras para a **Câmara dos Deputados** (eleições de 2022 a 2030). O incentivo mudou, para esses grupos, (1) as candidaturas, (2) o gasto, (3) os recursos do partido, (4) a competitividade e (5) o sucesso? E o efeito de 2022 se manteve em 2026?

## Como incluir 2026: referências e escolhas

| Questão | Escolha | Referência |
|---|---|---|
| Estimador com mais de um período pós-tratamento | `did::att_gt`: cada ATT(g,t) é uma 2×2 limpa contra o grupo nunca tratado; adoção única → desenho 2×T | Callaway & Sant'Anna (2021, *J. Econometrics* 225(2)); Roth, Sant'Anna, Bilinski & Poe (2023, *J. Econometrics*) |
| Período de referência | **Base universal = 2018** (último pré). ATT(2026) = Δ2018→2026 federal − Δ2018→2026 estadual. Uma 2×2 de 2022 para 2026 compararia pós com pós e mediria só ATT(2026) − ATT(2022) | Roth (2024), "Interpreting event-studies from recent DiD methods" (arXiv 2401.12309); Callaway (2021), "Universal vs. varying base period" |
| Resumo | Efeitos dinâmicos (2022 e 2026) + média dos dois (`aggte(type = "group")`); evitar `simple` | Callaway & Sant'Anna (2021) |
| Hipótese de identificação | Tendências paralelas por **8 anos** (2018→2026), mais forte que por 4. Pré-teste com 2014 (evidência, não prova) | Roth (2022, *AER: Insights*) sobre pré-testes |
| Sensibilidade | Magnitudes relativas: violação pós ≤ M̄ × violação pré observada; o viés máximo acumula com o horizonte (k = 1 em 2022, 2 em 2026) | Rambachan & Roth (2023, *Rev. Econ. Stud.* 90(5)) |
| Listas que entram/saem (fusões, federações) | Painel balanceado (principal) + painel desbalanceado (`allow_unbalanced_panel`) como robustez — estimandos diferentes | Sant'Anna & Xu (2023/2025), "DiD with compositional changes" (arXiv 2304.13925) |
| Inferência | Bootstrap multiplicador, bandas uniformes, EP agrupados por lista; TWFE com EP por UF como robustez | Callaway & Sant'Anna (2021) |

### O que mudou entre 2022 e 2026 e entra no contraste

- **EC 133/2024** — mínimo de 30% do FEFC e do Fundo Partidário para candidaturas negras (STF manteve em jun/2026). Vale para os dois cargos, portanto é um choque comum. Mas se os partidos cumprirem a cota alocando no federal (onde o voto vale em dobro), a interação entra no efeito de 2026.
- **Cláusula de desempenho de 2,5%** (era 2% em 2022), medida só pelos votos para deputado federal. É um incentivo específico do cargo tratado para concentrar recursos em quem traz voto. É a principal ameaça ao contraste federal × estadual em 2026.
- Novas federações e fusões (PRD = PTB + Patriota; PSC → Podemos; PROS → Solidariedade; União–PP). As siglas foram harmonizadas para as de 2026, e a única sigla de 2026 sem lista em 2022 é MISSÃO.
- Queda de cerca de 25% no número de candidaturas em 2026, nos dois cargos (7.803 registros federais, contra 10.630 em 2022).

## Dados

| Ano | Candidaturas | Votos e resultado | Recursos e gasto |
|---|---|---|---|
| 2014 | bases da tese | idem | não usados (doação empresarial; decisão da autora em 2026-09-28) |
| 2018, 2022 | `explorations/competitividade-gasto` | idem | prestação final |
| 2026 | `consulta_cand_2026` (TSE, 13/10) | `votacao_candidato_munzona_2026`, `votacao_partido_munzona_2026` (TSE, 13/10) | **prestação parcial** (TSE, 13/10: relatórios de 72 h + parcial; a final vence em novembro) |

Mesmas regras de 2018/2022: candidaturas aptas (em 2026, reconstruídas pela situação de julgamento); competitiva = votos ≥ 10% do QE ou eleita; gasto = despesas contratadas sem repasses a outras candidaturas. Conferência de 2026 (`output/conferencia_2026.csv`): 505 eleitos federais (513 menos os 8 do DF), 1.035 estaduais; 7.099 candidaturas federais aptas (37,0% mulheres, 46,3% negras).

## Achados (pp; listas partido × UF; painel balanceado; sem ponderação; * IC 95% exclui 0)

Tabela completa, com versões ponderada (votos da lista em 2018), desbalanceada e no nível UF × cargo: `output/did_2026_resultados.csv`.

| Resultado | Pré-teste 2014 | 2022 | 2026 | Média |
|---|---|---|---|---|
| **1. Candidaturas** — mulheres (% da lista) | −0,9 | +3,3* | +2,7* | +3,0* |
| pessoas negras | +2,6 | +4,9* | +5,5* | +5,2* |
| **2. Gasto** — mulheres (% do gasto da lista) | — | +7,6* | +6,0* ᵖ | +6,8* |
| pessoas negras | — | +3,0 | +3,0 ᵖ | +3,0 |
| **3. Recursos do partido** — mulheres (% das transferências) | — | +12,7* | +12,3* ᵖ | +12,5* |
| pessoas negras | — | +4,1 | +5,1 ᵖ | +4,6 |
| Recursos públicos (FEFC + FP) — mulheres | — | +9,0* | +7,5* ᵖ | +8,3* |
| pessoas negras | — | +5,6* | +5,3 ᵖ | +5,4* |
| **4a. Votos** — mulheres (% dos votos nominais da lista) | −0,3 | +4,1* | +2,2 | +3,2 |
| pessoas negras | −0,5 | +3,3 | +2,6 | +3,0 |
| **4c. Parcela entre as competitivas** — mulheres | +1,6 | +2,0 | +2,7 | — |
| pessoas negras | −1,0 | −1,8 | −0,6 | — |
| **5. Cadeiras (UF × cargo, % dos eleitos)** — mulheres | −1,9 | −2,1 | +1,8 | −0,2 |
| pessoas negras | −3,6 | −5,0 | +1,9 | −1,6 |

ᵖ provisório (prestação parcial de 2026).

**Leitura:**

1. **O efeito pretendido aparece e persiste em 2026 para as mulheres.** A parcela das transferências partidárias destinada a mulheres sobe cerca de 12 pp no federal em relação ao estadual, tanto em 2022 quanto em 2026. A parcela do gasto sobe 6 a 8 pp. A parcela das candidaturas sobe cerca de 3 pp.
2. **O efeito sobre os votos das mulheres enfraquece em 2026.** Foi de +4,1* em 2022 para +2,2 (n.s.) em 2026, sobretudo porque as mulheres cresceram no estadual (20,3% → 25,5% dos votos) mais que no federal (20,9% → 24,1%). Em 2022 o efeito resiste a violações de tendência até 1,7× a pré-tendência; em 2026 não resiste a nenhuma.
3. **Não há efeito sobre competitividade nem sucesso.** A parcela de mulheres e de pessoas negras entre as candidaturas competitivas e entre os eleitos não muda de forma distinguível de zero. Mais dinheiro e mais candidaturas não se converteram em mais cadeiras, padrão consistente com Fonseca et al. (2026), segundo os quais os partidos concentraram o apoio em candidaturas não competitivas.
4. **Pessoas negras:** mais candidaturas (+5 pp, puxadas por listas pequenas: a versão ponderada dá ≈ 0) e mais recursos públicos em 2022 (+5,6*). Não há efeito em votos, competitividade ou cadeiras. Em 2026 o efeito dos recursos é parecido, mas a EC 133/2024 (choque comum) dificulta a interpretação.

**Cuidado — painéis 4b e 5 da figura de listas:** "% das candidaturas da lista que são do grupo e competitivas/eleitas" cai também para **todas** as candidaturas (−12,8* e −7,1* em 2022), ou seja, as listas federais balanceadas perderam competitividade em geral em relação às estaduais. Os valores negativos para os grupos nesses painéis são, em grande parte, mecânicos. Use 4c (parcela entre as competitivas) e as cadeiras no nível UF × cargo.

## Competitivas × não competitivas (margem de votos, 2026-10-14)

Medida da exploração `competitividade-eleitoral` (branch `worktree-competitividade-abd-lss`), com `margem_resultado.rds` copiado para `data/raw/`. **Competitiva** = eleita ou a menos de 0,1 QE do limiar de eleição. Pareamento: 97–100% das candidaturas, e eleito/a coincide em 99,8–100% (`output/pareamento_margem.csv`). Na decomposição, as partes competitivas + não competitivas somam o efeito total (checado no código). Figuras: `did_2026_evento_margem_presenca.png` e `did_2026_evento_margem_decomposicao.png`.

| pp, sem ponderação | 2022 | 2026 |
|---|---|---|
| Mulheres entre as competitivas (UF) | +2,1 | +1,5 |
| Mulheres entre as não competitivas (UF) | +0,8 | +1,3 |
| Votos de mulheres: competitivas / não competitivas (lista) | −1,1 / **+5,2*** | −0,3 / +2,5 |
| Gasto de mulheres: competitivas / não competitivas ᵖ | −0,3 / **+7,9*** | −0,3 / **+6,3*** |
| Recursos do partido a mulheres: competitivas / não competitivas ᵖ | +1,3 / **+11,4*** | +2,3 / **+10,0*** |
| Recursos do partido a pessoas negras: competitivas / não competitivas ᵖ | **−7,4*** / **+11,6*** | **−4,9*** / **+10,0*** |

**Leitura.** A EC não mudou a presença de mulheres nem de pessoas negras entre as competitivas. Os ganhos de votos, gasto e recursos ficaram com candidaturas que terminaram longe do limiar. Para pessoas negras, recursos migraram das competitivas para as não competitivas. Nos votos de pessoas negras, o pré-teste de 2014 aponta na mesma direção, o que sugere uma tendência anterior. A classificação é *ex post*: a decomposição é válida, mas as comparações dentro de cada categoria são descritivas.

## Veredito de credibilidade (graduado)

| Bloco | Veredito | Por quê |
|---|---|---|
| Recursos e gasto, mulheres | **Moderado** | Efeito grande, estável entre 2022 e 2026 e nas versões ponderada e não ponderada. Mas não há pré-teste (2014 é outro regime de financiamento) e 2026 é provisório |
| Candidaturas, mulheres | **Moderado** | Pré-teste ≈ 0. Pequeno e sensível à ponderação (ponderado +1,6, n.s.) |
| Votos, mulheres | **Moderado em 2022, fraco em 2026** | Pré-teste ≈ 0. Em 2026 o efeito não sobrevive à sensibilidade de magnitudes relativas, e a cláusula de 2,5% é um choque concorrente só no federal |
| Competitividade e sucesso | **Nulo bem estimado na direção, impreciso no nível UF** | 52 disputas: IC largos para cadeiras |
| Pessoas negras | **Fraco** | Resultados dependem da ponderação. A EC 133/2024 confunde a parte de 2026 |

Limites gerais: o tratamento é do cargo (só um "cluster" tratado, como em qualquer DiD federal × estadual); há muitos resultados (comparações múltiplas); e o painel balanceado de 4 eleições (801 listas) é um subconjunto das listas.

## Regra de contagem da prestação de contas (decisão da autora, 2026-11-09)

**Problema.** Até 08/11 o gasto e as receitas eram montados com **uma linha por `SQ_DESPESA` / `SQ_RECEITA`** (a base `despesas_categorizadas_dep_{2018,2022}` do projeto de análise da tese seguia essa regra). O diagnóstico de 09/11 mostrou que o código identifica o **documento** (nota fiscal, contrato, recibo), não o item: dentro de um mesmo código, valor e descrição variam em ~90% dos grupos, enquanto candidatura, fornecedor, data e tipo de prestação nunca variam. Exemplos: uma nota com dez itens de material impresso (santinhos, adesivos, banners) de um mesmo fornecedor; duas quinzenas de pagamento de pessoal sob o mesmo código.

**Decisão.** Remover **só as linhas idênticas em todas as colunas** (cópias exatas). Implementada em `ler_prestacao()`, em `explorations/competitividade-gasto/R/funcoes_apoio.R`, e usada no gasto de 2018/2022 (`competitividade-gasto/R/01`, agora lido direto do zip do TSE), nas receitas de 2018/2022 (`R/04`) e no gasto e nas receitas de 2026 (`ec111-did-2026/R/01`). Nenhuma candidatura tem mais de um tipo de prestação (final/parcial) nos arquivos do TSE, então não há soma de prestações sucessivas.

| Gasto de deputados (R$ mi) | Todas as linhas | Só cópias exatas removidas (regra nova) | Uma linha por código (regra antiga) |
|---|---:|---:|---:|
| 2018 | 2.161,7 | 2.148,1 | 1.791,8 |
| 2022 | 4.790,8 | 4.747,9 | 3.999,3 |
| 2026 | 5.151,5 | 5.110,1 | 4.287,0 |

Receitas: efeito de ~0,4% (2022: 5.037,7 → 5.055,3). Conferência por cargo em `explorations/competitividade-gasto/output/conferencia_regra_deduplicacao.csv`.

**Efeito no Cap. 3** (rodada única de 09/11, junto com a votação republicada, 25.000 réplicas): estimativas do funil mudam até 0,4 p.p., nenhuma significância muda; tripla diferença pelo voto e HonestDiD inalterados; na margem de gasto, a média de 2022–2026 para mulheres negras − homens brancos passa de +4,4 (IC excluía zero) para +1,9 (não exclui), e para pessoas negras − brancas, de +2,3 para −0,2.

**Propagação:** Cap. 2, financiamento (receitas e gasto por candidatura), em 09/11 (`explorations/cap2-descritivo/R/02`). **Ainda não propagado:** a base geográfica `ql_gasto_eleit_*` (usada no Cap. 2, geografia do gasto, e no Cap. 5), construída fora do repositório; os scripts 02, 03, 06 e 07 de `competitividade-gasto`.

## Votação de 2026 republicada pelo TSE (2026-11-09)

O TSE republicou `votacao_candidato_munzona_2026.zip` (09/11) e `votacao_partido_munzona_2026.zip` (08/11); cópias em `data/raw/tse_20261108/`. Em relação à versão de 13/10: eleitos idênticos (1.572); duas candidaturas estaduais saem do arquivo (116 votos); uma estadual do MS é indeferida e seus 33.768 votos passam a legenda; 86 candidaturas passam a "indeferido", e as aptas caem para 7.065 (federal) e 10.618 (estadual); o painel balanceado vai de 801 para 799 listas. A distribuição de cadeiras reproduz 100% dos eleitos nos 216 distritos. Comparação em `output/versoes_votacao_2026/` (script `R/00_comparar_versoes_votacao_2026.R`).

## Pendências e desvios

- **HonestDiD do funil:** `output/did_2026_sensibilidade_rm.csv` traz só o **conjunto identificado** sob magnitudes relativas ± 1,96 EP. A restrição de magnitudes relativas do `HonestDiD` roda no R 4.2.3 local (é usada em `competitividade-eleitoral/R/10_honestdid.R`); só a de suavidade exige R ≥ 4.3.
- **Replicação da etapa anterior:** o efeito 2018→2022 sobre os votos das mulheres dá +4,7 neste painel, contra +5,2 na etapa anterior. A diferença vem das siglas harmonizadas para 2026 (fusões juntam listas: 1.111 contra 1.219).
- Rodadas finais com `biters = 25000` (variável de ambiente `BITERS`; o padrão do script já é 25000).

## Como rodar (da raiz)

```
Rscript explorations/ec111-did-2026/R/01_bases_2026.R      # ~5 min; zips do TSE em data/raw/
Rscript explorations/ec111-did-2026/R/02_painel_listas.R   # requer base de 2018/2022 de competitividade-gasto (scripts 01, 04, 05)
Rscript explorations/ec111-did-2026/R/03_did_event_study.R # pacotes did, fixest
Rscript explorations/ec111-did-2026/R/05_tabela_amostra.R  # tabela de amostra do Cap. 3 (Quarto/thesis/chapters/_tabelas-cap3/amostra.md)
Rscript explorations/ec111-did-2026/R/06_niveis_por_cargo.R  # níveis por cargo dos desfechos de parcela (output/niveis_por_cargo.csv); confere o ATT 2×2
```

Entradas em `data/raw/` (não versionadas): `votacao_candidato_munzona_2026.zip`, `votacao_partido_munzona_2026.zip`, `consulta_cand_2026.zip`, `prestacao_de_contas_eleitorais_candidatos_2026.zip` (TSE, CDN; versões em uso: votação de 08–09/11/2026, registro e prestação de contas de 08/11/2026) e as bases de 2014 listadas no script 02.

## Teste das laranjas (21/11/2026) — `R/09_teste_laranjas.R`

Pergunta: a EC 111 trocou candidaturas laranja (votos <= 1% do último eleito da UF, cargo e ano;
Gatto & Wylie 2021) por candidaturas caça-níqueis (acima do corte, não competitivas)?
Desenho da tbl-ddd: UF × cargo, sem DF, sem ponderação, base 2018, pré-teste 2014, EP por UF.
Saídas: `output/teste_laranjas.csv` (corte de 1%) e `output/teste_laranjas_corte5.csv` (5%).

- Corte de 1%: a taxa de laranjas no federal sobe para os dois sexos (homens: 12,2% → 25,8%
  em 2022, em médias por UF). DDD mulheres − homens = 0,0 [−4,5; 4,6] em 2022 e +2,7 em 2026.
  Nada indica que as laranjas tenham sido substituídas por caça-níqueis.
- Corte de 5%: DDD mulheres − homens = −5,1* (2022) e −4,1* (2026), pré-teste +2,4 (n.s.).
  Há sinal de substituição só na faixa logo acima das laranjas mais extremas.
- Pré-teste do DiD simples falha nos dois cortes: em 2014 as laranjas eram mais comuns no federal.
- Leitura: resultado sensível ao corte. A substituição não fica comprovada. A expansão de
  candidaturas no federal produziu mais candidaturas quase sem votos, de homens e de mulheres.

## Variáveis principais do Cap. 4 (22/11/2026) — `R/10_variaveis_principais.R`

Plano: `quality_reports/plans/2026-11-22_cap4-ec111-variaveis-identificacao.md`.
Erros agrupados por UF em todas as variáveis; comparação com o complemento (homens; não negras;
demais candidaturas), com pessoas brancas e homens brancos como linhas adicionais nas diferenças
de taxas; investimento relativo por candidatura (razão das médias das transferências do partido);
p-valor por wild cluster bootstrap restrito (Webb, UF) como conferência; níveis por cargo.
Depende de `data/processed/cand_ec111_2014_2026.rds`, salvo pelo `R/02`.
Saídas: `output/variaveis_principais_{resultados,niveis,comparacao}.csv`.
Depois de R/10, `R/11_tabelas_figuras_capitulo.R` escreve as tabelas do capítulo em
`Quarto/thesis/chapters/_tabelas-cap3/` (principal, sucesso, transferencias_cargo, decomposicao,
falsificacao) e as figuras `efeitos_etapas.png` e `transferencias_por_cargo.png`. O PDF avulso
do capítulo é derivado por `Quarto/capitulo4-pdf/derivar.py`.

## Categorias de receita (24/11/2026)

Plano: `quality_reports/plans/2026-11-24_cap4-categorias-receita-falsificacao.md` (recomendações
aceitas pela autora). **Problema:** "outras fontes" (`rto`, `receita_outras`) era receita total −
transferências do partido e incluía os repasses de outras candidaturas, dos quais 80–86% são FEFC ou
Fundo Partidário (a fonte é preservada no `DS_FONTE_RECEITA` do repasse). A Metodologia descrevia o
teste de falsificação só com doações e recursos próprios.

**Regra:** `categorizar_receita()` / `resumir_receitas()` em `competitividade-gasto/R/funcoes_apoio.R`,
usadas em `competitividade-gasto/R/04` (2018/2022) e `R/01` (2026). Cinco partes que somam a receita
total (assert de R$ 0,01): `receita_partido` (inalterada), `repasse_cand_pub` (outras candidaturas,
FEFC/FP), `repasse_cand_priv` (outras candidaturas, outros recursos), `receita_privada` (pessoas
físicas, internet, financiamento coletivo, próprios, comercialização) e `receita_residual`
(rendimentos, origem não identificada; < 0,1%). Estimáveis mantidos. As categorias de 2018/2022
entram no `R/02` direto de `receitas_cand_dep.rds` (o `R/05` de competitividade-gasto não foi
refeito). Medidas do painel: `rtp`, `rtc_pub`, `rtc_priv`, `rtpriv` (falsificação, com wild
bootstrap), `rtres` e `rec_partido_ampla` (partido + repasses públicos; robustez da H2).

| FEFC + FP repassados por outras candidaturas (R$ mi) | 2018 | 2022 | 2026 |
|---|---:|---:|---:|
| A candidaturas estaduais | 115 | 128 | 96 |
| A candidaturas federais | 26 | 26 | 18 |

**Conferências:** colunas antigas de `receitas_cand_dep.rds`, `cand_dep_2026.rds`, painéis e base por
candidatura idênticas às anteriores; no `R/10` final (BITERS=25000, WILD=1999; `rtpriv` na posição do
antigo `rto`, novas medidas no fim da grade) as 304 linhas já existentes saíram idênticas, inclusive
bandas e p do wild.

**Resultados (p.p.; * IC 95% exclui zero, EP por UF):**

- Falsificação (`rtpriv`): mulheres +1,7 (p wild 0,06) e −0,4; mulheres negras +0,5 e +0,1; pessoas
  negras +1,7* em 2022 (p wild 0,05) e −1,1. O antigo +3,0* das pessoas negras em 2022 era +1,0
  (repasses públicos) + 0,3 (repasses privados) + 1,7 (privada).
- Repasses públicos a pessoas negras: +1,0 (2022) e +2,4* (2026), compatível com a EC 133/2024.
- H2 ampla: mulheres +8,7* e +7,3* (contra +12,4 e +12,2); mulheres negras +6,7* e +5,9*; pessoas
  negras +4,9* (p wild 0,055) e +4,3. Totais nacionais, mulheres estaduais: 44,1% → 38,8% na medida
  ampla, contra 51,2% → 40,3% na direta; dois cargos: 31,9 / 33,9 / 36,0. Em 2018, os repasses de
  FEFC/FP às estaduais foram pouco para mulheres (15,8%).

`R/03` e `R/07` (fase anterior; nenhuma saída no capítulo) foram atualizados para as novas medidas,
mas não rodados de novo: `did_2026_resultados.csv` ainda traz `rto`.

## Viabilidade ex ante: para quem foi o acréscimo das transferências (2026-11-24)

Plano: `quality_reports/plans/2026-11-24_cap4-cacaniquel-item1-implementacao.md` (item 1 do teste caça-níquel). Scripts: `R/12_viabilidade_ex_ante.R` (classificação), `R/13_cacaniquel_viabilidade.R` (decomposição e estimação; usa `R/funcoes_estimacao.R`, cópia idêntica de `estimar()`/`wild_p()` do R/10) e a seção 6 do `R/11`.

**Classificação.** Uma candidatura é viável ex ante se, na eleição anterior (*t − 4*), foi eleita deputada no mesmo cargo (V1), no outro cargo (V2) ou terminou a menos de 0,1 QE do limiar em qualquer dos dois cargos (V3). A pessoa é ligada entre eleições pelo CPF do `consulta_cand` (título eleitoral na falta dele). Cobertura: 99,8% a 100%, e CPF 100% igual ao das bases da tese. Reeleitos federais: 239, 279 e 292. Robustez: só V1; V3 só no mesmo cargo. Decisões da autora (24/11): medir na lista; 2022 e 2026 medidos da mesma forma.

**Tamanhos.** Mulheres viáveis federais: 71 (2018), 129 (2022), 136 (2026). O aumento de 2022 vem de deputadas estaduais que passaram ao federal (V2: 5 → 23) e de quem ficou perto do limiar (V3: 24 → 52). Mulheres negras viáveis federais: 18, 43 e 44 (0,7 a 1,7 por UF). Por isso as medidas ficam na lista, como decomposição aditiva, sem dividir pelo número de viáveis.

**Resultado** (p.p., transferências do partido, listas balanceadas 2018–2026; \* IC 95% exclui zero, EP por UF):

| | Mulheres 2022 / 2026 | Pessoas negras 2022 / 2026 | Mulheres negras 2022 / 2026 |
|---|---|---|---|
| Total | +12,4\* / +12,2\* | +3,4 / +4,1 | +8,1\* / +8,4\* |
| Viáveis ex ante (observado) | −0,8 / −0,8 | −7,0\* / −6,0\* | −0,5 / −0,6 |
| Viáveis ex ante (esperado pela divisão federal de 2018) | +2,7 / +2,6 | +1,3 / +1,6 | +1,2 / +1,3 |
| Não viáveis ex ante | +13,2\* / +13,0\* | +10,4\* / +10,1\* | +8,5\* / +9,0\* |

**Leitura.** O acréscimo das transferências às mulheres foi inteiro para candidatas que não eram viáveis antes da eleição. A parte das viáveis não se move, quando a divisão de 2018 previa cerca de +2,7. O padrão se repete no gasto e nos votos, nas duas robustezes da classificação e em 2026. Para pessoas negras há realocação, com o dinheiro saindo das viáveis. A matriz viável × competitiva (`output/viabilidade_matriz_2x2.csv`) mostra que a célula "viável que fracassou" é pequena e não cresce (federal, mulheres: 9,2 → 7,5% das transferências). A célula "não viável e não competitiva" sobe de 44,5 para 65,5% no federal, contra 63,3 → 67,8% no estadual. A leitura ex post do capítulo, portanto, não confundia intenção com ineficácia.

**Cuidados.** Não há pré-teste: as transferências começam em 2018, e a viabilidade de 2014 exigiria 2010. O federal de 2018 já era mais concentrado nas viáveis que o estadual (36% contra 19% das transferências às mulheres, totais nacionais). A fatia da coluna "esperado" é média de listas (0,21 para mulheres), não total nacional. Os votos decompostos aqui usam o painel de 2018–2026, e não o de 2014–2026 do R/10.

## Competitividade, eleição e investimento relativo na lista (2026-11-24)

Plano: `quality_reports/plans/2026-11-24_cap4-competitividade-na-lista.md`. **Decisão da autora:** a hipótese é de estratégia partidária, então a unidade é a lista (partido × UF × cargo), onde o partido decide, e não a disputa (UF × cargo), que mistura todos os partidos. As variáveis da disputa continuam no R/10 (para comparação, `output/competitividade_lista_vs_disputa.csv`) e saem do capítulo.

**Medidas (R/10, seção 1b; linhas no fim da grade, de modo que as 364 linhas anteriores ficaram idênticas à rodada de 24/11).**

- *Principal:* diferença de taxas dentro da lista, `ltcv` (competitiva pelo voto), `ltcg` (pelo gasto) e `ltel` (eleita), dada pela taxa do grupo menos a do complemento, com `_br` e `_hb` como comparações adicionais. Só exige os dois grupos na lista (617 listas para mulheres, 483 para pessoas negras e 381 para mulheres negras, em 2014–2026). Não seleciona pelo resultado.
- *Investimento relativo:* `lexcesso` = % das transferências − % das candidaturas do grupo na lista (substitui a razão `inv`, indefinida quando um grupo recebe zero).
- *Mecanismo* (seção 2b, `output/competitividade_lista_ponderada.csv`): `lpcv`, `lpcg` e `lcadeira`, a proporção do grupo entre as competitivas e entre os eleitos da lista. São estimadas por TWFE ponderado pelo denominador, em painel desbalanceado (a lista sem competitivas não entra naquele ano).
- *Robustez:* as taxas ponderadas pelo número de candidaturas da lista em 2018.

**Resultados** (p.p.; * IC 95% exclui zero, EP por UF; p do wild entre parênteses):

| Taxa do grupo − complemento | 2014 | 2022 | 2026 |
|---|---|---|---|
| Competitiva pelo voto, mulheres | +2,5 | +6,7 (0,057) | +7,3* (0,023) |
| Competitiva pelo voto, pessoas negras | +3,8 | +5,6 (0,12) | +8,2* (0,018) |
| Eleita, mulheres | −1,4 | +3,6 (0,24) | +5,7* (0,057) |
| Competitiva pelo gasto, mulheres negras | — | +8,8* (0,003) | +8,7* (0,027) |
| Investimento relativo, mulheres | — | +9,7* (0,000) | +9,2* (0,001) |

**Leitura.**

1. Na lista, os pré-testes de 2014 ficam próximos de zero para todos os grupos. Na disputa, falhavam para pessoas negras (−5,7* e −4,4*).
2. As taxas na lista dão o dobro da disputa e são significativas em 2026. Mas, ponderadas pelo tamanho da lista, caem para +1 a +4 e nenhuma é significativa: a melhora relativa se concentra nas listas pequenas, onde uma candidata a mais muda muito a taxa.
3. A proporção do grupo entre as competitivas e entre os eleitos da lista não muda (mulheres: +1,4 e +1,0 em 2022). Ou seja, a taxa melhora, mas os lugares competitivos não passam para as mulheres.
4. O investimento relativo das mulheres (+9,7*, contra +17,0* na disputa) vem da queda no estadual (o excesso médio das listas cai de +18,9 para +10,0), com o federal perto de zero. É a realocação entre cargos já descrita no capítulo.

**Tabelas (R/11):** `principal.md` e `sucesso.md` passam às medidas de lista, com a coluna "Listas"; nova `composicao_lista.md` (`tbl-composicao-lista-ec111`, ainda não incluída no `.qmd`). O texto do capítulo (H4, H5, Variáveis, Métodos) ainda descreve a disputa e precisa ser refeito.
