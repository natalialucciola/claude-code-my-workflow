# Plano — EC 111 e a competitividade das candidaturas femininas e negras pela margem de votos (2014–2026)

**Status:** DRAFT (aguardando aprovação) · **Data:** 2026-10-13
**Exploração:** `explorations/competitividade-eleitoral/` · **Relacionado:** `explorations/competitividade-gasto/`

## Pergunta

A EC 111/2021 (art. 2º: votos em mulheres e pessoas negras para a Câmara contam em dobro na
divisão do Fundo Partidário e do FEFC, de 2022 a 2030) aproximou essas candidaturas do limiar de
eleição (H_a)? Ou aumentou seus votos longe dele (H_b, colheita de votos)? O incentivo premia
votos, não cadeiras; H_b é a previsão do mecanismo do Cap. 6.

## Decisões já tomadas (autora, 2026-10-13)

- **Medida principal:** margem de votos ÷ QE do distrito (cargo × UF × ano). LSS (÷ eleitorado)
  e ABD (÷ (V_i + V_L)) entram como robustez.
- **Desenho principal:** tripla diferença no nível da candidatura (mulher × Federal × pós). O
  painel de listas partido × UF × cargo entra como complemento.
- **Incluir 2026.**

## Desenho com 2026

Quatro eleições: **2014 e 2018 (antes)**, **2022 e 2026 (depois; a EC vale até 2030)**.
Referência: 2018. Estudo de evento em tripla diferença:

$$Y_i = \sum_{t \neq 2018} \beta_t\,(\text{Mulher}_i \times \text{Federal}_i \times \mathbb{1}[\text{ano}=t])
+ \text{EF}(\text{UF}\times\text{cargo}\times\text{ano}) + \text{EF}(\text{Mulher}\times\text{cargo})
+ \text{EF}(\text{Mulher}\times\text{ano}) + \varepsilon_i$$

- β_2014 é o placebo (deve ser ≈ 0); β_2022 é o efeito na 1ª eleição sob a EC; β_2026, na 2ª.
- **Por que 2026 ajuda:** testa se o efeito persiste ou cresce. Os partidos aprendem a usar a
  regra, e as eleitas em 2022 concorrem como incumbentes em 2026. Robustez: excluir incumbentes,
  para separar o canal de incumbência.
- **Desfechos** (cada um em bandas h ∈ {0,1; 0,25; 0,5} do QE): (i) eleita ou a menos de h do
  limiar; (ii) quase eleita, margem/QE ∈ [−h, 0); (iii) a margem/QE, para ver a distribuição.
  Ler as bandas juntas diz *onde* a EC mexeu (H_a × H_b).
- **Grupos:** mulheres, pessoas negras e mulheres negras (o voto delas conta em dobro uma vez só).
- **Inferência:** erros agrupados por UF (27), *wild cluster bootstrap*.
- **Painel de listas:** número e proporção de mulheres competitivas por lista, EF de lista e de
  ano, mesmo estudo de evento.

### Ameaças específicas, com o que fazer

| Ameaça | Por que importa | Tratamento |
| --- | --- | --- |
| Mudança de regras: coligações (2014/18), federações (2022/26), sobras abertas (2018), 80/20% do QE (2022), 3ª fase aberta a todos os partidos (ADIs 7228/7263/7325, a partir de 2024) | Mudam a margem de todos | Valem nos dois cargos, então a tripla diferença elimina o nível comum. A interação com a magnitude (pesa mais no Federal) fica como robustez: controle de magnitude, excluir UFs pequenas |
| Outras políticas de financiamento entre 2022 e 2026 (EC 117/2022 para mulheres; EC 133/2024 para pessoas negras — **a confirmar texto e vigência**) | Podem mudar recursos dos dois cargos | Valem para Federal e Estadual; documentar e checar se há componente específico de cargo |
| Composição (mais candidatas, inclusive de fachada) | A proporção de competitivas pode cair com o número subindo | Reportar número e proporção; separar entrada × intensidade |
| Identidade de listas e partidos (fusões, federações) | O painel de listas precisa ser estável | `partido_harm`; a margem é calculada na lista que disputa cadeiras |
| Medida *ex post* | Mede onde a candidata terminou, não sua viabilidade prévia | Cruzar com as medidas de gasto (*ex ante*) |

## Dados — inventário (conferido em 2026-10-13)

| Ano | Votos por candidato + lista + situação | Votos de legenda | Eleitorado | Gênero/raça |
| --- | --- | --- | --- | --- |
| 2014 | Lab `dados/brutos/votacao_candidato_munzona_2014.zip` | Lab `votacao_partido_munzona_2014.zip` (raiz) | Lab `perfil_eleitorado_2014.zip` | `data/raw/candidatos_*2014.rds` |
| 2018 | idem `_2018` | Lab `votacao_partido_munzona_2018.zip` (raiz) | idem `_2018` | `data/raw/candidatos_*2018.rds` |
| 2022 | idem `_2022` | Lab `dados/brutos/votacao_partido_munzona_2022.zip` | idem `_2022` | `data/raw/candidatos_*2022.rds` |
| 2026 | **FALTA** `votacao_candidato_munzona_2026` | Downloads `votacao_partido_munzona_2026.zip` (gerado em 13/10/2026) | Downloads `perfil_eleitorado_2026.zip` | Downloads `consulta_cand_2026.zip` (24/09: tem gênero/raça e federação, mas a situação ainda é `#NULO`) |

Lab = `Desktop/Lab Eleições - Geografia Eleitoral/`. Cópias dos arquivos de 2026 (todos de
24/09/2026) também em `OneDrive FINEP/Tese/Dados_TSE/2026/`, que tem ainda
`prestacao_de_contas_eleitorais_candidatos_2026.zip`, provavelmente a prestação **parcial**, de
antes da eleição, a conferir. Também em Downloads: `consulta_vagas_2026`
(cadeiras), `consulta_coligacao_2026` (federações), `extrato_bancario_candidato_2026`.
Os arquivos de votação por candidato trazem `SQ_COLIGACAO`, federação e `DS_SIT_TOT_TURNO`, o
que dispensa o `consulta_cand` para a composição das listas e para os eleitos.

**Pendências de dados:**
1. `votacao_candidato_munzona_2026.zip`, dados abertos do TSE (posso baixar, se autorizado).
2. Prestação de contas de 2026: o prazo da final é 30 dias após a eleição, por volta de
   03/11/2026, e o TSE publica depois. **A medida em dinheiro de 2026 fica para depois.**

Migração (INV-10): copiar/extrair para `data/raw/` (gitignored), só Deputado Federal e Estadual,
em `.rds`; nunca ler por caminho absoluto.

## Medida em dinheiro: "quanto dinheiro faltou"?

**É viável, mas com uma diferença de natureza.** A margem em votos é *contábil*: refazendo a
distribuição, sabe-se exatamente quantos votos mudariam o resultado. Já "quanto dinheiro faltou"
exige um **preço do voto**, isto é, quantos votos um real a mais compra. Isso não se observa; é
uma suposição ou uma estimativa. Proponho três versões, da mais transparente à mais modelada:

- **D1 — preço médio observado (referência transparente).**
  Δ$_i = margem_votos_i × c, onde c = gasto ÷ votos dos eleitos marginais da mesma lista (ou do
  distrito). É "quanto custaria aos preços pagos por quem se elegeu por pouco". Subestima o custo
  se os retornos forem decrescentes.
- **D2 — elasticidade voto–gasto (principal).**
  Com log V = a + ε·log G, o gasto que fecharia a margem é G\*_i = G_i·((V_i + Δ_i)/V_i)^{1/ε};
  daí Δ$_i = G\*_i − G_i. ε é estimado por gênero × cargo × ano (× incumbência), com faixa de
  sensibilidade a partir da literatura (Speck & Mancuso 2014: retorno maior para desafiantes
  mulheres). Para candidaturas com poucos votos, Δ$ explode, e isso é informativo: dinheiro
  sozinho não as elegeria.
  **Ressalva central:** ε observacional é endógeno (quem é forte arrecada mais), então tende a
  superestimar o retorno e subestimar o dinheiro faltante. Reportar como conversão sob
  suposição explícita, não como efeito causal.
- **D3 — distância de gasto ao limiar (sem votos, *ex ante*).**
  Gasto da candidata ÷ gasto do eleito marginal da lista ou do menor gasto entre os eleitos do
  distrito. É a mesma família de `razao_min`/`razao_p10` da exploração de gasto, agora ancorada
  no eleito marginal da lista, como a margem de ABD.

**Uso no desenho:** Δ$ (D1/D2) e D3 entram como desfechos da mesma tripla diferença para 2014–
2022, e para 2026 quando a prestação final sair. Pergunta: a EC reduziu o dinheiro que faltava
às mulheres? Dá para cruzar com o achado de que os recursos subiram sem mais mulheres viáveis.

## Etapas

1. **Dados** — scripts `01_importar_votacao.R` e `02_eleitorado_vagas.R`: base candidato × lista
   × cargo × UF × ano, com votos nominais, votos de legenda da lista, vagas, QE e eleitorado.
2. **Validar a distribuição** — `03_validar_distribuicao.R`: reproduzir 100% dos eleitos do TSE
   em cada UF × cargo × ano. Cada divergência é investigada (votos *sub judice*/anulados, 3ª
   fase, empates) antes de seguir. **Critério de parada:** nenhuma margem é calculada sem 100%
   de acerto.
3. **Margens** — `04_margens.R`: margem por busca para todas as candidaturas, normalizações
   ÷ QE, LSS e ABD. Otimizar a alocação (pré-ordenação, paralelizar por UF), já que são cerca de
   110 mil candidaturas. Validar contra a `rv` de ABD (2014, Federal) por
   `uf + nome + numero_partido`.
4. **Descritivo** — `05_descritivo_margens.R`: distribuição da margem/QE por gênero, raça,
   cargo e ano; figuras no padrão de publicação da tese.
5. **Estimação** — `06_ddd_margem.R`: estudo de evento em tripla diferença, painel de listas,
   placebo de 2014, *wild bootstrap*, robustez (LSS/ABD, bandas, excluir incumbentes,
   magnitude).
6. **Dinheiro** — `07_margem_dinheiro.R`: D1, D2 e D3 para 2014–2022; 2026 quando houver a
   prestação final.
7. **Registro** — atualizar o README e o SESSION_LOG; nota de resultados para decidir o capítulo
   de destino (Cap. 4/5 ou uma seção do Cap. 6).

## Verificação

- Testes do protótipo (`scripts/testar_exemplos_artigos.R`) seguem passando.
- 100% dos eleitos reproduzidos por UF × cargo × ano (tabela de validação em `output/`).
- Concordância com a `rv` de ABD em 2014 reportada (correlação, proporção idêntica ao centésimo).
- Placebo de 2014 reportado ao lado dos efeitos de 2022 e 2026.
- `Rscript` de cada script roda do zero; sem caminhos absolutos; quality score ≥ 80 para graduar.
