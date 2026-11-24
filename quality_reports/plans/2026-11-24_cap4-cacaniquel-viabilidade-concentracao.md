# Plano: testar diretamente a hipótese caça-níquel (Cap. 4, EC 111)

**Status:** DRAFT (aguarda aprovação da autora)
**Data:** 2026-11-24
**Capítulo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd` (exibido como Cap. 4)
**Exploração:** `explorations/ec111-did-2026/`

## Pergunta

O capítulo testa a hipótese caça-níquel por um padrão (H1–H3 confirmadas, H4–H5 não, ganhos nas não competitivas). Dois pontos fracos foram identificados:

1. **A decomposição usa competitividade *ex post*.** "Não competitiva" é definida pelo resultado, de modo que o dinheiro dado a uma candidata viável que fracassou conta como caça-níquel. Falta uma base de comparação: a fatia que as competitivas já recebiam antes.
2. **O espalhamento ("pulverização") é inferido, não medido.** Ele aparece só indiretamente, via margem de gasto.

O plano cria (1) uma classificação de **viabilidade *ex ante*** e (3) **medidas diretas de concentração** das transferências do partido entre as candidatas.

## O que já se sabe (descritivo, 24/11, totais nacionais, mulheres, sem DF)

| Ano | Cargo | Candidatas | % competitivas (ex post) | % das transf. às mulheres que vão às competitivas | % com transf. > 0 | % das transf. com os 10% mais financiados |
|---|---|---:|---:|---:|---:|---:|
| 2018 | Federal | 2.368 | 7,1 | 46,3 | 81,8 | 80,8 |
| 2022 | Federal | 3.268 | 4,6 | 26,9 | 92,2 | 59,9 |
| 2026 | Federal | 2.610 | 6,2 | 31,4 | 92,1 | 56,0 |
| 2018 | Estadual | 4.989 | 6,5 | 34,3 | 77,7 | 75,2 |
| 2022 | Estadual | 5.109 | 5,8 | 29,3 | 85,4 | 58,3 |
| 2026 | Estadual | 3.700 | 8,2 | 32,1 | 89,2 | 53,0 |

Leitura preliminar:

- **Item 1:** o acréscimo foi muito mais para as não competitivas do que a divisão de 2018 previa (as competitivas tinham 46% e ficaram com cerca de 7% do acréscimo). A evidência atual deve se fortalecer, mas o estadual também caiu (34 → 29).
- **Item 3:** a desconcentração é forte **nos dois cargos** (os 10% mais financiados caem cerca de 20 p.p. em ambos). Ela pode ser um choque comum, como a reserva proporcional de 2022, e não um efeito do voto em dobro. A diferença em diferenças pode dar perto de zero. Nesse caso, a "pulverização" atribuída à EC 111 no texto precisaria ser reformulada.

Script do descritivo: tabela acima, a partir de `data/processed/cand_ec111_2014_2026.rds`. Vira a Etapa 0 abaixo.

---

## Item 1 — Decomposição por viabilidade *ex ante*

### 1a. Base de comparação na decomposição atual (barato, sem dados novos)

- Nova medida no nível da **disputa** (UF × cargo, 52 unidades): **fatia das transferências do grupo que vai para as suas competitivas**, $\text{transf}_{g,\text{compet}} / \text{transf}_g$. No nível da lista não serve, porque a maior parte das listas não tem nenhuma mulher competitiva.
- DiD com a mesma `estimar()` do R/10 (base 2018, erros por UF, wild bootstrap).
- Na tabela de decomposição, acrescentar a coluna **"esperado se o acréscimo seguisse a divisão de 2018"**: $s_{2018} \times \Delta$, ao lado do observado.
- Previsão caça-níquel: a fatia cai no federal em relação ao estadual. Investimento em viáveis: a fatia sobe ou fica estável.

### 1b. Classificação *ex ante* (dados novos: ligação entre eleições)

**Identificador.** CPF do `consulta_cand` (cobertura de 99,8% a 100% das candidaturas a deputado em 2014–2026, conferida em 24/11; valores `-4` mascarados são tratados como ausentes e, no seu lugar, usa-se o título eleitoral, também com 99,8% a 100%). Arquivos em `data/raw/tse/consulta_cand_{2014,2018,2022,2026}.zip`.

**Definição.** A candidata *i* na eleição *t* é **viável ex ante** se, na eleição *t − 4*:

| Critério | Definição | Fonte |
|---|---|---|
| V1 Incumbente | eleita no mesmo cargo | `cand_ec111` (eleito) |
| V2 Mandato no outro cargo | eleita deputada estadual e agora candidata a federal, ou o inverso | idem |
| V3 Competitiva não eleita | margem de votos a menos de 0,1 QE do limiar | `margem_resultado.rds` (cobre 2014) |

- **Principal:** V1 ∪ V2 ∪ V3.
- **Robustez:** só V1. Opcional, a decidir pela autora: V4, mandato municipal eleito em *t − 2* (prefeitura ou vereança em 2016/2020/2024), o que exige baixar o `consulta_cand` e os resultados municipais.
- **Cobertura temporal:** 2018 usa 2014, 2022 usa 2018 e 2026 usa 2022. Todos estão disponíveis. Não há pré-teste para as transferências, como no restante do capítulo. Para os votos, o pré-teste de 2014 exigiria os dados de 2010, que não estão no disco.

**Medidas** (lista, mesmo estimador):

- Decomposição da proporção das transferências do partido para o grupo: **viáveis ex ante + não viáveis ex ante = total**. O mesmo vale para o gasto e os votos.
- Disputa: fatia das transferências do grupo que vai para as suas viáveis ex ante (análoga à 1a).
- Investimento relativo por candidatura: razão entre a transferência média das viáveis e a das não viáveis dentro do grupo (análoga às medidas `inv_c`/`inv_nc` do R/10).

**Leitura conjunta, uma matriz 2 × 2 descritiva:** viável ex ante × competitiva ex post, com a fatia das transferências em cada célula, por ano e cargo.

- Não viável → não competitiva: **caça-níquel**.
- Viável → não competitiva: **investimento que falhou**.

É isso que separa intenção de ineficácia, o problema central da classificação ex post.

**Ressalva.** A composição de quem se candidata muda com a EC (H1: mais candidatas novas). A queda da fatia das viáveis pode vir do maior número de não viáveis e não de uma mudança na alocação. Por isso a razão por candidatura (investimento relativo) vem junto: ela não depende de quantas há.

---

## Item 3 — Concentração das transferências entre as candidatas

Unidade: a **lista**, onde o partido decide. A amostra se limita às listas com pelo menos duas candidatas do grupo em todos os anos de 2018 a 2026, e o tamanho da amostra será reportado.

| Medida | Definição | Caça-níquel prevê | Investimento em viáveis prevê |
|---|---|---|---|
| **C1 Alcance** | % das candidatas do grupo com transferência > 0 | sobe | estável |
| **C2 Candidata mais financiada** | transferência à candidata do grupo mais financiada da lista, como % das transferências da lista | estável enquanto a proporção do grupo sobe | sobe |
| **C3 Número efetivo** | $N_{ef} = 1/\text{HHI}$ das transferências entre as candidatas do grupo, dividido pelo número de candidatas ($N_{ef}/n$, de 0 a 1) | sobe (dinheiro mais igual entre elas) | cai |
| C4 Acima de um patamar | % das candidatas com transferência ≥ 50% da transferência mediana dos eleitos do mesmo cargo, UF e ano; sensibilidade com 25% e 100% | estável | sobe |

- **Principais (pré-especificadas):** C2 e C3, com wild bootstrap. C1 e C4 são secundárias. Isso limita as comparações múltiplas.
- **Contraste com os homens (DDD):** a mesma medida para os homens da lista, e a diferença mulheres − homens no DiD. Se a desconcentração vier da reserva proporcional (choque comum, regra de 2022), ela aparece nos dois cargos e nos dois sexos. O DDD isola o que é específico das mulheres no federal.
- **Níveis por cargo**, como em `tbl-transferencias-cargo-ec111`, porque o descritivo já indica choque comum.
- **Problema mecânico:** HHI e a fatia dos mais financiados caem automaticamente quando *n* cresce. Por isso C3 é normalizada por *n*, e C2 é medida como fatia da lista inteira, não da fatia do grupo.

---

## Etapas

| # | Etapa | Arquivo | Verificação |
|---|---|---|---|
| 0 | Viabilidade da amostra: número de mulheres, pessoas negras e mulheres negras viáveis ex ante por ano e cargo; número de listas com pelo menos duas candidatas em todos os anos. **Parar e consultar a autora** se houver menos de ~5 viáveis por disputa em média | `R/12_viabilidade_ex_ante.R` (parte 1) | tabela de tamanhos |
| 1 | Ligação por CPF ou título entre eleições e classificação V1–V3. Reaproveitar o bloco de incumbência de `competitividade-eleitoral/R/05_ddd_margem.R` (l. 106–135) | `R/12`, salva `data/processed/viabilidade_ex_ante.rds` | incumbentes federais por ano entre ~250 e 300 (reeleição esperada); conferir contra `ST_REELEICAO`, se o campo existir no consulta_cand |
| 2 | Extrair `estimar()` e `wild_p()` do R/10 para `R/funcoes_estimacao.R` e fazer o R/10 usar esse arquivo | `R/10`, novo `R/funcoes_estimacao.R` | `output/variaveis_principais_resultados.csv` idêntico ao atual (diff) |
| 3 | Medidas 1a, 1b e C1–C4 e estimação | `R/13_cacaniquel_testes.R` → `output/cacaniquel_{viabilidade,concentracao}.csv` | partes da decomposição somam o total (assert no código); níveis por cargo batem com o descritivo da Etapa 0 |
| 4 | Tabelas e figura para o capítulo | `R/11` ou `R/14` → `chapters/_tabelas-cap3/` | render do capítulo |
| 5 | Texto, **só depois de a autora ver os números**: Variáveis (`tbl-variaveis-ec111`), H4 "Onde ficaram os ganhos", parágrafo da previsão (l. 70), limite "Medidas de competitividade" e Discussão | `.qmd` do capítulo; `Quarto/capitulo4-pdf/derivar.py` | `quarto render`, PDF derivado, números conferidos contra os CSVs |

Rodar da raiz, como os demais scripts (`Rscript explorations/ec111-did-2026/R/12_...R`). `WILD=1999` nas rodadas de teste e `WILD=9999` na final, como no R/10.

## Decisões para a autora

1. **Mandato municipal (V4):** incluir? Exige baixar o `consulta_cand` e os resultados municipais de 2016, 2020 e 2024. Recomendação: **não na primeira rodada**. V1–V3 já capturam a viabilidade mais relevante para deputado.
2. **Patamar da C4:** 50% da mediana dos eleitos é uma escolha arbitrária. Fica como secundária, com sensibilidade.
3. **Se a C2/C3 der DiD nulo** (choque comum, como sugere o descritivo): aceitar reformular a "pulverização" no texto como efeito da reserva proporcional, comum aos dois cargos, mantendo como efeito da EC 111 só o deslocamento do dinheiro entre cargos e a destinação às não viáveis?

## Fora do escopo

- O teste laranja × caça-níquel (item 2 da avaliação) já existe: `R/09_teste_laranjas.R`, com resultado sensível ao corte.
- O HonestDiD do funil continua pendente, como no README.
