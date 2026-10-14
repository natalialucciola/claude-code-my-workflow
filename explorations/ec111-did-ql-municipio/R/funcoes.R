# ==============================================================================
# Funções comuns — DiD da EC 111 com QL por município (ec111-did-ql-municipio)
#
# Monta, a partir das bases candidato × município com QL_voto (2010–2026), o
# painel partido × território × cargo × ano com:
#   - presença de base (QL > ql_min e fatia ≥ fatia_min), por grupo;
#   - transição para território novo (sem base em t−1, com base em t),
#     decomposta em nova_base_g + nova_base_naog;
#   - sobreposição com base de incumbente (ponte com o Cap. 6).
# Fontes: 2010/2014 em output/dados desta exploração (01_ql_2010_2014.R);
#         2018/2022/2026 em explorations/ql-voto-2026/output/dados.
# ==============================================================================

dir_ql_antigo <- file.path("explorations", "ec111-did-ql-municipio", "output", "dados")
dir_ql_novo   <- file.path("explorations", "ql-voto-2026", "output", "dados")
anos_painel   <- c(2010L, 2014L, 2018L, 2022L, 2026L)
anos_did      <- c(2014L, 2018L, 2022L, 2026L)   # 2010 só entra como t−1 de 2014

# ---- Partidos: sigla bruta do TSE (2010–2026) → linhagem vigente em 2026 ----
# Fusões, incorporações e renomeações; mesma convenção de harmonizar_partido_2026()
# (explorations/competitividade-gasto/R/funcoes_apoio.R), estendida às siglas de
# 2010/2014. PHS (incorporado em 2019) fica NA, como nas análises irmãs.
mapa_partido_2026 <- c(
  "PMDB" = "MDB", "PR" = "PL", "DEM" = "UNIÃO", "PSL" = "UNIÃO", "PPS" = "CIDADANIA",
  "PRB" = "REPUBLICANOS", "PSDC" = "DC", "PTC" = "AGIR", "PT do B" = "AVANTE",
  "PTdoB" = "AVANTE", "PTN" = "PODE", "PSC" = "PODE", "SD" = "SOLIDARIEDADE",
  "PROS" = "SOLIDARIEDADE", "PTB" = "PRD", "PATRI" = "PRD", "PATRIOTA" = "PRD",
  "PRP" = "PRD", "PEN" = "PRD", "PMN" = "MOBILIZA", "PMB" = "DEMOCRATA",
  "PC do B" = "PCDOB", "PPL" = "PCDOB"
)

#' Harmoniza a sigla bruta para a linhagem de 2026
#'
#' @param sigla Vetor de siglas do TSE de qualquer ano entre 2010 e 2026.
#' @return Vetor de siglas de 2026; PHS vira NA.
harmonizar_partido_2026 <- function(sigla) {
  s <- if_else(sigla %in% names(mapa_partido_2026), unname(mapa_partido_2026[sigla]), sigla)
  s[sigla == "PHS"] <- NA_character_
  s
}

#' Normaliza CPF para 11 dígitos (as fontes diferem em zeros à esquerda)
normalizar_cpf <- function(cpf) {
  d <- str_remove_all(cpf, "\\D")
  if_else(is.na(d) | d == "" | d == "0" | str_detect(d, "^0+$"), NA_character_,
          str_pad(d, 11, pad = "0"))
}

# ---- Leitura das bases candidato × município ----

#' Lê e empilha as bases candidato × município de 2010–2026 (um cargo)
#'
#' @param cargo "federal" ou "estadual".
#' @return tibble com ano (int), cargo, partido, SG_UF, COD_MUN_TSE (5 dígitos),
#'   sq_candidato, cpf, votos, V_cand, eleito, competitivo, mulher, negra.
ler_bases_candidato <- function(cargo) {
  map(anos_painel, function(a) {
    dir <- if (a <= 2014L) dir_ql_antigo else dir_ql_novo
    readRDS(file.path(dir, sprintf("ql_voto_%s_%d.rds", cargo, a))) |>
      transmute(ano = as.integer(ANO_ELEICAO), cargo, SG_UF,
                COD_MUN_TSE = str_pad(as.integer(COD_MUN_TSE), 5, pad = "0"),
                sq_candidato, cpf = normalizar_cpf(cpf), votos, V_cand,
                eleito = as.integer(eleito), competitivo = as.integer(competitivo),
                mulher = as.integer(genero == "FEMININO"),
                # cor/raça só existe a partir de 2014
                negra = if (a == 2010L) NA_integer_ else as.integer(raca2 == "NEGRA"),
                partido = harmonizar_partido_2026(sg_partido))
  }) |>
    list_rbind() |>
    # PHS (partido NA) fica até o cálculo do QL, para não mudar o denominador
    filter(SG_UF != "DF")
}

#' Marca incumbentes: CPF eleito no mesmo cargo na eleição anterior
#'
#' @param cand Saída de ler_bases_candidato().
#' @return cand + coluna incumbente (0/1; NA em 2010, sem eleição anterior na base).
marcar_incumbentes <- function(cand) {
  eleitos <- cand |>
    filter(eleito == 1L, !is.na(cpf)) |>
    distinct(cargo, ano_eleito = ano, cpf)
  cand |>
    mutate(ano_eleito = ano - 4L) |>
    left_join(mutate(eleitos, inc = 1L), by = c("cargo", "ano_eleito", "cpf")) |>
    mutate(incumbente = case_when(ano == min(anos_painel) ~ NA_integer_,
                                  is.na(inc) ~ 0L, TRUE ~ 1L)) |>
    select(-ano_eleito, -inc)
}

# ---- Território: município ou RGI ----

#' Tabela município TSE → RGI (IBGE 2017)
ler_mun_rgi <- function() {
  ids <- readRDS("data/raw/ids_municipios_ibge.rds") |>
    transmute(COD_MUN_TSE = str_pad(as.integer(COD_MUN_TSE), 5, pad = "0"), COD_MUN_IBGE)
  rgi <- read_csv("data/raw/ibge_municipio_rgi.csv", col_types = cols(.default = "c"))
  ids |> inner_join(select(rgi, COD_MUN_IBGE, cod_rgi), by = "COD_MUN_IBGE") |>
    select(COD_MUN_TSE, cod_rgi)
}

#' Agrega votos ao território e recalcula o QL nesse nível
#'
#' No município, o QL é recalculado com a mesma fórmula do ql-voto-2026 (W = votos
#' nominais do cargo no território); na RGI, os votos são somados antes.
#' @param cand Candidato × município (com incumbente).
#' @param territorio "municipio" ou "rgi".
#' @return candidato × território com votos, V_cand, QL.
agregar_territorio <- function(cand, territorio = c("municipio", "rgi")) {
  territorio <- match.arg(territorio)
  if (territorio == "rgi") {
    mr <- ler_mun_rgi()
    sem_rgi <- setdiff(unique(cand$COD_MUN_TSE), mr$COD_MUN_TSE)
    if (length(sem_rgi) > 0) message("Municípios TSE sem RGI (descartados): ", length(sem_rgi))
    cand <- cand |> inner_join(mr, by = "COD_MUN_TSE") |> mutate(terr = cod_rgi)
  } else {
    cand <- cand |> mutate(terr = COD_MUN_TSE)
  }
  cand |>
    summarise(votos = sum(votos),
              .by = c(ano, cargo, SG_UF, terr, partido, sq_candidato, cpf, V_cand, eleito,
                      competitivo, mulher, negra, incumbente)) |>
    mutate(W_terr = sum(votos), .by = c(ano, cargo, SG_UF, terr)) |>
    mutate(W_uf = sum(votos), .by = c(ano, cargo, SG_UF)) |>
    # participação do território no voto do candidato ÷ participação no voto do cargo na UF
    mutate(QL = (votos / V_cand) / (W_terr / W_uf), fatia = votos / V_cand) |>
    select(-W_uf)
}

# ---- Painel ----

#' Monta o painel partido × território × cargo × ano
#'
#' @param ct Saída de agregar_territorio() para os dois cargos.
#' @param ql_min Limiar do QL (base = QL > ql_min).
#' @param fatia_min Fatia mínima do território nos votos do candidato.
#' @param so_competitivas Se TRUE, só candidaturas competitivas formam base.
#' @param balanceado Se TRUE, mantém só listas partido × UF presentes nos dois cargos
#'   em todos os anos 2010–2026.
#' @return tibble com uma linha por partido × UF × território × cargo × ano (2014–2026).
montar_painel <- function(ct, ql_min = 1, fatia_min = 0.025, so_competitivas = FALSE,
                          balanceado = TRUE) {
  ct <- ct |>
    filter(!is.na(partido)) |>
    mutate(base = QL > ql_min & fatia >= fatia_min &
             (!so_competitivas | competitivo == 1L))

  # Listas (partido × UF × cargo) que disputaram cada eleição
  listas <- ct |> distinct(ano, cargo, SG_UF, partido)
  if (balanceado) {
    ok <- listas |>
      count(SG_UF, partido, name = "n") |>
      filter(n == length(anos_painel) * 2L) |>   # 5 eleições × 2 cargos
      select(SG_UF, partido)
    listas <- listas |> semi_join(ok, by = c("SG_UF", "partido"))
  }

  # Territórios com voto no cargo em todas as eleições (universo fixo por UF)
  terrs <- ct |>
    distinct(ano, cargo, SG_UF, terr) |>
    count(cargo, SG_UF, terr) |>
    filter(n == length(anos_painel)) |>
    distinct(SG_UF, terr) |>
    # território precisa existir nos dois cargos
    semi_join(ct |> distinct(SG_UF, terr, cargo) |> count(SG_UF, terr) |> filter(n == 2L),
              by = c("SG_UF", "terr"))

  # Agregados por partido × território × cargo × ano
  agg <- ct |>
    summarise(
      votos_partido = sum(votos),
      votos_g_mulher = sum(votos * mulher, na.rm = TRUE),
      votos_g_negra = sum(votos * negra, na.rm = TRUE),
      tem_base = as.integer(any(base)),
      base_mulher = as.integer(any(base & mulher == 1L, na.rm = TRUE)),
      base_negra = as.integer(any(base & negra == 1L, na.rm = TRUE)),
      # incumbente de fora do grupo com base no território (para sobreposição)
      base_inc_nao_mulher = as.integer(any(base & incumbente == 1L & mulher == 0L,
                                           na.rm = TRUE)),
      base_inc_nao_negra = as.integer(any(base & incumbente == 1L & negra == 0L,
                                          na.rm = TRUE)),
      .by = c(ano, cargo, SG_UF, terr, partido)
    )

  painel <- listas |>
    inner_join(terrs, by = "SG_UF", relationship = "many-to-many") |>
    left_join(agg, by = c("ano", "cargo", "SG_UF", "terr", "partido")) |>
    mutate(across(c(votos_partido, votos_g_mulher, votos_g_negra, tem_base, base_mulher,
                    base_negra, base_inc_nao_mulher, base_inc_nao_negra),
                  \(x) coalesce(x, 0)))

  # 2010 sem raça: base_negra não definida
  painel <- painel |> mutate(base_negra = if_else(ano == 2010L, NA_real_, base_negra))

  painel |>
    arrange(cargo, SG_UF, partido, terr, ano) |>
    mutate(
      # t−1 só existe se a lista disputou a eleição imediatamente anterior
      tem_base_ant = if_else(lag(ano) == ano - 4L, lag(tem_base), NA_real_),
      peso_2018 = sum(votos_partido * (ano == 2018L)),
      .by = c(cargo, SG_UF, partido, terr)
    ) |>
    filter(ano %in% anos_did) |>
    mutate(
      # ---- resultado principal: entrada em território novo, decomposta ----
      nova_base = (1 - tem_base_ant) * tem_base,
      nova_base_mulher = (1 - tem_base_ant) * base_mulher,
      nova_base_nao_mulher = nova_base - nova_base_mulher,
      nova_base_negra = (1 - tem_base_ant) * base_negra,
      nova_base_nao_negra = nova_base - nova_base_negra,
      # ---- secundários ----
      voto_mulher_terr = if_else(votos_partido > 0, 100 * votos_g_mulher / votos_partido,
                                 NA_real_),
      voto_negra_terr = if_else(votos_partido > 0, 100 * votos_g_negra / votos_partido,
                                NA_real_),
      base_mulher_livre = base_mulher * (1 - base_inc_nao_mulher),
      base_mulher_sobrep = base_mulher * base_inc_nao_mulher,
      base_negra_livre = base_negra * (1 - base_inc_nao_negra),
      base_negra_sobrep = base_negra * base_inc_nao_negra,
      federal = as.integer(cargo == "Federal"),
      gname = if_else(federal == 1L, 2022L, 0L),
      lista = paste(partido, SG_UF, cargo, sep = "|"),
      unidade = paste(partido, SG_UF, terr, cargo, sep = "|"),
      pt = paste(partido, SG_UF, terr, sep = "|")
    ) |>
    mutate(id = as.integer(factor(unidade)), lista_id = as.integer(factor(lista)))
}
