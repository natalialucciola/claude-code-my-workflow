# ==============================================================================
# Placebo com 2014: DiD com três eleições (2014, 2018, 2022)
#
# Pré-teste de tendências paralelas (tempo de evento em anos: placebo e = −4, efeito e = 0): entre 2014 e
# 2018 (antes da EC 111) deve ser ≈ 0. Com base_period = "varying" do pacote did,
# ATT(g = 2022, t = 2018) compara 2014 → 2018 (placebo); ATT(2022, 2022) compara
# 2018 → 2022 (efeito). Medidas m6 e m8 apenas (em 2014 não havia limite legal → sem m2).
#
# 2014 — cuidados de construção:
#   gasto: despesas das candidaturas, EXCLUINDO doações a outros candidatos/comitês/
#          partidos e os lançamentos "Baixa de Estimaveis - ..." (inexistentes nos
#          arquivos de despesas contratadas de 2018 e 2022).
#   recursos do partido: receitas "Recursos de partido político" (qualquer fonte).
#          Em 2014 havia doação empresarial, parte repassada pelos partidos — o
#          recurso "do partido" tinha natureza diferente de 2018/2022 (FEFC).
#   m8: regra "descartar eleitos com gasto < 1% do limite" usa um pseudolimite =
#          limite de 2018 ÷ 1,26 (IPCA aproximado entre 2014 e 2018).
#   votos (federal): soma dos votos por município; eleito: eleitos_2014_df.
#
# Rodar da raiz, depois dos scripts 01, 04 e 05:
#   Rscript explorations/competitividade-gasto/R/07_placebo_2014.R
# Entradas extras: data/raw/prestacao_final_2014.zip (TSE, baixado pelo navegador),
#   candidatos2014.rds, candidatos_estadual_2014.rds, votos_mun_2014_df.rds,
#   eleitos_2014_df.rds, eleitos_e_compet_est_2014_df.rds
# ==============================================================================

.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
library(data.table)
library(tidyverse)
library(did)
library(fixest)

source("explorations/competitividade-gasto/R/funcoes_apoio.R")
set.seed(20260928)
out_dir <- "explorations/competitividade-gasto/output"
tmp_dir <- file.path(tempdir(), "p2014"); dir.create(tmp_dir, showWarnings = FALSE)
biters  <- 1000L
cargos  <- c("Deputado Federal", "Deputado Estadual")
ipca_2014_2018 <- 1.26
teto_2018 <- c("Deputado Federal" = 2500000, "Deputado Estadual" = 1000000)

# Siglas de 2014 e 2018 → sigla de 2022 (listas comparáveis nas três eleições)
mapa_2022 <- c(partido_map_2018_2022, "PMDB" = "MDB", "PT do B" = "AVANTE", "SD" = "SOLIDARIEDADE",
               "PRP" = "PATRIOTA", "PPL" = "PC do B", "PHS" = "PODE")
para_2022 <- \(p) if_else(p %in% names(mapa_2022), unname(mapa_2022[p]), p)

# ------------------------------------------------------------------------------
# 1. Candidaturas de 2014 com votos, gasto e recursos do partido
# ------------------------------------------------------------------------------
ler_2014 <- function(arquivo, cols) {
  unzip("data/raw/prestacao_final_2014.zip", files = arquivo, exdir = tmp_dir, overwrite = TRUE)
  x <- fread(file.path(tmp_dir, arquivo), sep = ";", encoding = "Latin-1", colClasses = "character",
             select = cols)
  file.remove(file.path(tmp_dir, arquivo))
  as_tibble(x[Cargo %in% cargos])
}
num <- \(x) as.numeric(sub(",", ".", x, fixed = TRUE))

desp <- ler_2014("despesas_candidatos_2014_brasil.txt",
                 c("Sequencial Candidato", "Cargo", "Tipo despesa", "Valor despesa")) |>
  mutate(v = num(`Valor despesa`),
         excluir = str_detect(`Tipo despesa`, "^Doações financeiras a outros|^Baixa de Estimaveis")) |>
  summarise(gasto = sum(v[!excluir], na.rm = TRUE), .by = c(`Sequencial Candidato`, Cargo))
rec <- ler_2014("receitas_candidatos_2014_brasil.txt",
                c("Sequencial Candidato", "Cargo", "Tipo receita", "Valor receita")) |>
  mutate(v = num(`Valor receita`)) |>
  summarise(receita_partido = sum(v[`Tipo receita` == "Recursos de partido político"], na.rm = TRUE),
            .by = c(`Sequencial Candidato`, Cargo))

rd <- \(f) readRDS(file.path("data/raw", f)) |> as_tibble()
votos_fed <- rd("votos_mun_2014_df.rds") |>
  summarise(VOTOS_CAND_TOTAL = sum(VOTOS, na.rm = TRUE), .by = sq_candidato) |>
  left_join(rd("eleitos_2014_df.rds") |> select(sq_candidato, eleito), by = "sq_candidato") |>
  mutate(eleito = replace_na(eleito, 0L), DS_CARGO = "Deputado Federal")
votos_est <- rd("eleitos_e_compet_est_2014_df.rds") |>
  transmute(sq_candidato, VOTOS_CAND_TOTAL, eleito, DS_CARGO = "Deputado Estadual")

c14 <- bind_rows(rd("candidatos2014.rds") |> mutate(DS_CARGO = "Deputado Federal"),
                 rd("candidatos_estadual_2014.rds") |> mutate(DS_CARGO = "Deputado Estadual")) |>
  filter(situacao_candidatura == "APTO", genero %in% c("FEMININO", "MASCULINO"), uf != "DF") |>
  inner_join(bind_rows(votos_fed, votos_est), by = c("sq_candidato", "DS_CARGO")) |>
  left_join(desp, by = c("sq_candidato" = "Sequencial Candidato", "DS_CARGO" = "Cargo")) |>
  left_join(rec, by = c("sq_candidato" = "Sequencial Candidato", "DS_CARGO" = "Cargo")) |>
  mutate(ANO = "2014", across(c(gasto, receita_partido), \(x) replace_na(x, 0)),
         mulher = genero == "FEMININO", negra = raca2(raca) == "NEGRA",
         pseudolimite = teto_2018[DS_CARGO] / ipca_2014_2018)
stopifnot(!anyDuplicated(c14[c("DS_CARGO", "sq_candidato")]))

# Medidas m6 e m8 para 2014 (mesmas regras do script 05)
c14 <- c14 |>
  mutate(n_partido = n(), rec_tot = sum(receita_partido),
         m6 = if_else(rec_tot > 0, receita_partido / rec_tot * n_partido, 0),
         .by = c(DS_CARGO, uf, partido)) |>
  left_join(c14 |> filter(eleito == 1, gasto >= 0.01 * pseudolimite) |>
              summarise(ref = min(gasto), .by = c(DS_CARGO, uf)), by = c("DS_CARGO", "uf")) |>
  mutate(m8 = gasto / ref)

# ------------------------------------------------------------------------------
# 2. Base das três eleições e painel de listas
# ------------------------------------------------------------------------------
niveis <- list(m6 = c("Não recebeu", "< 0,5×", "0,5–1×", "1–5×", "≥ 5×"),
               m8 = c("< 10%", "10–25%", "25–50%", "50–100%", "≥ 100%"))
faixa_m6 <- \(x) factor(case_when(x <= 0 ~ niveis$m6[1], x < .5 ~ niveis$m6[2], x < 1 ~ niveis$m6[3],
                                  x < 5 ~ niveis$m6[4], TRUE ~ niveis$m6[5]), levels = niveis$m6)
faixa_m8 <- \(x) cut(x, c(-Inf, .10, .25, .50, 1, Inf), right = FALSE, labels = niveis$m8)

cols <- c("ANO", "DS_CARGO", "uf", "partido", "mulher", "negra", "VOTOS_CAND_TOTAL",
          "receita_partido", "m6", "m8")
cand <- bind_rows(c14 |> select(all_of(cols)),
                  readRDS("data/processed/base_did_candidatos.rds") |> select(all_of(cols))) |>
  mutate(partido_lista = para_2022(partido),
         faixa_m6 = faixa_m6(m6), faixa_m8 = faixa_m8(m8),
         viavel_m6 = m6 >= 1, viavel_m8 = m8 >= .5)
stopifnot(!anyNA(cand$faixa_m6), !anyNA(cand$faixa_m8))

pp <- \(num, den) if_else(den > 0, 100 * num / den, NA_real_)
resumir <- function(d) {
  V <- sum(d$VOTOS_CAND_TOTAL); R <- sum(d$receita_partido)
  out <- list(votos_lista = V)
  for (g in c("mulher", "negra")) {
    gi <- d[[g]]
    out[[paste0("voto_", g)]] <- pp(sum(d$VOTOS_CAND_TOTAL[gi]), V)
    out[[paste0("rec_", g)]]  <- pp(sum(d$receita_partido[gi]), R)
    for (m in c("m6", "m8")) {
      vi <- d[[paste0("viavel_", m)]]
      out[[paste0("cand_viavel_", g, "_", m)]] <- 100 * mean(gi & vi)
      out[[paste0("rec_viavel_", g, "_", m)]]  <- pp(sum(d$receita_partido[gi & vi]), R)
      fx <- d[[paste0("faixa_", m)]]
      for (k in seq_along(niveis[[m]])) {
        out[[paste0("voto_", g, "_", m, "_b", k)]] <- pp(sum(d$VOTOS_CAND_TOTAL[gi & fx == niveis[[m]][k]]), V)
      }
    }
  }
  as_tibble(out)
}
painel <- cand |>
  nest(.by = c(ANO, DS_CARGO, uf, partido_lista)) |>
  mutate(res = map(data, resumir)) |> select(-data) |> unnest(res) |>
  filter(votos_lista > 0) |>
  mutate(lista = paste(partido_lista, uf, DS_CARGO)) |>
  filter(n_distinct(ANO) == 3, .by = lista) |>                  # balanceado nas três eleições
  mutate(id = as.integer(factor(lista)), ano = as.integer(ANO),
         federal = DS_CARGO == "Deputado Federal", gname = if_else(federal, 2022L, 0L))
message("Painel 2014–2022: ", n_distinct(painel$id), " listas (", sum(painel$federal) / 3, " federais)")

# ------------------------------------------------------------------------------
# 3. Estimação: placebo (e = −1) e efeito (e = 0)
# ------------------------------------------------------------------------------
estimar <- function(y) {
  d <- painel |> filter(!is.na(.data[[y]])) |> filter(n() == 3, .by = id)
  a <- suppressWarnings(att_gt(yname = y, tname = "ano", idname = "id", gname = "gname", data = d,
                               panel = TRUE, control_group = "nevertreated", est_method = "dr",
                               base_period = "varying", bstrap = TRUE, cband = TRUE,
                               biters = biters, clustervars = "id", print_details = FALSE))
  ag <- aggte(a, type = "dynamic", bstrap = TRUE, cband = TRUE, biters = biters)
  # Checagem: placebo = DiD 2×2 de 2014 → 2018 (TWFE)
  tw <- feols(as.formula(paste(y, "~ I(federal & ano == 2018L) | id + ano")),
              data = filter(d, ano < 2022L), cluster = ~id)
  tibble(resultado = y, e = ag$egt, att = ag$att.egt, ep = ag$se.egt,
         ic_inf = att - 1.96 * ep, ic_sup = att + 1.96 * ep,
         twfe_placebo = unname(coef(tw)[1]), n_listas = n_distinct(d$id))
}
ys <- names(painel) |> keep(\(n) str_detect(n, "^(rec_|cand_viavel_|voto_)"))
res <- map(ys, estimar) |> list_rbind()
chk <- res |> filter(e < 0)            # e em anos: placebo = 2018 − 2022 = −4
stopifnot(nrow(chk) == length(ys), all(abs(chk$att - chk$twfe_placebo) < 1e-6))

res <- res |>
  mutate(periodo = if_else(e < 0, "Placebo: 2014 para 2018", "Efeito: 2018 para 2022"),
         grupo = if_else(str_detect(resultado, "mulher"), "Mulheres", "Negras/os"),
         medida = str_extract(resultado, "m\\d"),
         faixa_k = as.integer(str_extract(resultado, "(?<=_b)\\d")),
         faixa = map2_chr(medida, faixa_k, \(m, k) if (is.na(k)) NA_character_ else niveis[[m]][k]),
         rotulo = case_when(
           str_detect(resultado, "^voto_(mulher|negra)$") ~ "Votos da lista (total)",
           str_detect(resultado, "^rec_(mulher|negra)$") ~ "Recursos do partido (total)",
           str_detect(resultado, "^rec_viavel") ~ paste("Recursos para viáveis", medida),
           str_detect(resultado, "^cand_viavel") ~ paste("Candidaturas viáveis", medida),
           TRUE ~ paste0("Votos ", medida, " ", faixa)))
write_excel_csv2(res, file.path(out_dir, "did_placebo_2014.csv"))

# ------------------------------------------------------------------------------
# 4. Gráfico: placebo × efeito
# ------------------------------------------------------------------------------
cores_per <- c("Placebo: 2014 para 2018" = "#9a9890", "Efeito: 2018 para 2022" = "#104281")
d <- res |>
  filter(is.na(faixa_k) | medida == "m8") |>
  mutate(rotulo = fct_rev(fct_inorder(rotulo)), periodo = factor(periodo, levels = names(cores_per)))
p <- ggplot(d, aes(x = att, y = rotulo, colour = periodo)) +
  geom_vline(xintercept = 0, colour = "grey50", linewidth = 0.4) +
  geom_pointrange(aes(xmin = ic_inf, xmax = ic_sup), position = position_dodge(width = 0.6),
                  size = 0.3, linewidth = 0.6) +
  facet_wrap(~grupo, ncol = 2) +
  scale_colour_manual(values = cores_per, name = NULL) +
  labs(title = "Teste placebo: federal × estadual antes (2014 para 2018) e depois (2018 para 2022) da EC 111",
       subtitle = paste("Placebo ≈ 0 é consistente com tendências paralelas. m6 = recursos do partido;",
                        "m8 = gasto ÷ menor gasto dos eleitos (faixas de votos em m8)."),
       x = "Efeito estimado (pontos percentuais)", y = NULL,
       caption = paste("Fonte: TSE. DiD com 3 eleições (Callaway & Sant'Anna, pacote did, base variável);",
                       "listas partido × UF balanceadas nas três eleições, sem DF.\nBarras: IC 95%",
                       "(bootstrap, EP agrupados por lista). Em 2014, recursos do partido incluem doações",
                       "empresariais repassadas.")) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0), plot.title = element_text(face = "bold"),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.caption = element_text(colour = "grey40", hjust = 0), legend.position = "top")
ggsave(file.path(out_dir, "did_placebo_2014.png"), p, width = 11, height = 7, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "did_placebo_2014.pdf"), p, width = 11, height = 7)
message("Placebo 2014: resultados em ", out_dir)
