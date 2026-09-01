# Proofreading Report: `01-revisao-literatura.qmd`

**File:** `Quarto/thesis/chapters/01-revisao-literatura.qmd`
**Date:** 2026-09-01
**Scope:** Capítulo 1 ("Revisão de Literatura") — tese de doutorado, português acadêmico, formato Quarto/pandoc.

Todas as 12 chaves de citação usadas no capítulo foram checadas contra `Bibliography_base.bib` — todas existem e correspondem ao conteúdo/autoria descritos. Nenhum problema de citação inexistente. Sintaxe de citação pandoc (`[@key; @key2]`) bem formada; hierarquia de headers consistente. Nenhum erro estrutural/mecânico encontrado.

---

### Issue 1 — Referência cruzada incorreta ("a seção seguinte")
- **Local:** "Tipologia de Mecanismos..." — "O caso brasileiro, como a seção seguinte detalha, é uma cota de candidatura em sistema de lista aberta..."
- **Problema:** A seção seguinte é "Interseccionalidade", não a que detalha o caso brasileiro (isso só vem duas seções depois, em "Trajetória Legal e Institucional").
- **Proposto:** "...como a seção 'Trajetória Legal e Institucional' detalha adiante..."
- **Categoria:** Consistência (referência estrutural) — **Severidade: Major**

### Issue 2 — Erro aritmético: "23 anos" não bate com as datas citadas
- **Local:** "Trajetória Legal..." e "Síntese" (repetido nas duas seções)
- **Atual:** "o eixo de gênero teve 23 anos de cota de candidatura (1997) antes de ganhar proporcionalidade de financiamento (2018)"
- **Problema:** 2018 − 1997 = 21, não 23. O número "23" só bate se contado a partir de 1995 (Lei 9.100/1995, mencionada antes no mesmo parágrafo) ou até 2020 (mecanismo racial), não até 2018.
- **Proposto:** Corrigir para "21 anos... (1997)" **ou**, se a intenção é contar desde 1995, mudar o parêntese para "(1995)".
- **Categoria:** Precisão factual/numérica — **Severidade: Major** ⚠️ *É o achado mais importante deste relatório — número errado repetido 2x, inclusive na Síntese.*

### Issue 3 — Termo-chave da tese usado de forma inconsistente
- **Local:** Intro ("a geografia do gasto de campanha") vs. demais seções ("a geografia da campanha eleitoral")
- **Proposto:** Padronizar um único termo, ou marcar explicitamente como equivalentes na primeira ocorrência.
- **Categoria:** Consistência (terminologia) — **Severidade: Major**

### Issue 4 — Terminologia racial inconsistente
- **Local:** "mulheres e negros" → "mulheres negras" → "candidaturas autodeclaradas pretas e pardas" → "candidatos afro-brasileiros" (4 termos em 2 páginas)
- **Problema:** "Pretas e pardas" é a categoria oficial de autodeclaração do IBGE usada na decisão da ADPF — vale marcar essa distinção explicitamente em vez de deixar implícita a equivalência com os outros termos.
- **Proposto:** Explicar na primeira ocorrência (ex.: "candidatos negros (autodeclarados pretos ou pardos, categoria oficial do IBGE)") e manter consistente depois.
- **Categoria:** Consistência/precisão terminológica — **Severidade: Major**

### Issue 5 — Referência ambígua a "Capítulo 6"
- **Local:** "...é o argumento geral de @Gatto2025_resistance_quotas, cujo Capítulo 6 desenvolve..."
- **Problema:** "Capítulo 6" já foi usado (intro e síntese) para se referir ao Capítulo 6 *desta tese*; aqui se refere ao capítulo do livro da Gatto — confuso.
- **Proposto:** "...cujo próprio sexto capítulo desenvolve..." ou "no Capítulo 6 da obra de Gatto..."
- **Categoria:** Clareza/consistência — **Severidade: Major**

### Issue 6 — Quarta dimensão de Pitkin introduzida e nunca retomada
- **Local:** "...quatro dimensões — formalística, descritiva, simbólica e substantiva. Descritiva e simbólica são... Substantiva é..."
- **Problema:** "Formalística" é citada mas nunca explicada, deixando a tipologia com uma lacuna.
- **Proposto:** Acrescentar cláusula breve (ex.: "a formalística, referente à autorização e prestação de contas institucionais, não é o foco deste capítulo").
- **Categoria:** Qualidade acadêmica (paralelismo incompleto) — **Severidade: Major**

### Issues menores (15, severidade Minor)

| # | Local | Problema | Proposto |
|---|---|---|---|
| 7 | "fast track"/"incremental" | Itálico inconsistente para termos estrangeiros | Itálico em *fast track*; sem aspas em "incremental" |
| 8 | *candidatura*, *reservadas*, etc. | Itálico usado tanto para termos estrangeiros quanto para ênfase em português | Reservar itálico só para termos estrangeiros |
| 9 | "rádio e televisão" vs. "rádio/TV" | Abreviação inconsistente | Padronizar uma forma |
| 10 | "FEFC" | Sigla nunca definida por extenso na primeira ocorrência | Definir "(FEFC)" já na primeira menção do nome completo |
| 11 | STF, TSE, ADPF, ADI, PSOL | Siglas institucionais nunca expandidas | Expandir ao menos STF e TSE na primeira menção |
| 12 | "West Bengal e Rajastão" | Um nome em inglês, outro aportuguesado | Padronizar ("Bengala Ocidental e Rajastão") |
| 13 | "lideranças mulheres"/"lideranças homens" | Construção não-padrão | "líderes mulheres... líderes homens" |
| 14 | "partiram de pontos de partida diferentes" | Repetição tautológica da raiz "part-" | "seguiram caminhos institucionais diferentes" |
| 15 | "mostra/mostram que" (8+ ocorrências) | Verbo repetitivo | Variar: demonstra, evidencia, documenta, argumenta |
| 16 | "explorando" em frases consecutivas | Repetição entre sentenças adjacentes | Variar o segundo uso |
| 17 | Síntese, 3º ponto | Falta @BeamanEtAl2012 no cluster de citação (os outros dois da mesma seção estão lá) | Incluir a terceira citação |
| 18 | "mecanismos de representação de minoria" | Concordância de número | "...de minorias" (plural) |
| 19 | Frase longa sobre ADI 5.617/STF/TSE | 3 orações encadeadas só por vírgula | Quebrar em duas frases |
| 20 | Frase final do parágrafo de Ruanda | Frase >70 palavras; "ou" ambíguo (Índia OU Ruanda vs. Brasil?) | Quebrar em duas; trocar "ou" por "e" |
| 21 | Frase de abertura do capítulo | ~70 palavras, duas perguntas de pesquisa numa só frase | Quebrar após os dois-pontos |

---

## Resumo

- **6 issues Major** (1–6) — sobretudo consistência interna e um erro factual/numérico real (Issue 2).
- **15 issues Minor** (7–21) — formatação de itálico, siglas, repetição de estilo, frases longas.
- Nenhum erro de sintaxe de citação pandoc, colchetes desbalanceados, hierarquia de headers ou chave de citação inexistente.

Nenhum arquivo foi editado no momento deste relatório, conforme o protocolo `/proofread`.

---

## Atualização (2026-09-01): todas as 21 correções aplicadas

A pedido da autora, todas as correções acima (6 major + 15 minor) foram aplicadas diretamente em `Quarto/thesis/chapters/01-revisao-literatura.qmd`. Destaques:

- **Issue 2 corrigida:** "23 anos" → "21 anos" nas duas ocorrências (Trajetória Legal e Síntese).
- **Issue 4 corrigida:** primeira menção de "pretas e pardas" agora explica que é a categoria oficial de autodeclaração do IBGE, com nota de que o capítulo passa a usar "candidaturas negras" — e "candidatos afro-brasileiros" (na frase da EC 111) foi alinhado para "candidatos negros".
- Demais issues (1, 3, 5, 6 e as 15 minor) aplicadas conforme a proposta de correção de cada uma.
- Verificação pós-edição: todas as 12 chaves de citação continuam existindo em `Bibliography_base.bib`; colchetes e marcadores de itálico permanecem balanceados no arquivo.
