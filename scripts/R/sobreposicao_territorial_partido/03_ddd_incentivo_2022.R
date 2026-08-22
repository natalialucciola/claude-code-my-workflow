# ==============================================================================
# Tripla diferença (DDD): o incentivo financeiro de 2022 (fundo eleitoral
# proporcional a votos de mulheres/negros) reduziu a sobreposição territorial
# especificamente para Deputado Federal, e não para Estadual?
#
# Especificação principal:
#   taxa_sobreposicao ~ Federal * Ano2022 * Mulher(ou Negra) + partido_harm + SG_UF
#   Coeficiente de interesse: Federal:Ano2022:Mulher (a tripla interação)
#
# Unidade: candidato (taxa_sobreposicao pessoal — mesma convenção usada em
# todas as tabelas anteriores desta exploração).
#
# Decisão metodológica (acordada com a usuária): NÃO controlar por incumbência
# ou resultado eleitoral na especificação principal — se o incentivo funciona
# via composição (partidos lançando candidatas mais competitivas/incumbentes),
# controlar por isso enviesaria o efeito total da política para baixo ("bad
# control"). Essas variáveis entram só como decomposição secundária, não como
# controle causal.
#
# Limitação conhecida: só 2 períodos (2018, 2022) — não dá para testar
# tendências paralelas pré-política.
#
# Pré-requisito: rodar R/01_overlap_partido.R (gera taxa_sobreposicao_candidato.rds
# e cand_mun_ql1.rds) e R/02_overlap_extensoes.R antes.
#
# Autor: Natalia Lucciola
#
# Outputs (salvos em out_dir, ver Secao 6):
#   - ddd_modelo_genero.rds                    (objeto feols: modelo principal genero)
#   - ddd_modelo_raca.rds                      (objeto feols: modelo principal raca)
#   - ddd_modelo_genero_resultado.rds          (objeto feols: genero, controle resultado)
#   - ddd_modelo_raca_resultado.rds            (objeto feols: raca, controle resultado)
#   - ddd_modelo_genero_incumbencia.rds        (objeto feols: genero, controle incumbencia)
#   - ddd_modelo_raca_incumbencia.rds          (objeto feols: raca, controle incumbencia)
#   - (cada um dos 6 acima tem um par "_tidy.rds" com broom::tidy(conf.int = TRUE))
#   - incumbencia_completa_candidato.rds       (tabela de incumbencia por candidato)
#   - ddd_genero_especificacoes.tex            (tabela comparativa das 3 especificacoes, genero)
#   - ddd_raca_especificacoes.tex              (tabela comparativa das 3 especificacoes, raca)
#   - (diagnosticos de suporte/cobertura tambem salvos como .rds — ver Secoes 2, 3, 5)
# ==============================================================================

# ==============================================================================
# 0. SETUP
# ==============================================================================

library(tidyverse)
library(fixest)

out_dir <- "explorations/base-territorial-partidos/output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# 1. DATASET PRINCIPAL (nível candidato)
# ==============================================================================

taxa <- readRDS(file.path(out_dir, "taxa_sobreposicao_candidato.rds"))

uf_por_candidato <- readRDS(file.path(out_dir, "cand_mun_ql1.rds")) |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, SG_UF)

ddd_base <- taxa |>
  left_join(uf_por_candidato, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  mutate(
    federal  = as.integer(cargo == "Federal"),
    ano2022  = as.integer(ANO_ELEICAO == "2022"),
    mulher   = as.integer(genero == "FEMININO"),
    negra    = as.integer(raca2 == "NEGRA")
  )

message("N total (candidatos com taxa_sobreposicao definida): ", nrow(ddd_base))

# ==============================================================================
# 2. MODELO PRINCIPAL — GÊNERO
# ==============================================================================

df_genero <- ddd_base |> filter(genero %in% c("FEMININO", "MASCULINO"))

# Tabela de células (n por cargo x ano x mulher) — checagem de suporte; persistida
# em disco (Issue 5) para consulta sem re-rodar o script interativamente.
suporte_celula_genero <- df_genero |>
  summarise(n = n(), .by = c(cargo, ANO_ELEICAO, mulher)) |>
  arrange(cargo, ANO_ELEICAO, mulher)
saveRDS(suporte_celula_genero, file.path(out_dir, "ddd_suporte_celula_genero.rds"))

modelo_genero <- feols(
  taxa_sobreposicao ~ federal * ano2022 * mulher | partido_harm + SG_UF,
  data = df_genero,
  cluster = ~ partido_harm + SG_UF
)
if (length(modelo_genero$collin.var) > 0) {
  warning("modelo_genero: variavel(is) colinear(es) absorvida(s) pelos efeitos fixos: ",
          paste(modelo_genero$collin.var, collapse = ", "))
}

message("Secao 2 — Modelo DDD Genero: N = ", nrow(df_genero),
        " (", sum(df_genero$mulher), " mulheres, ", sum(1 - df_genero$mulher), " homens); ",
        "suporte por celula salvo em ddd_suporte_celula_genero.rds")

# ==============================================================================
# 3. MODELO PRINCIPAL — RAÇA
# ==============================================================================

df_raca <- ddd_base |> filter(raca2 %in% c("BRANCA", "NEGRA"))

# Tabela de células (n por cargo x ano x negra) — checagem de suporte; persistida
# em disco (Issue 5) para consulta sem re-rodar o script interativamente.
suporte_celula_raca <- df_raca |>
  summarise(n = n(), .by = c(cargo, ANO_ELEICAO, negra)) |>
  arrange(cargo, ANO_ELEICAO, negra)
saveRDS(suporte_celula_raca, file.path(out_dir, "ddd_suporte_celula_raca.rds"))

modelo_raca <- feols(
  taxa_sobreposicao ~ federal * ano2022 * negra | partido_harm + SG_UF,
  data = df_raca,
  cluster = ~ partido_harm + SG_UF
)
if (length(modelo_raca$collin.var) > 0) {
  warning("modelo_raca: variavel(is) colinear(es) absorvida(s) pelos efeitos fixos: ",
          paste(modelo_raca$collin.var, collapse = ", "))
}

message("Secao 3 — Modelo DDD Raca: N = ", nrow(df_raca),
        " (", sum(df_raca$negra), " negros, ", sum(1 - df_raca$negra), " brancos); ",
        "suporte por celula salvo em ddd_suporte_celula_raca.rds")

# ==============================================================================
# 4. DECOMPOSIÇÃO SECUNDÁRIA — controlando por resultado eleitoral do ano
#    corrente (disponível nas 4 células; NÃO é a especificação causal principal)
#
#    Bad-control: `resultado` (eleito/competitivo/não-competitivo) é medido no
#    MESMO ano-eleição que o outcome `taxa_sobreposicao` — é um resultado
#    contemporâneo da campanha, não uma característica pré-determinada do
#    candidato. Controlar por ele bloqueia parte do canal causal pelo qual o
#    incentivo de 2022 pode operar (se o incentivo funciona atraindo/elegendo
#    candidatas mais competitivas, condicionar em `resultado` absorve
#    exatamente esse efeito). Por isso essas duas regressões entram só como
#    decomposição secundária/descritiva (mesma lógica de bad control já
#    documentada no cabeçalho para incumbência/resultado na especificação
#    principal), nunca como estimativa causal do efeito da política.
# ==============================================================================

resultado_por_candidato <- readRDS(file.path(out_dir, "cand_mun_ql1.rds")) |>
  mutate(resultado = case_when(
    eleito == 1                    ~ "Eleito",
    competitivo == 1 & eleito == 0 ~ "Competitivo",
    competitivo == 0 & eleito == 0 ~ "Nao_competitivo",
    TRUE ~ NA_character_
  )) |>
  distinct(sq_candidato, cargo, ANO_ELEICAO, resultado)

df_genero_resultado <- df_genero |>
  left_join(resultado_por_candidato, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  filter(!is.na(resultado))

modelo_genero_resultado <- feols(
  taxa_sobreposicao ~ federal * ano2022 * mulher + resultado | partido_harm + SG_UF,
  data = df_genero_resultado,
  cluster = ~ partido_harm + SG_UF
)
if (length(modelo_genero_resultado$collin.var) > 0) {
  warning("modelo_genero_resultado: variavel(is) colinear(es) absorvida(s) pelos efeitos fixos: ",
          paste(modelo_genero_resultado$collin.var, collapse = ", "))
}

df_raca_resultado <- df_raca |>
  left_join(resultado_por_candidato, by = c("sq_candidato", "cargo", "ANO_ELEICAO")) |>
  filter(!is.na(resultado))

modelo_raca_resultado <- feols(
  taxa_sobreposicao ~ federal * ano2022 * negra + resultado | partido_harm + SG_UF,
  data = df_raca_resultado,
  cluster = ~ partido_harm + SG_UF
)
if (length(modelo_raca_resultado$collin.var) > 0) {
  warning("modelo_raca_resultado: variavel(is) colinear(es) absorvida(s) pelos efeitos fixos: ",
          paste(modelo_raca_resultado$collin.var, collapse = ", "))
}

message("Secao 4 — Decomposicao (controle por resultado eleitoral): ",
        "genero N = ", nrow(df_genero_resultado),
        "; raca N = ", nrow(df_raca_resultado))

# ==============================================================================
# 5. DECOMPOSIÇÃO SECUNDÁRIA — incumbência, AGORA NAS 4 CÉLULAS
#    Federal 2014 (candidatos2014.rds + eleitos_2014_df.rds) foi preparado
#    especificamente para fechar esta lacuna — ver
#    explorations/base-territorial-partidos/scripts/08_baixar_candidatos_federal_2014.R.
#    Com isso, dá para rodar a DDD completa (Federal x Estadual) controlando
#    por incumbência, não só um DiD 2x2 dentro do Estadual como na primeira
#    versão desta seção.
# ==============================================================================

cand_est_2018_cpf <- readRDS("data/raw/candidatos_estadual_2018.rds") |> select(sq_candidato, cpfCand)
cand_est_2022_cpf <- readRDS("data/raw/candidatos_estadual_2022.rds") |> select(sq_candidato, cpfCand)
cand_est_2014_cpf <- readRDS("data/raw/candidatos_estadual_2014.rds") |> select(sq_candidato, cpfCand)
cand_fed_2018_cpf <- readRDS("data/raw/candidatos2018.rds")           |> select(sq_candidato, cpfCand)
cand_fed_2022_cpf <- readRDS("data/raw/candidatos2022.rds")           |> select(sq_candidato, cpfCand)
cand_fed_2014_cpf <- readRDS("data/raw/candidatos2014.rds")           |> select(sq_candidato, cpfCand)

eleito_fed_2018 <- readRDS("data/raw/ql_gasto_eleit_2018.rds") |>
  distinct(sq_candidato, eleito) |>
  left_join(cand_fed_2018_cpf, by = "sq_candidato") |>
  filter(eleito == 1) |> distinct(cpfCand) |> pull(cpfCand)

eleito_est_2014 <- readRDS("data/raw/eleitos_e_compet_est_2014_df.rds") |>
  distinct(sq_candidato, eleito) |>
  left_join(cand_est_2014_cpf, by = "sq_candidato") |>
  filter(eleito == 1) |> distinct(cpfCand) |> pull(cpfCand)

eleito_est_2018 <- readRDS("data/raw/eleitos_e_compet_est_2018_df.rds") |>
  distinct(sq_candidato, eleito) |>
  left_join(cand_est_2018_cpf, by = "sq_candidato") |>
  filter(eleito == 1) |> distinct(cpfCand) |> pull(cpfCand)

eleito_fed_2014 <- readRDS("data/raw/eleitos_2014_df.rds") |>
  distinct(sq_candidato, eleito) |>
  left_join(cand_fed_2014_cpf, by = "sq_candidato") |>
  filter(eleito == 1) |> distinct(cpfCand) |> pull(cpfCand)

incumbencia_completa <- bind_rows(
  cand_fed_2018_cpf |>
    mutate(cargo = "Federal", ANO_ELEICAO = "2018",
           incumbente = as.integer(cpfCand %in% eleito_fed_2014)),
  cand_fed_2022_cpf |>
    mutate(cargo = "Federal", ANO_ELEICAO = "2022",
           incumbente = as.integer(cpfCand %in% eleito_fed_2018)),
  cand_est_2018_cpf |>
    mutate(cargo = "Estadual", ANO_ELEICAO = "2018",
           incumbente = as.integer(cpfCand %in% eleito_est_2014)),
  cand_est_2022_cpf |>
    mutate(cargo = "Estadual", ANO_ELEICAO = "2022",
           incumbente = as.integer(cpfCand %in% eleito_est_2018))
) |>
  select(sq_candidato, cargo, ANO_ELEICAO, incumbente)

# Cobertura de incumbência por célula — checagem de suporte; persistida em
# disco (Issue 5) para consulta sem re-rodar o script interativamente.
cobertura_incumbencia <- incumbencia_completa |> summarise(
  n = n(), taxa_incumbente_pct = round(100 * mean(incumbente, na.rm = TRUE), 1),
  .by = c(cargo, ANO_ELEICAO)
)
saveRDS(cobertura_incumbencia, file.path(out_dir, "ddd_cobertura_incumbencia.rds"))

# ---- DDD completa (Federal x Estadual), controlando por incumbência ----

df_genero_inc <- df_genero |>
  left_join(incumbencia_completa, by = c("sq_candidato", "cargo", "ANO_ELEICAO"))

modelo_genero_incumbencia <- feols(
  taxa_sobreposicao ~ federal * ano2022 * mulher + incumbente | partido_harm + SG_UF,
  data = df_genero_inc,
  cluster = ~ partido_harm + SG_UF
)
if (length(modelo_genero_incumbencia$collin.var) > 0) {
  warning("modelo_genero_incumbencia: variavel(is) colinear(es) absorvida(s) pelos efeitos fixos: ",
          paste(modelo_genero_incumbencia$collin.var, collapse = ", "))
}

df_raca_inc <- df_raca |>
  left_join(incumbencia_completa, by = c("sq_candidato", "cargo", "ANO_ELEICAO"))

modelo_raca_incumbencia <- feols(
  taxa_sobreposicao ~ federal * ano2022 * negra + incumbente | partido_harm + SG_UF,
  data = df_raca_inc,
  cluster = ~ partido_harm + SG_UF
)
if (length(modelo_raca_incumbencia$collin.var) > 0) {
  warning("modelo_raca_incumbencia: variavel(is) colinear(es) absorvida(s) pelos efeitos fixos: ",
          paste(modelo_raca_incumbencia$collin.var, collapse = ", "))
}

message("Secao 5 — Incumbencia: CPFs eleitos (Federal 2014 = ", length(eleito_fed_2014),
        ", Federal 2018 = ", length(eleito_fed_2018),
        ", Estadual 2014 = ", length(eleito_est_2014),
        ", Estadual 2018 = ", length(eleito_est_2018), "); ",
        "genero N = ", nrow(df_genero_inc),
        " (", sum(is.na(df_genero_inc$incumbente)), " sem incumbencia identificada); ",
        "raca N = ", nrow(df_raca_inc),
        "; cobertura por celula salva em ddd_cobertura_incumbencia.rds")

# ==============================================================================
# 6. SALVAR
# ==============================================================================

saveRDS(modelo_genero,               file.path(out_dir, "ddd_modelo_genero.rds"))
saveRDS(broom::tidy(modelo_genero, conf.int = TRUE),
        file.path(out_dir, "ddd_modelo_genero_tidy.rds"))

saveRDS(modelo_raca,                 file.path(out_dir, "ddd_modelo_raca.rds"))
saveRDS(broom::tidy(modelo_raca, conf.int = TRUE),
        file.path(out_dir, "ddd_modelo_raca_tidy.rds"))

saveRDS(modelo_genero_resultado,     file.path(out_dir, "ddd_modelo_genero_resultado.rds"))
saveRDS(broom::tidy(modelo_genero_resultado, conf.int = TRUE),
        file.path(out_dir, "ddd_modelo_genero_resultado_tidy.rds"))

saveRDS(modelo_raca_resultado,       file.path(out_dir, "ddd_modelo_raca_resultado.rds"))
saveRDS(broom::tidy(modelo_raca_resultado, conf.int = TRUE),
        file.path(out_dir, "ddd_modelo_raca_resultado_tidy.rds"))

saveRDS(modelo_genero_incumbencia,   file.path(out_dir, "ddd_modelo_genero_incumbencia.rds"))
saveRDS(broom::tidy(modelo_genero_incumbencia, conf.int = TRUE),
        file.path(out_dir, "ddd_modelo_genero_incumbencia_tidy.rds"))

saveRDS(modelo_raca_incumbencia,     file.path(out_dir, "ddd_modelo_raca_incumbencia.rds"))
saveRDS(broom::tidy(modelo_raca_incumbencia, conf.int = TRUE),
        file.path(out_dir, "ddd_modelo_raca_incumbencia_tidy.rds"))

saveRDS(incumbencia_completa,        file.path(out_dir, "incumbencia_completa_candidato.rds"))

etable(modelo_genero, modelo_genero_resultado, modelo_genero_incumbencia,
       file = file.path(out_dir, "ddd_genero_especificacoes.tex"), replace = TRUE)
etable(modelo_raca, modelo_raca_resultado, modelo_raca_incumbencia,
       file = file.path(out_dir, "ddd_raca_especificacoes.tex"), replace = TRUE)

message("Secao 6 — DDD concluido: modelos (raw + tidy) e diagnosticos salvos em ", out_dir)
