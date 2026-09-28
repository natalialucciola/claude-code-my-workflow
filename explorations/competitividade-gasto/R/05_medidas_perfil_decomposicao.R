# ==============================================================================
# Três medidas de competitividade pelo gasto, perfil de gênero/raça por faixa e
# decomposição do ganho de votos (composição × rendimento) — 2018 × 2022,
# Deputado Federal (tratado: votos em dobro, EC 111/2021) × Estadual (controle)
#
# Medidas (plano: quality_reports/plans/2026-09-28_competitividade-gasto-did.md)
#   m2  % do limite legal            viável: ≥ 5%
#   m6  recursos do partido ÷ divisão igualitária entre as candidaturas do partido
#       no cargo e UF                 viável: ≥ 1×
#   m8  gasto ÷ menor gasto entre eleitos da UF (excluídos eleitos com gasto < 1%
#       do limite)                    viável: ≥ 0,5×
#
# Decomposição (nacional, por cargo e ano; g = mulheres ou negras/os):
#   participação de g nos votos  V = Σ_b p_b · r_b
#     p_b = candidaturas de g na faixa b ÷ total de candidaturas   (composição)
#     r_b = (votos de g na faixa b ÷ votos totais) ÷ p_b          (rendimento relativo)
#   ΔV = Σ Δp_b · r̄_b  +  Σ p̄_b · Δr_b   (médias entre anos → decomposição exata)
#
# Rodar da raiz, depois dos scripts 01 e 04:
#   Rscript explorations/competitividade-gasto/R/05_medidas_perfil_decomposicao.R
# Saídas: data/processed/base_did_candidatos.rds (sem CPF; não versionado)
#         output/perfil_faixas_*.csv/png, decomposicao_*.csv/png
# ==============================================================================

library(tidyverse)

source("explorations/competitividade-gasto/R/funcoes_apoio.R")
out_dir <- "explorations/competitividade-gasto/output"

niveis <- list(
  m2 = c("< 1%", "1–5%", "5–10%", "10–25%", "≥ 25%"),
  m6 = c("Não recebeu", "< 0,5×", "0,5–1×", "1–5×", "≥ 5×"),
  m8 = c("< 10%", "10–25%", "25–50%", "50–100%", "≥ 100%")
)
niveis_plot <- unlist(imap(niveis, \(v, m) paste(m, v)), use.names = FALSE)   # únicos por medida
sem_prefixo <- \(x) sub("^m\\d ", "", x)
rotulo_medida <- c(m2 = "% do limite legal", m6 = "Recursos do partido",
                   m8 = "÷ menor gasto dos eleitos")

# ------------------------------------------------------------------------------
# 1. Base de candidaturas com as três medidas
# ------------------------------------------------------------------------------
rec <- readRDS("data/processed/receitas_cand_dep.rds") |>
  select(ANO, DS_CARGO, sq_candidato = SQ_CANDIDATO, receita_partido, partido_fefc, partido_fp)

cand <- readRDS("data/processed/competitividade_gasto_cand.rds") |>
  filter(uf != "DF") |>                                   # DF não tem eleição estadual (controle)
  left_join(rec, by = c("ANO", "DS_CARGO", "sq_candidato")) |>
  mutate(across(c(receita_partido, partido_fefc, partido_fp), \(x) replace_na(x, 0)),
         partido_lista = if_else(partido %in% names(partido_map_2018_2022),
                                 unname(partido_map_2018_2022[partido]), partido),
         mulher = genero == "Mulheres",
         negra  = raca2 == "NEGRA",
         federal = DS_CARGO == "Deputado Federal")

# m6: parcela dos recursos que o partido (sigla do ano) repassou às suas candidaturas do cargo e UF
cand <- cand |>
  mutate(n_partido = n(), rec_partido_tot = sum(receita_partido),
         m6 = if_else(rec_partido_tot > 0, receita_partido / rec_partido_tot * n_partido, 0),
         .by = c(ANO, DS_CARGO, uf, partido))

# m8: referência = menor gasto entre eleitos com gasto ≥ 1% do limite
ref8 <- cand |>
  filter(eleito == 1, pct_teto >= 1) |>
  summarise(min_eleito_real = min(gasto), .by = c(ANO, DS_CARGO, uf))
cand <- cand |>
  left_join(ref8, by = c("ANO", "DS_CARGO", "uf")) |>
  mutate(m2 = pct_teto,
         m8 = gasto / min_eleito_real,
         faixa_m2 = cut(m2, c(-Inf, 1, 5, 10, 25, Inf), right = FALSE, labels = niveis$m2),
         faixa_m6 = factor(case_when(m6 <= 0 ~ niveis$m6[1], m6 < .5 ~ niveis$m6[2],
                                     m6 < 1 ~ niveis$m6[3], m6 < 5 ~ niveis$m6[4],
                                     TRUE ~ niveis$m6[5]), levels = niveis$m6),
         faixa_m8 = cut(m8, c(-Inf, .10, .25, .50, 1, Inf), right = FALSE, labels = niveis$m8),
         viavel_m2 = m2 >= 5, viavel_m6 = m6 >= 1, viavel_m8 = m8 >= .5)
stopifnot(!anyNA(cand$faixa_m2), !anyNA(cand$faixa_m6), !anyNA(cand$faixa_m8))
saveRDS(cand, "data/processed/base_did_candidatos.rds")

# ------------------------------------------------------------------------------
# 2. Perfil: % de mulheres / negras/os em cada faixa, por cargo e ano
# ------------------------------------------------------------------------------
longo <- cand |>
  select(ANO, DS_CARGO, mulher, negra, VOTOS_CAND_TOTAL, faixa_m2, faixa_m6, faixa_m8) |>
  pivot_longer(starts_with("faixa_"), names_to = "medida", values_to = "faixa",
               names_prefix = "faixa_") |>
  mutate(faixa = as.character(faixa))

perfil <- longo |>
  summarise(n = n(), pct_mulheres = 100 * mean(mulher), pct_negras = 100 * mean(negra),
            .by = c(medida, DS_CARGO, ANO, faixa)) |>
  mutate(pct_das_candidaturas = 100 * n / sum(n), .by = c(medida, DS_CARGO, ANO)) |>
  arrange(medida, DS_CARGO, faixa, ANO)
write_excel_csv2(perfil, file.path(out_dir, "perfil_faixas_genero_raca.csv"))

# ------------------------------------------------------------------------------
# 3. Decomposição do ganho de votos: composição × rendimento
# ------------------------------------------------------------------------------
decompor <- function(grupo) {
  longo |>
    mutate(g = .data[[grupo]]) |>
    mutate(N = n(), V = sum(VOTOS_CAND_TOTAL), .by = c(medida, DS_CARGO, ANO)) |>
    summarise(p = sum(g) / first(N), share = sum(VOTOS_CAND_TOTAL[g]) / first(V),
              .by = c(medida, DS_CARGO, ANO, faixa)) |>
    mutate(r = if_else(p > 0, share / p, NA_real_)) |>
    pivot_wider(names_from = ANO, values_from = c(p, share, r)) |>
    mutate(across(c(p_2018, p_2022, share_2018, share_2022), \(x) replace_na(x, 0)),
           # faixa vazia em um ano: usa o rendimento do outro ano (contribui só via composição)
           r_2018 = coalesce(r_2018, r_2022, 0), r_2022 = coalesce(r_2022, r_2018, 0),
           composicao = 100 * (p_2022 - p_2018) * (r_2018 + r_2022) / 2,
           rendimento = 100 * (p_2018 + p_2022) / 2 * (r_2022 - r_2018),
           total      = 100 * (share_2022 - share_2018),
           grupo = if_else(grupo == "mulher", "Mulheres", "Negras/os"))
}
decomp <- bind_rows(decompor("mulher"), decompor("negra"))
# Checagem: composição + rendimento = variação total em cada faixa (decomposição exata)
stopifnot(all(abs(decomp$composicao + decomp$rendimento - decomp$total) < 1e-8))
write_excel_csv2(decomp, file.path(out_dir, "decomposicao_composicao_rendimento.csv"))

# Diferença federal − estadual de cada componente (parte "adicional" do federal)
decomp_dif <- decomp |>
  select(grupo, medida, DS_CARGO, faixa, composicao, rendimento, total) |>
  pivot_longer(c(composicao, rendimento, total), names_to = "componente") |>
  pivot_wider(names_from = DS_CARGO, values_from = value) |>
  mutate(dif_federal_menos_estadual = `Deputado Federal` - `Deputado Estadual`)
write_excel_csv2(decomp_dif, file.path(out_dir, "decomposicao_diferenca_federal_estadual.csv"))

# ------------------------------------------------------------------------------
# 4. Gráficos
# ------------------------------------------------------------------------------
cores_ano  <- c("2018" = "#86b6ef", "2022" = "#104281")
cores_comp <- c("Composição (mais candidaturas na faixa)" = "#2a78d6",
                "Rendimento (mais votos por candidatura)" = "#eb6834")
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_text(colour = "grey40", hjust = 0), legend.position = "top")
fonte <- "Fonte: TSE (candidaturas, resultados, prestação de contas final). Sem DF."
salvar <- function(p, nome, w, h) {
  ggsave(file.path(out_dir, paste0(nome, ".png")), p, width = w, height = h, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, paste0(nome, ".pdf")), p, width = w, height = h)
}

for (v in c("pct_mulheres", "pct_negras")) {
  rot <- if (v == "pct_mulheres") "mulheres" else "negras/os"
  d <- perfil |>
    mutate(faixa = factor(paste(medida, faixa), levels = niveis_plot),
           medida = factor(rotulo_medida[medida], levels = rotulo_medida),
           DS_CARGO = factor(DS_CARGO, levels = c("Deputado Federal", "Deputado Estadual")))
  p <- ggplot(d, aes(x = .data[[v]], y = fct_rev(faixa))) +
    geom_line(aes(group = faixa), colour = "grey75", linewidth = 0.5) +
    geom_point(aes(colour = ANO, shape = ANO), size = 2.4, fill = "white", stroke = 1) +
    facet_grid(medida ~ DS_CARGO, scales = "free_y", space = "free_y") +
    scale_y_discrete(labels = sem_prefixo) +
    scale_colour_manual(values = cores_ano, name = NULL) +
    scale_shape_manual(values = c("2018" = 21, "2022" = 16), name = NULL) +
    scale_x_continuous(labels = \(x) paste0(x, "%")) +
    labs(title = paste0("Perfil das faixas de competitividade pelo gasto — % de ", rot),
         subtitle = paste0("% de ", rot, " entre as candidaturas de cada faixa, 2018 × 2022. ",
                           "Faixas de baixo para cima: menos para mais competitiva."),
         x = paste0("% de ", rot, " na faixa"), y = NULL, caption = fonte) + tema
  salvar(p, paste0("perfil_faixas_", if (v == "pct_mulheres") "genero" else "raca"), 10, 8)
}

for (gr in c("Mulheres", "Negras/os")) {
  d <- decomp |>
    filter(grupo == gr) |>
    select(medida, DS_CARGO, faixa, composicao, rendimento) |>
    pivot_longer(c(composicao, rendimento), names_to = "componente") |>
    mutate(componente = if_else(componente == "composicao", names(cores_comp)[1], names(cores_comp)[2]),
           faixa = factor(paste(medida, faixa), levels = niveis_plot),
           medida = factor(rotulo_medida[medida], levels = rotulo_medida),
           DS_CARGO = factor(DS_CARGO, levels = c("Deputado Federal", "Deputado Estadual")))
  tot <- decomp |> filter(grupo == gr) |>
    summarise(t = sum(total), .by = c(medida, DS_CARGO)) |>
    mutate(lab = sprintf("Variação total: %+.1f pp", t),
           medida = factor(rotulo_medida[medida], levels = rotulo_medida),
           DS_CARGO = factor(DS_CARGO, levels = c("Deputado Federal", "Deputado Estadual")))
  p <- ggplot(d, aes(x = value, y = fct_rev(faixa), fill = componente)) +
    geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.4) +
    geom_col(position = position_dodge(width = 0.75), width = 0.7) +
    geom_text(data = tot, aes(x = Inf, y = Inf, label = lab), inherit.aes = FALSE,
              hjust = 1.05, vjust = 1.4, size = 2.9, fontface = "bold", colour = "grey20") +
    facet_grid(medida ~ DS_CARGO, scales = "free_y", space = "free_y") +
    scale_y_discrete(labels = sem_prefixo) +
    scale_fill_manual(values = cores_comp, name = NULL) +
    labs(title = paste0("De onde veio a variação da participação de ", str_to_lower(gr),
                        " nos votos, de 2018 para 2022"),
         subtitle = paste0("Contribuição de cada faixa (pontos percentuais dos votos nominais), ",
                           "separada em composição e rendimento.\nFaixas de baixo para cima: ",
                           "menos para mais competitiva."),
         x = "Contribuição (pp)", y = NULL, caption = fonte) + tema
  salvar(p, paste0("decomposicao_", if (gr == "Mulheres") "genero" else "raca"), 10, 8.5)
}

message("Medidas, perfil e decomposição: resultados em ", out_dir)
