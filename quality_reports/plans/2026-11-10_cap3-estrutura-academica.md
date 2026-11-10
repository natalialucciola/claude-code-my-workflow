# Plano: Cap. 3 (EC 111) em estrutura acadêmica padrão

**Status:** COMPLETED (aprovado em 2026-11-10; implementado no mesmo dia)
**Data:** 2026-11-10
**Arquivo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd`
**Origem:** pedido da autora de 10/11 (estrutura padrão, revisão de literatura consolidada, hipóteses formais, metodologia antes dos dados, variáveis descritas uma a uma, amostra com contagens por ano e cargo) + decisões tomadas no mesmo dia.

## Decisões da autora (10/11)

| Tema | Decisão |
|---|---|
| Subseções | Nenhuma por padrão; só onde for indispensável, e cada uma listada aqui para aprovação |
| Tratamento | Equações (DiD por estágio e tripla diferença) + esquema 2×2 (cargo × período) |
| Hipóteses | H1–H6, uma por estágio do funil |
| Revisão de 10/11 | Incorporar os pontos de texto (FEFC, transbordamento, mudanças concorrentes); pesos e IC das tabelas ficam para outra etapa |
| Literatura | Só reorganizar as referências já existentes, sem busca externa |

## Estrutura nova (7 seções)

Os rótulos `#sec-...` de seções que continuam existindo são mantidos, para não quebrar referências cruzadas de outros capítulos. Os rótulos que saem são verificados com grep em todo o livro.

### 1. Introdução (`#sec-introducao-ec111`)
Texto aprovado em 10/11, mantido. Ajuste mínimo: a frase "um voto conta o mesmo para o fundo…" passa a falar do *bônus* da EC 111, para ficar coerente com a regra do FEFC (ver seção 2). Sem subseções.

### 2. Revisão da Literatura (`#sec-literatura-ec111`): consolida as atuais 4.2 e 4.3
Ordem dos parágrafos, sem subseções:
1. **Estudos sobre a EC 111 e incentivos financeiros à representação.** Evangelista et al. (2024) e Trindade (2025) são descritivos; Lucciola (2023) e Fonseca et al. (2026) estimam efeitos. Ver se Squires (2024), que já está no `.bib`, trata de cotas de recursos e cabe aqui; se não couber, fica de fora.
2. **O que a regra premia.** As três propriedades atuais (dirigida ao partido, premia votos, vale só para o federal), reescritas em prosa. Corrigir a regra do FEFC (2% iguais, 35% pelos votos para a Câmara, 48% pelas cadeiras na Câmara, 15% pelo Senado; Fundo Partidário essencialmente pelos votos) e dizer que o voto em dobro vale uma única vez para mulheres negras. **Conferir as porcentagens no texto da Lei 9.504/1997, art. 16-D, antes de escrever.**
3. **História legislativa e o mecanismo de proteção.** Gatto (2025) e o vínculo com o Cap. 5.
4. **Lacuna:** o que este capítulo acrescenta a Fonseca et al. (2026), em uma frase, sem repetir a Introdução.
5. **Hipóteses formais H1–H6**, numa lista com enunciado testável e direção:
   - **H1 (candidaturas):** a EC 111 aumentou a parcela de mulheres, pessoas negras e mulheres negras entre as candidaturas das listas federais, em relação às estaduais.
   - **H2 (recursos e gasto):** aumentou a parcela da receita, das transferências partidárias e do gasto destinada a esses grupos, e o aumento vem das transferências do partido.
   - **H3 (votos):** aumentou a parcela dos votos nominais obtida por esses grupos.
   - **H4 (competitividade):** aumentou a proporção de candidaturas desses grupos perto do limiar de eleição, em relação ao grupo de comparação, medida pelo voto e pelo gasto.
   - **H5 (eleição):** aumentou a taxa de eleição e a parcela das cadeiras desses grupos.
   - **H6 (persistência):** os efeitos de 2022 se mantêm em 2026.

   Em seguida, o parágrafo atual sobre as duas leituras: colheita de votos (H1–H3 confirmadas, H4–H5 não) × investimento em candidaturas viáveis (H1–H5 confirmadas).

### 3. Metodologia (`#sec-desenho-ec111`): passa a vir antes de Dados
Parágrafos, com no máximo as subseções propostas abaixo:
1. **Abordagem.** DiD federal × estadual com várias eleições e adoção única, estimador de Callaway & Sant'Anna, base 2018, pré-teste 2014. A estratégia é atribuída a Fonseca et al. (2026), como pedido em 10/11.
2. **Esquema 2×2** (tabela Markdown curta, sem figura nova): linhas para federal (tratado a partir de 2022) e estadual (nunca tratado); colunas 2014 | 2018 | 2022 | 2026, com as células indicando pré-teste, base, efeito 2022 e efeito 2026.
3. **Equações** (LaTeX no Quarto):
   - Efeito por estágio: $ATT(t) = \big[E(Y^{F}_{t}) - E(Y^{F}_{2018})\big] - \big[E(Y^{E}_{t}) - E(Y^{E}_{2018})\big]$, para $t \in \{2014, 2022, 2026\}$ ($t = 2014$ é o pré-teste).
   - Tripla diferença: o mesmo $ATT(t)$ aplicado a $D_{c,u,t} = \text{taxa}_{g} - \text{taxa}_{\text{comparação}}$ na disputa UF × cargo.
   - Persistência: $\Delta = ATT(2026) - ATT(2022)$, com erro-padrão pela função de influência.
4. **Adaptações aos limites do caso:** um único tratado (o cargo); um só período anterior (2014); recursos sem pré-teste por causa da doação empresarial; duas unidades de análise (lista e disputa) e por quê; tripla diferença para as taxas; painel balanceado. **Novo:** transbordamento entre federal e estadual (orçamento e grupo de candidatas compartilhados) e choques nacionais do cargo federal que o agrupamento por UF não captura.
5. **Variáveis**, descritas uma a uma numa tabela com nome, definição, unidade, anos e papel:
   - **Dependentes:** % do grupo nas candidaturas, receita total, transferências do partido, recursos públicos, gasto, votos nominais, competitiva pelo voto, competitiva pelo gasto, eleita, % das cadeiras.
   - **Independente / tratamento:** federal × período pós-2022.
   - **Grupos:** mulheres, pessoas negras, mulheres negras, com a comparação de cada um.
   - **Controles:** o desenho não usa covariáveis; os efeitos fixos de lista e período são implícitos no estimador. O texto diz isso explicitamente e explica a ponderação pelos votos de 2018 e pelo número de candidaturas como robustez.
6. **Medidas de competitividade.** A margem de votos (definição, cálculo por busca e callout de validação) e a margem de gasto saem da atual seção "Dados e medidas" e passam a ficar aqui, porque são variáveis dependentes construídas. A figura de faixas de margem acompanha.
7. **Hierarquia dos desfechos** (tabela atual) e **mudanças concorrentes** (lista atual + EC 117/2022 e a distribuição proporcional a candidaturas negras desde 2020, como choques comuns aos dois cargos).

**Subseções propostas (para aprovar):** "Estimação", "Variáveis" e "Medidas de competitividade". Sem elas, a Metodologia teria cerca de 2.500 palavras sem pausa. Se preferir nenhuma, vira prosa contínua com frases de abertura.

### 4. Dados (`#sec-medida-ec111`)
1. **Fontes e procedimentos:** arquivos do TSE (candidaturas, votação, prestação de contas), datas das versões de 2026, regra de cópias exatas, harmonização de siglas, exclusão do DF, definição de gênero e raça.
2. **Amostra.** Nova tabela gerada por script, com uma linha por ano × cargo (2014–2026) e as colunas:
   - candidaturas aptas, % de mulheres, % de pessoas negras, % de mulheres negras;
   - candidaturas com prestação de contas registrada (n e %);
   - candidaturas com receita > 0 e com gasto > 0 (n e %), também por grupo;
   - listas no painel balanceado e disputas.

   Isso responde ao pedido de mostrar de quantas candidaturas há dados de receita e gasto.
   - **Script novo:** `explorations/ec111-did-2026/R/05_tabela_amostra.R`. Lê as bases já processadas (`data/processed/`) e grava `output/tabela_amostra.csv`; o capítulo inclui uma tabela Markdown gerada a partir desse CSV, como no Cap. 2 (`chapters/_tabelas-cap3/`).
   - Já existem `descritivo_grupos_ano_cargo.csv` e `competitividade-eleitoral/output/gasto_cobertura.csv`, mas a cobertura é da regra antiga e não separa por grupo. Por isso o script é novo.
3. Um parágrafo de leitura da tabela: queda de cerca de 25% nas candidaturas em 2026, cobertura da prestação de 2014 (83–85%) contra mais de 99% depois, e as cerca de 400 candidaturas de 2026 só com prestação parcial.

### 5. Resultados (`#sec-resultados-ec111`)
Ordem por hipótese, H1 → H6. Cada bloco abre com "H_k: confirmada / não confirmada / não identificada" e reúne o texto atual do estágio. Todas as tabelas e figuras atuais ficam. O que muda:
- **Persistência** (hoje seção própria) passa a ser o bloco de H6.
- **"Onde o efeito se perde"** (decomposição competitivas × não competitivas) entra no fim de H2–H4, onde é usada.
- **Fragilidade da competitividade pelo voto** (cláusula, magnitude, tendência anterior, HonestDiD) entra no bloco de H4.
- Corrigir a contradição da persistência ("nenhuma diferença significativa" × "a única diferença significativa") e unificar a nomenclatura das transferências a candidaturas negras competitivas (MC4 da revisão), porque é só texto.

**Subseções propostas (para aprovar):** uma por hipótese ("H1 · Candidaturas", …, "H6 · Persistência"). É a principal exceção: são cerca de 4.000 palavras e 5 tabelas. A alternativa é nenhuma subseção, com o rótulo da hipótese em negrito no início do parágrafo.

### 6. Discussão (`#sec-discussao-ec111`)
Texto atual ("O que a EC 111 fez e o que não fez" + leitura da literatura) em prosa, sem subseções. As Limitações entram como os últimos parágrafos, com o transbordamento e os choques nacionais acrescentados. Fecha com o resumo causal em três categorias: robusto (recursos às mulheres, candidaturas não competitivas), frágil (competitividade das mulheres pelo voto) e não identificado (competitividade e eleição de pessoas negras e de mulheres negras).

### 7. Conclusão (`#sec-conclusao-ec111`)
Texto atual, com a ressalva sobre as mulheres negras nas cadeiras (mc4 da revisão).

## Ajustes aprovados em 10/11, depois do rascunho
- Metodologia com duas subseções: "Estimação" (desenho, esquema 2×2, equações, pré-teste, limites do caso) e "Variáveis" (incluindo as duas margens). Sem subseção própria para as medidas de competitividade.
- Resultados com uma subseção por hipótese (H1–H6).
- O modelo é apresentado também como a regressão linear 2×2 equivalente.
- Sem a robustez com efeitos fixos de UF × ano nesta etapa.
- A autora prefere estimar por regressão linear de DiD tradicional numa etapa futura.

## Fora do escopo desta etapa (para depois)
- Harmonizar pesos e IC entre tbl-ddd e tbl-honestdid (MC5) e reescrever a justificativa da restrição de magnitudes relativas (MC6), que depende do resultado do script.
- Inferência alternativa (wild bootstrap e randomização).
- CoVe, proofread e as pendências já listadas no comentário do fim do capítulo.

## Etapas
1. Script `05_tabela_amostra.R`: rodar e conferir os totais contra `descritivo_grupos_ano_cargo.csv` e `gasto_cobertura.csv`.
2. Conferir a regra do FEFC no texto da lei.
3. Reescrever o `.qmd` na nova ordem, movendo texto e mantendo números e tabelas idênticos. Diff de números: todo número do capítulo antigo deve aparecer no novo, salvo os removidos de propósito, listados no commit.
4. Grep de rótulos `@sec-` em todo o livro; renderizar o livro.
5. `quality_score.py` no capítulo; commit no main; republicar a página "Estado dos Capítulos"; atualizar `capitulos.json`.
6. Avisar a autora com o link e a lista do que mudou de lugar.

## Verificação
- O livro renderiza sem aviso de referência quebrada.
- Mesmo conjunto de tabelas e figuras, mais a tabela de amostra e o esquema 2×2.
- Checagem automática de que nenhum número desapareceu sem motivo.
- A tabela de amostra bate com os CSVs existentes nas contagens de candidaturas.
