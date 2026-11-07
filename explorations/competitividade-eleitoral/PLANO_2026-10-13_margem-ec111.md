# Plano — EC 111 e a competitividade das candidaturas femininas e negras pela margem de votos (2014–2026)

**Status:** APPROVED (2026-10-13; retificado: só votação, sem a dimensão de gasto)
**Exploração:** `explorations/competitividade-eleitoral/`

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
- **Só votação:** a dimensão de gasto/dinheiro fica fora deste plano.

## Desenho

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
| Outras políticas entre 2022 e 2026 (EC 117/2022 para mulheres; EC 133/2024 para pessoas negras — **a confirmar texto e vigência**) | Podem mudar a competição nos dois cargos | Valem para Federal e Estadual; documentar e checar se há componente específico de cargo |
| Composição (mais candidatas, inclusive de fachada) | A proporção de competitivas pode cair com o número subindo | Reportar número e proporção; separar entrada × intensidade |
| Identidade de listas e partidos (fusões, federações) | O painel de listas precisa ser estável | `partido_harm`; a margem é calculada na lista que disputa cadeiras |
| Medida *ex post* | Mede onde a candidata terminou, não sua viabilidade prévia | Interpretar sempre como proximidade do limiar no resultado |

## Dados — inventário (conferido em 2026-10-13)

| Ano | Votos por candidato + lista + situação | Votos de legenda | Eleitorado | Gênero/raça |
| --- | --- | --- | --- | --- |
| 2014 | Lab `dados/brutos/votacao_candidato_munzona_2014.zip` | Lab `votacao_partido_munzona_2014.zip` (raiz) | Lab `perfil_eleitorado_2014.zip` | `data/raw/candidatos_*2014.rds` |
| 2018 | idem `_2018` | Lab `votacao_partido_munzona_2018.zip` (raiz) | idem `_2018` | `data/raw/candidatos_*2018.rds` |
| 2022 | idem `_2022` | Lab `dados/brutos/votacao_partido_munzona_2022.zip` | idem `_2022` | `data/raw/candidatos_*2022.rds` |
| 2026 | `votacao_candidato_munzona_2026` (baixar do TSE) | Downloads `votacao_partido_munzona_2026.zip` (gerado em 13/10/2026) | Downloads `perfil_eleitorado_2026.zip` | Downloads `consulta_cand_2026.zip` (24/09: tem gênero/raça e federação; a situação vem do arquivo de votação) |

Lab = `Desktop/Lab Eleições - Geografia Eleitoral/`. Cópias dos arquivos de 2026 também em
`OneDrive FINEP/Tese/Dados_TSE/2026/`. Os arquivos de votação por candidato trazem
`SQ_COLIGACAO`, federação e `DS_SIT_TOT_TURNO`, o que dispensa o `consulta_cand` para a
composição das listas e para os eleitos.

Migração (INV-10): copiar os zips para `data/raw/tse/` (gitignored) e extrair só Deputado
Federal e Estadual para `.rds`; os scripts nunca leem por caminho absoluto.

## Etapas

1. **Dados** — `01_importar_votacao.R`: base candidato × lista × cargo × UF × ano, com votos
   nominais, votos de legenda da lista, vagas, QE, eleitorado, gênero e raça.
2. **Validar a distribuição** — `02_validar_distribuicao.R`: reproduzir 100% dos eleitos do TSE
   em cada UF × cargo × ano. Cada divergência é investigada (votos *sub judice*/anulados, 3ª
   fase, empates) antes de seguir. **Critério de parada:** nenhuma margem é calculada sem 100%
   de acerto.
3. **Margens** — `03_margens.R`: margem por busca para todas as candidaturas, normalizações
   ÷ QE, LSS e ABD. Otimizar a alocação, já que são cerca de 110 mil candidaturas. Validar contra
   a `rv` de ABD (2014, Federal) por `uf + nome + numero_partido`.
4. **Descritivo** — `04_descritivo_margens.R`: distribuição da margem/QE por gênero, raça,
   cargo e ano; figuras no padrão de publicação da tese.
5. **Estimação** — `05_ddd_margem.R`: estudo de evento em tripla diferença, painel de listas,
   placebo de 2014, *wild bootstrap*, robustez (LSS/ABD, bandas, excluir incumbentes,
   magnitude).
6. **Registro** — atualizar o README e o SESSION_LOG; nota de resultados para decidir o capítulo
   de destino.

## Verificação

- Testes do protótipo (`scripts/testar_exemplos_artigos.R`) seguem passando.
- 100% dos eleitos reproduzidos por UF × cargo × ano (tabela de validação em `output/`).
- Concordância com a `rv` de ABD em 2014 reportada (correlação, proporção idêntica ao centésimo).
- Placebo de 2014 reportado ao lado dos efeitos de 2022 e 2026.
- `Rscript` de cada script roda do zero; sem caminhos absolutos; quality score ≥ 80 para graduar.
