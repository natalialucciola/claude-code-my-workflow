# Plano: modelo do Cap. 4 (EC 111) como regressão linear de diferenças em diferenças

**Status:** CONCLUÍDO em 17/11 (sem commit; aguarda a autora)
**Data:** 2026-11-17
**Arquivo:** `Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd` (Cap. 4 no livro; commit `011689f`)

## Decisões da autora (17/11)

| Tema | Decisão |
|---|---|
| Modelo | Regressão de DiD tradicional, no formato de Cunningham (*Mixtape*, cap. 9): estudo de evento por ano e termo único Federal × Pós |
| Período "antes" do termo único | **Só 2018**, o último período antes do tratamento; 2014 entra como pré-teste no estudo de evento |
| Unidade | As mesmas do capítulo: lista partido × UF (parcelas) e disputa UF × cargo (taxas) |
| Controles | Só efeitos fixos de unidade e de ano, sem covariáveis |
| Inferência | Erros agrupados (como hoje) mais **inferência por randomização** (troca de sinal por UF) |
| Apresentação | Gráfico de dados brutos por cargo; falsificações apresentadas como tais |

## Referência metodológica: o que Cunningham recomenda e como entra no capítulo

| Recomendação (*Mixtape*, cap. 9) | Situação no capítulo | O que muda |
|---|---|---|
| 2×2 em forma de regressão: Y = α₀ + α₁·Tratado + α₂·Pós + δ·(Tratado × Pós) | Há só a equação 2×2 por ano | Equação principal: δ com efeitos fixos de unidade e de ano, 2018 contra 2022–2026 |
| Estudo de evento, com referência no último período antes do tratamento; coeficientes anteriores = tendência diferencial | Já estimado (CS = regressão de estudo de evento, \|dif\| < 1e-6) | Escrito e apresentado como regressão; CS citado como o estimador que dá os mesmos coeficientes e as bandas uniformes |
| Gráfico dos dados brutos | Níveis só no texto (H2, H3) | Figura nova com as médias por cargo e ano |
| Falsificações: grupo não afetado; desfecho não afetado | Existem sem esse nome: tripla diferença (grupos de comparação), receita de outras fontes (nula), placebo 2014–2018 | Parágrafo curto na Metodologia que as declara como falsificações, com remissão aos resultados |
| Poucos grupos ou um só tratado → randomização | 26 UFs, um único cargo tratado | Inferência por randomização (troca de sinal por UF) |
| Juntar os dados em antes e depois só como recurso de inferência | — | O termo único é apresentado como resumo do efeito pós-emenda, e não como substituto do estudo de evento |

O trecho lido do livro não cobre a tripla diferença nem a adoção escalonada. Nada sobre esses pontos é atribuído a Cunningham.

## Especificação

**Termo único (principal):**
$$Y_{ut} = \mu_u + \lambda_t + \delta\,(\text{Federal}_u \times \text{Pós}_t) + \varepsilon_{ut}, \qquad t \in \{2018, 2022, 2026\}$$
Pós = 1 em 2022 e 2026. Com o painel balanceado, δ = média dos efeitos de 2022 e 2026. O script confere isso (\|dif\| < 1e-6).

**Estudo de evento:**
$$Y_{ut} = \mu_u + \lambda_t + \sum_{k \in \{2014, 2022, 2026\}} \delta_k\,(\text{Federal}_u \times 1[t = k]), \quad \text{referência } 2018$$
$\delta_{2014}$ é o pré-teste. A conferência exige que reproduza `did_2026_resultados.csv` e `ddd_resultados.csv`.

**Robustez (só em CSV, fora do corpo):** δ com o "antes" = 2014 e 2018, para mostrar o quanto a pré-tendência infla o termo único (estimativa grosseira: pessoas negras, competitiva pelo voto ≈ 6,2 contra 3,3); versões ponderadas; painel desbalanceado.

**Unidades e desfechos:**
- **Parcelas:** lista partido × UF × cargo (painel balanceado; sem peso); candidaturas, receita total, transferências do partido, recursos públicos, gasto e votos, para 3 grupos; erros agrupados por lista, com a alternativa por UF.
- **Cadeiras:** disputa.
- **Taxas:** disputa UF × cargo, com Y = taxa do grupo − taxa do grupo de comparação; competitiva pelo voto, competitiva pelo gasto e eleita, para 3 grupos; erros agrupados por UF.

## Inferência por randomização

- **Hipótese nula:** a EC 111 não teve efeito em nenhuma unidade. Sob ela, os rótulos federal e estadual são intercambiáveis dentro de cada UF.
- **Procedimento:**
  - em cada réplica, sortear para cada UF se os rótulos federal e estadual são trocados (troca de sinal);
  - reestimar δ (e $\delta_{2022}$, $\delta_{2026}$);
  - 10.000 réplicas, semente fixa no topo do script (`set.seed(20261117)`);
  - p-valor = proporção de réplicas com |δ| ≥ |δ observado|.
- **Onde se aplica:**
  - **taxas:** a troca inverte o sinal do contraste da disputa;
  - **parcelas:** troca os rótulos de todas as listas da UF de uma vez, e δ é reestimado pela regressão.
- **Limite, declarado no texto:** a randomização corrige o problema de poucas UFs, mas não protege contra um choque nacional do cargo federal. Esse choque afetaria todas as UFs no mesmo sentido e também apareceria como efeito.
- **Bootstrap selvagem:** sai do plano. A randomização responde ao mesmo problema e é a alternativa indicada por Cunningham para poucos grupos.

## Arquivos

1. **Script novo** `explorations/ec111-did-2026/R/08_regressao_did.R`:
   - lê `data/processed/painel_listas_2014_2026.rds` e `painel_disputas_2014_2026.rds`;
   - monta as taxas por disputa a partir de `margem_resultado.rds` (voto) e `margem_gasto_medidas.rds` (gasto), com o código de `05_ddd_margem.R` e `14_ddd_gasto.R`;
   - estima o termo único, o estudo de evento e a randomização;
   - grava `output/regressao_did.csv`, `output/regressao_did_robustez.csv` e `output/randomizacao_did.csv`;
   - para com erro se o estudo de evento não reproduzir os resultados atuais, ou se δ não for igual à média dos efeitos de 2022 e 2026.
2. **Figura nova**, no `07_figuras_capitulo.R`: dados brutos, com a parcela média de cada grupo por cargo, 2014–2026 (2018–2026 nos recursos), a partir de `niveis_por_cargo.csv`. Seis painéis, um por desfecho de parcela, com federal e estadual em cores diferentes e cada grupo num tom. Entra na abertura dos Resultados, antes do resumo do funil.
3. **Capítulo:**
   - **Metodologia (Estimação):** as duas equações de regressão no lugar de `eq-att` e `eq-reg`; CS como estimador equivalente; uma frase sobre por que 2014 é pré-teste e não parte do "antes"; um parágrafo de falsificações; um parágrafo de inferência (erros agrupados + randomização, com o limite).
   - **Tabelas:**
     - nas duas tabelas do funil, uma coluna "Federal × Pós" com δ e IC;
     - na tripla diferença principal, a coluna "Média" vira "Federal × Pós". O número é o mesmo, porque δ é igual à média dos efeitos de 2022 e 2026; muda o nome e a origem;
     - nas taxas, mais uma coluna com o p-valor por randomização.
     - Nenhum número por ano muda.
   - **Texto:** onde os resultados citam "em média", citar δ. Nas Limitações, trocar a frase de inferência pelo resultado da randomização, com o limite.
   - **Comentário de pendências:** marcar como resolvidos a regressão de DiD tradicional e o MC3.

## Verificação

- O script roda do início ao fim, com as conferências de 1e-6 passando.
- **Diff de números no `.qmd`:** nenhum número por ano muda. Os números novos (δ, IC, p-valores por randomização, níveis da figura) são listados no commit.
- `quarto render` sem avisos; `quality_score.py` ≥ 90; leitura da figura nova.
- **Citações:** Cunningham (2021) e a referência da randomização (p. ex., Buchmueller, DiNardo & Valletta 2011, citada por ele) entram no `.bib` só depois de conferidas. Antes, checar se já estão no arquivo.

## Fora do escopo

Efeitos fixos de UF × ano e covariáveis; regressão por candidatura individual; HonestDiD do funil e de mulheres negras.
