# ==============================================================================
# Painéis para o DiD da EC 111/2021 com 2014, 2018, 2022 e 2026
#
# (a) Lista = partido (sigla harmonizada para a vigente em 2026) × UF × cargo × ano
# (b) Disputa = UF × cargo × ano (para o sucesso: % das cadeiras ocupadas pelo grupo)
#
# Resultados (pontos percentuais; g = mulher ou negra):
#   cand_g        % das candidaturas aptas da lista que são do grupo g        2014–2026
#   voto_g        % dos votos nominais da lista obtidos por g                  2014–2026
#   compet_g      % das candidaturas da lista que são g e competitivas         2014–2026
#                 (votos ≥ 10% do QE ou eleita)
#   eleita_g      % das candidaturas da lista que são g e foram eleitas        2014–2026
#   gasto_g       % do gasto da lista feito por candidaturas de g              2018–2026
#   rec_partido_g % das transferências do partido à lista recebidas por g      2018–2026
#   rec_publico_g % dos recursos públicos (FEFC + FP) da lista recebidos por g 2018–2026
#   rec_total_g   % de todas as receitas da lista recebidas por g              2018–2026
#   Disputa: cadeira_g = % dos eleitos que são g; cand_g, voto_g idem.
# Recursos e gasto de 2026 vêm da prestação PARCIAL (ver 01_bases_2026.R).
#
# Rodar da raiz, depois de 01_bases_2026.R e dos scripts 01, 04 e 05 de
# explorations/competitividade-gasto (base de 2018/2022):
#   Rscript explorations/ec111-did-2026/R/02_painel_listas.R
# Saídas: data/processed/painel_listas_2014_2026.rds, painel_disputas_2014_2026.rds
#         output/listas_por_ano.csv, output/descritivo_grupos_ano_cargo.csv
# ==============================================================================

library(tidyverse)

source("explorations/competitividade-gasto/R/funcoes_apoio.R")
out_dir <- "explorations/ec111-did-2026/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
rd <- \(f) readRDS(file.path("data/raw", f)) |> as_tibble() |> ungroup()

cadeiras_fed <- c(SP = 70, MG = 53, RJ = 46, BA = 39, RS = 31, PR = 30, PE = 25, CE = 22, MA = 18,
                  GO = 17, PA = 17, SC = 16, PB = 12, ES = 10, PI = 10, AL = 9, AC = 8, AM = 8,
                  AP = 8, MS = 8, MT = 8, RN = 8, RO = 8, RR = 8, SE = 8, TO = 8)

# Siglas de 2014 → sigla de 2018 (depois harmonizar_partido_2026 leva a 2026)
mapa_2014 <- c("PMDB" = "MDB", "PT do B" = "PTdoB", "SD" = "SOLIDARIEDADE", "PRP" = "PATRIOTA",
               "PPL" = "PC do B", "PEN" = "PATRIOTA", "PSDC" = "DC", "PTN" = "PODE")
# Grafias de 2026 → mesma grafia de harmonizar_partido_2026
mapa_grafia_2026 <- c("PC do B" = "PCDOB")
para_2026 <- function(sigla, ano) {
  s <- if_else(ano == "2014" & sigla %in% names(mapa_2014), unname(mapa_2014[sigla]), sigla)
  s <- harmonizar_partido_2026(s)
  if_else(s %in% names(mapa_grafia_2026), unname(mapa_grafia_2026[s]), s)
}

# ------------------------------------------------------------------------------
# 1. Candidaturas aptas, 2014–2026 (mesmas colunas)
# ------------------------------------------------------------------------------
cols <- c("ANO", "DS_CARGO", "sq_candidato", "uf", "partido", "mulher", "negra",
          "VOTOS_CAND_TOTAL", "compet", "eleito", "gasto", "receita_total", "receita_publica",
          "receita_partido")

# 2014 (sem recursos: 2014 não serve de referência para financiamento)
votos_fed_14 <- rd("votos_mun_2014_df.rds")
qe_fed_14 <- votos_fed_14 |>
  summarise(VOTOS_UF = sum(VOTOS, na.rm = TRUE), .by = SG_UF) |>   # nominais + legenda
  mutate(QE = VOTOS_UF / cadeiras_fed[SG_UF])
fed_14 <- votos_fed_14 |>
  summarise(VOTOS_CAND_TOTAL = sum(VOTOS, na.rm = TRUE), .by = c(SG_UF, sq_candidato)) |>
  left_join(qe_fed_14, by = "SG_UF") |>
  left_join(rd("eleitos_2014_df.rds") |> select(sq_candidato, eleito), by = "sq_candidato") |>
  transmute(sq_candidato, VOTOS_CAND_TOTAL, eleito = replace_na(as.integer(eleito), 0L),
            competitivo = as.integer(VOTOS_CAND_TOTAL >= 0.1 * QE), DS_CARGO = "Deputado Federal")
est_14 <- rd("eleitos_e_compet_est_2014_df.rds") |>
  transmute(sq_candidato, VOTOS_CAND_TOTAL, eleito = as.integer(eleito),
            competitivo = as.integer(competitivo), DS_CARGO = "Deputado Estadual")
c14 <- bind_rows(rd("candidatos2014.rds") |> mutate(DS_CARGO = "Deputado Federal"),
                 rd("candidatos_estadual_2014.rds") |> mutate(DS_CARGO = "Deputado Estadual")) |>
  filter(situacao_candidatura == "APTO", genero %in% c("FEMININO", "MASCULINO")) |>
  inner_join(bind_rows(fed_14, est_14), by = c("sq_candidato", "DS_CARGO")) |>
  mutate(ANO = "2014", mulher = genero == "FEMININO", negra = raca2(raca) == "NEGRA",
         compet = competitivo == 1L | eleito == 1L,
         gasto = NA_real_, receita_total = NA_real_, receita_publica = NA_real_,
         receita_partido = NA_real_) |>
  select(all_of(cols))

# 2018 e 2022 (base da exploração competitividade-gasto; sem DF)
c1822 <- readRDS("data/processed/base_did_candidatos.rds") |>
  mutate(compet = compet_voto == 1L, eleito = as.integer(eleito)) |>
  select(all_of(cols))

# 2026
c26 <- readRDS("data/processed/cand_dep_2026.rds") |>
  filter(genero %in% c("FEMININO", "MASCULINO")) |>
  mutate(mulher = genero == "FEMININO", negra = raca2(raca) == "NEGRA",
         compet = competitivo == 1L | eleito == 1L) |>
  select(all_of(cols))

cand <- bind_rows(c14, c1822, c26) |>
  filter(uf != "DF") |>
  mutate(partido_h = para_2026(partido, ANO), federal = DS_CARGO == "Deputado Federal")
stopifnot(!anyDuplicated(cand[c("ANO", "DS_CARGO", "sq_candidato")]))

# Descritivo nacional por ano × cargo (o "antes e depois" bruto)
descr <- cand |>
  summarise(candidaturas = n(),
            pct_cand_mulheres = 100 * mean(mulher), pct_cand_negras = 100 * mean(negra),
            pct_votos_mulheres = 100 * sum(VOTOS_CAND_TOTAL[mulher]) / sum(VOTOS_CAND_TOTAL),
            pct_votos_negras = 100 * sum(VOTOS_CAND_TOTAL[negra]) / sum(VOTOS_CAND_TOTAL),
            pct_eleitos_mulheres = 100 * mean(mulher[eleito == 1]),
            pct_eleitos_negras = 100 * mean(negra[eleito == 1]),
            pct_rec_partido_mulheres = 100 * sum(receita_partido[mulher]) / sum(receita_partido),
            pct_rec_partido_negras = 100 * sum(receita_partido[negra]) / sum(receita_partido),
            pct_gasto_mulheres = 100 * sum(gasto[mulher]) / sum(gasto),
            pct_gasto_negras = 100 * sum(gasto[negra]) / sum(gasto),
            .by = c(DS_CARGO, ANO)) |>
  arrange(DS_CARGO, ANO)
write_excel_csv2(descr, file.path(out_dir, "descritivo_grupos_ano_cargo.csv"))
print(as.data.frame(descr |> mutate(across(where(is.numeric), \(x) round(x, 1)))))

# ------------------------------------------------------------------------------
# 2. Painel de listas
# ------------------------------------------------------------------------------
pp <- \(num, den) if_else(den > 0, 100 * num / den, NA_real_)
fontes <- c(gasto = "gasto", rec_total = "receita_total", rec_publico = "receita_publica",
            rec_partido = "receita_partido")

painel <- cand |>
  summarise(n_cand = n(), votos_lista = sum(VOTOS_CAND_TOTAL), n_eleitos = sum(eleito),
            # referência: mudanças que não dependem do grupo (viés mecânico em compet_g/eleita_g)
            compet_todos = 100 * mean(compet), eleita_todos = 100 * mean(eleito == 1L),
            across(c(mulher, negra), list(
              compshare = \(g) pp(sum(g & compet), sum(compet)),   # % das competitivas que são g
              cand   = \(g) 100 * mean(g),
              voto   = \(g) pp(sum(VOTOS_CAND_TOTAL[g]), sum(VOTOS_CAND_TOTAL)),
              compet = \(g) 100 * mean(g & compet),
              eleita = \(g) 100 * mean(g & eleito == 1L),
              gasto       = \(g) pp(sum(gasto[g]), sum(gasto)),
              rec_total   = \(g) pp(sum(receita_total[g]), sum(receita_total)),
              rec_publico = \(g) pp(sum(receita_publica[g]), sum(receita_publica)),
              rec_partido = \(g) pp(sum(receita_partido[g]), sum(receita_partido))),
              .names = "{.fn}_{.col}"),
            .by = c(ANO, DS_CARGO, federal, uf, partido_h)) |>
  filter(votos_lista > 0, !is.na(partido_h)) |>          # PHS (extinto) sai
  mutate(lista = paste(partido_h, uf, DS_CARGO), ano = as.integer(ANO),
         gname = if_else(federal, 2022L, 0L), id = as.integer(factor(lista))) |>
  mutate(anos_presente = paste(sort(unique(ano)), collapse = "-"), .by = lista) |>
  mutate(peso = sum(votos_lista[ano == 2018L]), .by = lista)    # peso: votos da lista em 2018
saveRDS(painel, "data/processed/painel_listas_2014_2026.rds")

presenca <- painel |>
  distinct(lista, DS_CARGO, anos_presente) |>
  count(DS_CARGO, anos_presente, name = "listas") |>
  arrange(DS_CARGO, desc(listas))
write_excel_csv2(presenca, file.path(out_dir, "listas_por_ano.csv"))
message("Listas por padrão de presença (top 6 por cargo):")
print(as.data.frame(presenca |> slice_head(n = 6, by = DS_CARGO)))
sem_par_2026 <- setdiff(unique(painel$partido_h[painel$ano == 2026]),
                        unique(painel$partido_h[painel$ano == 2022]))
message("Siglas de 2026 sem lista em 2022: ", paste(sem_par_2026, collapse = ", "))

# ------------------------------------------------------------------------------
# 3. Painel de disputas (UF × cargo)
# ------------------------------------------------------------------------------
disputas <- cand |>
  summarise(n_cadeiras = sum(eleito),
            across(c(mulher, negra), list(
              cadeira = \(g) pp(sum(g & eleito == 1L), sum(eleito == 1L)),
              cand    = \(g) 100 * mean(g),
              voto    = \(g) pp(sum(VOTOS_CAND_TOTAL[g]), sum(VOTOS_CAND_TOTAL)),
              compet  = \(g) pp(sum(g & compet), sum(compet))),
              .names = "{.fn}_{.col}"),
            .by = c(ANO, DS_CARGO, federal, uf)) |>
  mutate(ano = as.integer(ANO), gname = if_else(federal, 2022L, 0L),
         id = as.integer(factor(paste(uf, DS_CARGO))))
stopifnot(nrow(disputas) == 26L * 2L * 4L)
saveRDS(disputas, "data/processed/painel_disputas_2014_2026.rds")
message("Painéis salvos: ", n_distinct(painel$id), " listas; ", n_distinct(disputas$id), " disputas")
