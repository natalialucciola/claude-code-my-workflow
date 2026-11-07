# Plano — DiD da EC 111/2021 na geografia do voto (QL por município), a partir de Calzavara

**Status:** APPROVED (2026-10-14) → **IN PROGRESS** · revisado em 2026-11-07
**Branch:** `worktree-did-ec111-ql-municipio` — **sem merge na main** até ordem da autora. Commits: `f266f95` (plano), `47ab999` (código + resultados principais). Sem push.
**Base da branch:** `worktree-ql-voto-2026`, **ainda não incorporada à main** (3 commits à frente). Um merge desta branch leva junto os commits do ql-voto-2026.
**Exploração:** `explorations/ec111-did-ql-municipio/` (log em `SESSION_LOG.md`)
**Antecessores:** `2026-10-13_did-ec111-2026.md` (DiD no nível da lista) · `2026-10-13_ql-voto-2026-cap6.md` (QL do voto 2018–2026)
**Fonte:** Calzavara, Luana Maria de Matos. *Fragmentação de dentro para fora: estratégias políticas e dinâmica do sistema partidário brasileiro.* Tese (Doutorado em Ciência Política) — IESP-UERJ, 2025. Orientador: Fernando Guarnieri. Cap. 3 "Fragmentação na arena eleitoral". PDF em `master_supporting_docs/supporting_papers/` do checkout principal (não está no worktree).

### Histórico de revisões

| Data | Mudança |
|---|---|
| 2026-10-14 | Rascunho; a autora decide o resultado principal (decomposição da entrada em território novo) e aprova as demais recomendações (branch a partir do ql-voto-2026; município principal, RGI na robustez; Calzavara como referência de mensuração) |
| 2026-10-14 | Implementação dos scripts 00–05; 00–03 executados; 04 interrompido por falta de memória; 05 não executado |
| 2026-11-07 | Revisão: plano alinhado ao que foi feito; desvios registrados (§3, §4, §6, §7); revisão crítica e decisões em aberto (§9–§10) |

---

## 1. O que a tese de Calzavara faz (e o que não faz)

**Não há diferenças em diferenças na tese.** O desenho geográfico do Cap. 3 é:

| Elemento | Calzavara (Cap. 3) |
|---|---|
| Pergunta | A filiação de deputados migrantes expande o partido para territórios novos? |
| Unidade geográfica | Região Geográfica Imediata (RGI, IBGE 2017; 510 regiões). Ela descarta o município por ser "detalhista demais" para medir sobreposição (p. 96–97, citando Silva & Davidian 2013; Avelino, Biderman & Silva 2016) |
| Medida de base | QL do candidato na RGI = (votos do candidato na RGI ÷ votos totais do candidato) ÷ (eleitorado da RGI ÷ eleitorado da UF); base = QL > 1. Testa limiares 2 e 3 (p. 100–102) |
| Painel | partido × RGI × eleição, Dep. Federal, 1998–2022 |
| 3.3 Sobreposição | "Conflito entre bases": o migrante entra num partido que já tem eleito com QL > 1 na mesma RGI? → 10,9% dos casos (Tab. 1) |
| 3.3.1 Expansão | Transição entre eleições consecutivas na RGI (o partido passa a ter, mantém ou perde candidato com QL > 1), com e sem migrante: crescimento de 29% → 62,9% (Tab. 2). **É a comparação mais próxima de um DiD**, mas descritiva |
| 3.4 Votação | VD = % de votos do partido na RGI; tratamento = presença de migrante; modelo de efeitos mistos; efeito ≈ +10 p.p. (Gráf. 20). O resumo fala em "efeitos fixos" e o texto em "efeitos mistos" |
| 3.5 Fragmentação | Regressão linear simples: % dos votos do partido vindos de RGIs de migrantes → votação total |

**O que aproveitamos:** o painel partido × território × eleição; a presença de base (QL > 1) como resultado; a transição entre eleições (Tab. 2). **O que não copiamos:** a identificação. O modelo de efeitos mistos não separa seleção de efeito; aqui esse papel é do DiD Federal × Estadual. Diferença de medida: o denominador do QL dela é o **eleitorado**; o nosso é o **voto nominal do cargo** (mesma regra do ql-voto-2026).

## 2. Pergunta (DECIDIDA 2026-10-14)

**A EC 111/2021 fez os partidos avançarem sobre territórios novos, e esse avanço ocorreu por candidaturas de mulheres ou de pessoas negras?**

A EC 111 conta em dobro os votos em mulheres e em pessoas negras na distribuição do FEFC/FP, só para a Câmara dos Deputados, de 2022 a 2030. Perguntas secundárias:

- **Nível de presença:** os partidos passaram a ter base de g em mais municípios (`base_g`, que mistura território antigo e novo)?
- **Sobreposição (ponte com o Cap. 6):** as bases de g aparecem em municípios "livres" ou sobrepostas à base de um incumbente do partido?
- **Fatia do voto:** subiu a parcela do voto do partido no município que vai para g? (variável construída; **não estimada ainda** — ver §4.2)

## 3. Desenho

- **Unidade:** partido × município × cargo × ano. Partido harmonizado para a linhagem de 2026 (`harmonizar_partido_2026()` em `R/funcoes.R`, estendida às siglas de 2010/2014; PHS = NA, como nas análises irmãs).
- **Tratado:** Deputado Federal a partir de 2022 (`gname = 2022`). **Controle:** Deputado Estadual, mesmo partido e mesmo município, nunca tratado (`gname = 0`). DF fora.
- **Períodos:** 2014 e 2018 (pré) · 2022 e 2026 (pós). **2010 entra só como t−1 da transição de 2014.** Com `gname = 2022`, 2014 é e = −8 e 2018 (e = −4) é a referência.
- **Universo (painel balanceado):** listas partido × UF presentes **nos dois cargos nas cinco eleições 2010–2026** × municípios com voto nos dois cargos em todas as eleições. Resultado: **20 partidos, 297 listas por cargo, 74.549 pares partido × município por cargo.** **Desvio importante:** exigir 2010 tira do painel PSD, Solidariedade, Novo, Rede e outros criados depois de 2010 → ver §9, item 1.
- **Estimadores (implementados em `R/03_did.R`):**
  - Principal: `did::att_gt(control_group = "nevertreated", base_period = "universal", panel = TRUE, clustervars = "lista_id", bstrap = TRUE, cband = TRUE, biters = 1000)`, com `aggte(type = "dynamic")` e `aggte(type = "group")`. `est_method = "reg"`: sem covariáveis, é idêntico ao `"dr"`, que é o padrão da regra `did-conventions.md`. 25.000 iterações na versão final (`EC111_BITERS`).
  - TWFE `id + ano`: coincide com o `att_gt` (diferença máx. **9 × 10⁻¹²**, checado no código).
  - TWFE `id + partido×município×ano`: absorve choques locais comuns aos dois cargos; especificação mais exigente.
- **Pesos:** não ponderado e ponderado pelos votos do partido no município em 2018 (implementado para os resultados principais).
- **Inferência da parcela de g:** regressão empilhada (g e total no mesmo modelo, efeitos fixos por resultado, cluster na lista) + método delta. **Desvio:** o plano previa as funções de influência do `did`, mas o pacote guarda as unidades numa ordem interna diferente da do id, o que desalinha o cluster.

## 4. Resultados (g = mulheres ou pessoas negras)

### 4.1 Resultado principal — entrada em território novo, decomposta por grupo

| Variável | Definição (partido × município × cargo, eleição t) | Status |
|---|---|---|
| `nova_base` | 1 se o partido não tinha base no município em t−1 e tem em t | ✅ estimado |
| `nova_base_g` | `nova_base` = 1 e ≥ 1 das bases novas é de g | ✅ estimado |
| `nova_base_nao_g` | `nova_base` = 1 e nenhuma base nova é de g | ✅ estimado |

- **Identidade:** `nova_base = nova_base_g + nova_base_nao_g` → ATT(total) = ATT(g) + ATT(não g); parcela de g = ATT(g) ÷ ATT(total). A identidade é checada no código.
- **Base** = QL > 1 e fatia ≥ 0,025 dos votos do candidato (regra calibrada no ql-voto-2026).
- **Sem condicionar ao conjunto em risco** (a base de 2022 é pós-tratamento). A versão condicional, prevista como robustez só para 2022, **não foi implementada**.
- **Benchmark mecânico** (nível da lista, TWFE): nº de candidaturas de g, nº de bases novas de g e bases novas de g por candidatura de g. ✅ estimado.
- **Bases fracas:** a variante "só candidaturas competitivas" está em `04_robustez.R`, ainda **não executada**. A variante "mínimo absoluto de votos no município" **não foi implementada**.

**Resultados preliminares** (painel balanceado, p.p.; `output/resultados_did.csv`, `parcela_g.csv`, `benchmark_listas.csv`):

| | 2014 (pré) | 2022 | 2026 | Média 2022–26 |
|---|---|---|---|---|
| Total (`nova_base`; média federal 2018 ≈ 6,3%) | −0,67 (0,60) | 1,15 (0,69) | 1,24 (0,70) | 1,19 [−0,02; 2,41] |
| Mulheres | −0,27 (0,28) | 0,57 (0,34) | 0,28 (0,26) | 0,42 [−0,11; 0,95] |
| Pessoas negras | −0,18 (0,34) | 0,46 (0,44) | 0,44 (0,37) | 0,45 [−0,26; 1,15] |
| Parcela de mulheres (2018: 33%) | | 49% | 22% | 35% [11%; 59%] |
| Parcela de pessoas negras (2018: 39%) | | 40% | 36% | 38% [3%; 72%] |

Com efeitos fixos partido × município × ano, o total de 2022 e de 2026 e a entrada por mulheres em 2022 ficam significativos a 5%. Benchmark: as candidaturas de g crescem (+1,1 a +3,7 por lista), mas as bases novas **por candidatura** de g não.

### 4.2 Resultados secundários

| Variável | Status |
|---|---|
| `base_g` (nível) | ✅ estimado (att_gt) |
| `base_g_livre` / `base_g_sobrep` (soma = `base_g`) | ✅ estimado (att_gt) |
| `voto_g_terr` (% do voto do partido no município obtido por g) | ⚠️ construído no painel, **não estimado** (é NA onde o partido não teve voto; precisa de subamostra balanceada) |
| `n_base_g` / `sh_base_g` | ❌ não implementado — proposta: **retirar** (redundantes com a decomposição) |

- **Heterogeneidade — DESVIO.** A heterogeneidade extensiva × intensiva por "o partido tinha base no município em 2018" foi **descartada**. 2018 é o período de referência, e o subgrupo fica mecanicamente ligado ao resultado: reversão à média, com pré-testes de −3,9 e +9,3 p.p. A versão do plano ("sem/com base **de g** em 2018") tem o mesmo defeito. **Substituída por tercis de porte do município** (votos para federal em 2010), que testam a crítica da Calzavara ao município: o avanço se concentra onde formar base é "barato"? Código pronto em `03_did.R`, **não executado**.

## 5. Robustez e diagnóstico (`R/04_robustez.R` — escrito, execução interrompida)

| Item | Status |
|---|---|
| RGI (unidade de Calzavara) | código pronto, não executado |
| `fatia_min` 0 e 0,05; QL > 2 e > 3 | código pronto, não executado |
| Só candidaturas competitivas | código pronto, não executado |
| Painel desbalanceado (traz PSD, Solidariedade, Novo…) | código pronto, não executado |
| HonestDiD, magnitudes relativas (M̄ ∈ {0; 0,5; 1; 1,5; 2}) | código pronto, não executado |
| Pré-teste 2014 → 2018 | ✅ no att_gt (o teste de Wald do `did` não sai com cluster acima da unidade; usar as bandas do bootstrap) |
| `didFF` (sensibilidade à forma funcional) | ❌ não implementado — ver §9, item 6 |
| "Placebo de cargo" (excluir zeros estruturais) | ❌ não implementado — ver §9, item 7 |

O `04` foi morto pelo sistema por falta de memória (máquina com 7,8 GB; ~2,5 GB livres). O script já foi enxugado: carrega só as colunas necessárias e libera memória entre as variantes.

## 6. Dados

| Ano | Fonte | Situação |
|---|---|---|
| 2010 | TSE: `votacao_candidato_munzona`, `votacao_partido_munzona`, `consulta_cand`, `consulta_vagas` | ✅ baixado (`00_dados.R`) |
| 2014 | TSE (mesmos arquivos) + candidaturas da autora (gênero, raça, CPF) | ✅ QL em `01_ql_2010_2014.R`. **Desvio:** usado o zip do TSE, não `votos_mun_2014_df.rds` |
| 2018, 2022, 2026 | `ql_voto_*` do ql-voto-2026 | ✅ |
| RGI | API de localidades do IBGE (5.571 municípios, 510 RGIs) | ✅ |

- Em 2010/2014 só existe `QT_VOTOS_NOMINAIS` → restrito a candidaturas APTO (os votos das inaptas vêm zerados). Vagas: `QT_VAGAS` (2010) × `QT_VAGA` (2014). Eleito em 2010 inclui a situação "MÉDIA".
- Raça: não existe em 2010; em 2014 faltam 2 (federal) e 8 (estadual) candidaturas.
- `data/raw` do worktree = hard links para o checkout principal. Saídas `.rds` e logs ignorados no `.gitignore`.

## 7. Arquivos (`explorations/ec111-did-ql-municipio/R/`)

| Script | Faz | Executado |
|---|---|---|
| `00_dados.R` | downloads TSE 2010/2014 e RGI do IBGE | ✅ |
| `01_ql_2010_2014.R` | QL de 2010/2014 + validação da regra contra a base da autora | ✅ |
| `funcoes.R` | harmonização, incumbência, agregação por território, `montar_painel()` | — |
| `02_painel.R` | painel principal + painel de listas | ✅ |
| `03_did.R` | att_gt, parcela de g, TWFE, heterogeneidade por porte, benchmark | ✅ (exceto a heterogeneidade por porte) |
| `04_robustez.R` | variantes + HonestDiD | ❌ interrompido |
| `05_figuras_tabelas.R` | 4 figuras + tabela principal | ❌ |

## 8. Verificação

| Checagem | Status |
|---|---|
| Regra de eleito/competitivo em 2014 = base da autora | ✅ 513/1035 eleitos; 100% de concordância |
| QL municipal recalculado = `QL_voto` do ql-voto-2026 | ✅ diferença máx. 0 |
| Painel sem duplicatas; decomposição fecha | ✅ `stopifnot` |
| att_gt = TWFE simples | ✅ 9 × 10⁻¹² |
| Regressão empilhada = att_gt | ✅ `stopifnot` |
| Coerência com o DiD de listas (`voto_g`) | ❌ pendente |
| `/review-r` nos scripts; `quality_score.py` (exploração ≥ 60; graduação ≥ 80) | ❌ pendente |
| `README.md` da exploração (exigido pelo protocolo de explorações) | ❌ pendente |
| Figuras renderizadas e inspecionadas | ❌ pendente |

## 9. Revisão crítica (2026-11-07)

Em ordem de importância para as conclusões:

1. **O painel balanceado perde partidos centrais.** Exigir 2010–2026 tira PSD, Solidariedade, Novo, Rede e outros criados depois de 2010. O PSD, sozinho, é um dos maiores partidos da Câmara. O efeito estimado vale para os 20 partidos "antigos". A alternativa é tornar principal o painel balanceado em **2014–2026** e usar 2010 só para a transição de 2014 quando o partido existia. Isso desbalanceia apenas o pré-teste e mantém o PSD. → decisão da autora (§10).
2. **A pré-tendência pesa.** O coeficiente de 2014 é negativo em todos os resultados: −0,67 no total, mais da metade do efeito de 2022. Não é significativo, mas indica que o Federal já ganhava território em relação ao Estadual entre 2014 e 2018. Extrapolado linearmente, o efeito de 2022 cai para cerca de 0,5 p.p. (1,15 − 0,67) e o de 2026 desaparece (1,24 − 2 × 0,67 ≈ −0,1). Proposta: além das magnitudes relativas, rodar a restrição de **suavidade** do HonestDiD (ΔSD, M = 0 = tendência linear), que é a que responde a essa preocupação. Com um só pré-período, a conclusão vai ser frágil e o texto precisa dizer isso.
3. **A parcela de g é instável quando o total é marginal.** O denominador ATT(total) tem IC que encosta no zero (média [−0,02; 2,41]; 2022 e 2026 isolados incluem zero), e nesse caso o método delta para uma razão não é confiável. Proposta: o resultado principal passa a ser a **decomposição em níveis** (ATT(g) e ATT(não g) lado a lado). A parcela fica como leitura auxiliar, com IC de Fieller ou bootstrap por cluster, e só é reportada nas especificações em que o total é distinguível de zero.
4. **O benchmark por candidatura tem pré-tendência própria.** `nova_por_cand_*` em 2014 é positivo e significativo (mulheres 0,37, EP 0,16; negras 0,29, EP 0,13). A conclusão "a capacidade por candidatura não subiu" é, portanto, menos limpa do que parece. Reportar com essa ressalva.
5. **Identificação: choques específicos do cargo federal.** A cláusula de desempenho (2% → 2,5%, medida em votos para federal) e as federações mudam incentivos só ou principalmente no federal, e em 2026 se somam à EC 111. Os efeitos fixos partido × município × ano não absorvem choques por cargo. O ATT de 2026 é "EC 111 + cláusula", e isso precisa estar no texto.
6. **`didFF`:** a regra `did-conventions.md` pede a sensibilidade à forma funcional. Os resultados são binários (probabilidades em p.p.), e para eles a questão níveis × log não se coloca do mesmo modo. Proposta: documentar a justificativa em vez de rodar, ou rodar só em `voto_g_terr`, que é contínua.
7. **"Placebo de cargo" do plano original:** a formulação era ambígua. Proposta: substituir por uma **amostra restrita às listas com ≥ 1 candidatura de g em todas as eleições**, que elimina zeros estruturais de partidos que nunca lançaram g na UF.
8. **Execução sob memória limitada.** O `04` precisa rodar sozinho, sem outros processos R. Se morrer de novo, a próxima opção é rodar cada variante numa sessão R separada (variável de ambiente por variante).
9. **Dependência da branch ql-voto-2026.** Se ela mudar antes do merge, esta branch precisa de rebase, e o QL de 2018–2026 deve ser recalculado e conferido.
10. **Calzavara no `.bib`:** os dados completos estão no cabeçalho deste plano. Falta criar a entrada no `Bibliography_base.bib`.

## 10. Decisões em aberto (para a autora)

1. **Painel principal:** manter o balanceado 2010–2026 (20 partidos, pré-teste completo) ou passar para o balanceado 2014–2026 (com PSD, Solidariedade, Novo; pré-teste só para os partidos que existiam em 2010)? *Recomendação:* 2014–2026 como principal; 2010–2026 como robustez.
2. **Destaque do resultado:** decomposição em níveis como principal, com a parcela como leitura auxiliar (§9, item 3)? *Recomendação:* sim.
3. **Itens a retirar do escopo:** `n_base_g`/`sh_base_g`, a versão condicional ao conjunto em risco e o `didFF` nos resultados binários? *Recomendação:* retirar os três, documentando o motivo.

## 11. Próximos passos (após as decisões)

1. Ajustar `montar_painel()` se o painel principal mudar (§10, item 1) e refazer `02` e `03`.
2. Rodar `04_robustez.R` sozinho; acrescentar ΔSD ao HonestDiD e a amostra "listas com g em todos os anos".
3. Rodar a heterogeneidade por porte (`03`, com `EC111_REUSAR=1`).
4. Estimar `voto_g_terr` na subamostra balanceada.
5. Rodar `05_figuras_tabelas.R`, inspecionar as figuras, escrever o `README.md` da exploração.
6. Conferir a coerência com o DiD de listas; `/review-r`; `quality_score.py`.
7. Versão final com `EC111_BITERS=25000`.
