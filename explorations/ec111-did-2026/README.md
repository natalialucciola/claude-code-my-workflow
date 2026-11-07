# EC 111/2021 com 2026: DiD federal × estadual com dois períodos pós-tratamento

**Status:** exploração ativa (2026-10-13). Plano: `quality_reports/plans/2026-10-13_did-ec111-2026.md`.
**Antecessor:** `explorations/competitividade-gasto/` (DiD 2×2 2018→2022 e placebo 2014, à la Fonseca, Thomé & Guedes-Neto 2026).
**Destino (2026-11-07):** o funil (candidaturas → recursos → votos → cadeiras) e a decomposição competitivas × não competitivas foram levados ao Cap. 4, `Quarto/thesis/chapters/04-ec111-competitividade-eleitoral.qmd`, junto com `explorations/competitividade-eleitoral/`. Figuras copiadas para `Quarto/thesis/Figures/04-ec111-competitividade/`.

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

## Pendências e desvios

- **HonestDiD não instalado** (R 4.2.3 local; a dependência `CVXR` não está disponível para esta versão). `output/did_2026_sensibilidade_rm.csv` traz o **conjunto identificado** sob magnitudes relativas ± 1,96 EP, sem a inferência de Rambachan & Roth. Para a tese, rodar o `HonestDiD` num R ≥ 4.3.
- **Deduplicação das despesas por `SQ_DESPESA`.** É a regra usada em 2018/2022 (reproduz exatamente os R$ 3.999 mi de `despesas_categorizadas_dep_2022`) e foi mantida em 2026 por comparabilidade. Mas ela descarta linhas que não são cópias: em 2022, deduplicar por linha dá R$ 4.652 mi (+16%). A decisão é da autora e afeta igualmente as análises anteriores.
- **Recursos de 2026:** refazer quando sair a prestação final (prazo em nov/2026). Basta trocar o zip em `data/raw/` e rodar 01 → 03.
- **Replicação da etapa anterior:** o efeito 2018→2022 sobre os votos das mulheres dá +4,7 neste painel, contra +5,2 na etapa anterior. A diferença vem das siglas harmonizadas para 2026 (fusões juntam listas: 1.111 contra 1.219).
- `biters = 1000` (exploração). Usar 25.000 na versão final.

## Como rodar (da raiz)

```
Rscript explorations/ec111-did-2026/R/01_bases_2026.R      # ~5 min; zips do TSE em data/raw/
Rscript explorations/ec111-did-2026/R/02_painel_listas.R   # requer base de 2018/2022 de competitividade-gasto (scripts 01, 04, 05)
Rscript explorations/ec111-did-2026/R/03_did_event_study.R # pacotes did, fixest
```

Entradas em `data/raw/` (não versionadas): `votacao_candidato_munzona_2026.zip`, `votacao_partido_munzona_2026.zip`, `consulta_cand_2026.zip`, `prestacao_de_contas_eleitorais_candidatos_2026.zip` (TSE, CDN, 13/10/2026) e as bases de 2014 listadas no script 02.
