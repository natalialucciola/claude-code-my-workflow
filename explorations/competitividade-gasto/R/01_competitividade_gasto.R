# ==============================================================================
# Competitividade da candidatura medida pelo GASTO — Deputado Federal e Estadual,
# 2018 e 2022 (etapa 1: limites legais e distribuição do gasto)
#
# Pergunta de fundo: o aumento de votos das mulheres foi maior entre candidaturas
# mais ou menos competitivas — com competitividade definida pelo gasto, não pelo voto.
#
# Gasto da candidatura = despesas contratadas (prestação final do TSE), EXCLUINDO
# "Doações financeiras a outros candidatos/partidos" (repasses). Candidaturas aptas
# sem despesa entram com gasto 0.
#
# Medidas candidatas (para comparar Federal × Estadual):
#   (1) pct_teto  = gasto / limite legal do cargo no ano.
#       Atenção: para deputado o limite é o MESMO em todas as UFs
#       (2018: Lei 13.488/2017; 2022: Portaria TSE 647/2022 = 2018 + IPCA), logo
#       (1) normaliza entre cargos, mas NÃO entre UFs.
#   (2) razao_min = gasto / menor gasto entre os eleitos do mesmo ano × cargo × UF
#       (transposição de Wylie, dos Santos & Marcelino 2019 para o gasto);
#       razao_p10 = idem, com o p10 do gasto dos eleitos (menos sensível a outliers).
#   (3) pctl_uf   = percentil do gasto no ano × cargo × UF (robustez).
#
# Valores em R$ de 2022: 2018 corrigido pelo mesmo fator IPCA usado pelo TSE para
# atualizar os tetos (teto 2022 / teto 2018 = 1,2706).
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/competitividade-gasto/R/01_competitividade_gasto.R
#
# Entradas (data/raw/, copiadas do projeto de análise da tese — ver README):
#   prestacao_de_contas_eleitorais_candidatos_{2018,2022}.zip (TSE): despesas contratadas,
#     só cópias exatas removidas (regra de 2026-11-09; ver ler_prestacao em funcoes_apoio.R)
#   despesas_categorizadas_dep_{2018,2022}.rds  (base anterior, uma linha por SQ_DESPESA;
#     só para a conferência output/conferencia_regra_deduplicacao.csv)
#   candidatos{2018,2022}.rds, candidatos_estadual_{2018,2022}.rds
#   eleitos_e_compet_{2018,2022}_df.rds, eleitos_e_compet_est_{2018,2022}_df.rds
# Saídas:
#   data/processed/competitividade_gasto_cand.rds (uma linha por candidatura apta, sem CPF)
#   explorations/competitividade-gasto/output/*.csv, *.png, *.pdf
# ==============================================================================

library(data.table)
library(tidyverse)

source("explorations/competitividade-gasto/R/funcoes_apoio.R")
raw_dir  <- "data/raw"
proc_dir <- "data/processed"
out_dir  <- "explorations/competitividade-gasto/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(proc_dir, showWarnings = FALSE, recursive = TRUE)
rd <- function(arq) readRDS(file.path(raw_dir, arq)) |> as_tibble() |> ungroup()

anos   <- c("2018", "2022")
cargos <- c("Deputado Federal", "Deputado Estadual")
origem_repasse <- "Doações financeiras a outros candidatos/partidos"

# ------------------------------------------------------------------------------
# 1. Limites legais de gasto (iguais em todas as UFs para deputado)
# ------------------------------------------------------------------------------
tetos <- tribble(
  ~ANO,   ~DS_CARGO,           ~teto,       ~fonte,
  "2018", "Deputado Federal",  2500000.00,  "Lei 13.488/2017",
  "2018", "Deputado Estadual", 1000000.00,  "Lei 13.488/2017",
  "2022", "Deputado Federal",  3176572.53,  "Portaria TSE 647/2022 (2018 + IPCA)",
  "2022", "Deputado Estadual", 1270629.01,  "Portaria TSE 647/2022 (2018 + IPCA)"
) |>
  mutate(fator_2022 = teto[ANO == "2022"] / teto, .by = DS_CARGO)   # 1,2706 para 2018
write_excel_csv2(tetos, file.path(out_dir, "limites_gasto_cargo_ano.csv"))

# ------------------------------------------------------------------------------
# 2. Gasto por candidatura (bruto, repasses e líquido)
# ------------------------------------------------------------------------------
# Desde 2026-11-09 (decisão da autora): despesas lidas direto da prestação de contas do
# TSE, removendo só as linhas idênticas em todas as colunas (ler_prestacao, em
# funcoes_apoio.R). A base anterior (despesas_categorizadas_dep_{ano}.rds) mantinha uma
# linha por SQ_DESPESA e descartava itens distintos do mesmo documento (~20% do gasto).
desp <- map(anos, function(a) {
  x <- ler_prestacao(file.path(raw_dir, paste0("prestacao_de_contas_eleitorais_candidatos_", a, ".zip")),
                     paste0("despesas_contratadas_candidatos_", a, "_BRASIL.csv"), cargos)
  message(a, ": ", attr(x, "copias_exatas"), " cópias exatas removidas")
  as_tibble(x[, .(ANO = a, DS_CARGO, SQ_CANDIDATO, DS_ORIGEM_DESPESA,
                  VR_DESPESA_CONTRATADA = as.numeric(sub(",", ".", VR_DESPESA_CONTRATADA, fixed = TRUE)))])
}) |> list_rbind()
conf_regra <- map(anos, \(a) rd(paste0("despesas_categorizadas_dep_", a, ".rds")) |>
                    summarise(regra_antiga_mi = sum(VR_DESPESA_CONTRATADA, na.rm = TRUE) / 1e6,
                              .by = DS_CARGO) |> mutate(ANO = a)) |>
  list_rbind() |>
  left_join(desp |> summarise(regra_nova_mi = sum(VR_DESPESA_CONTRATADA, na.rm = TRUE) / 1e6,
                              .by = c(ANO, DS_CARGO)), by = c("ANO", "DS_CARGO"))
write_excel_csv2(conf_regra, file.path(out_dir, "conferencia_regra_deduplicacao.csv"))
print(conf_regra)
gasto <- desp |>
  summarise(gasto_bruto = sum(VR_DESPESA_CONTRATADA, na.rm = TRUE),
            repasse     = sum(VR_DESPESA_CONTRATADA[DS_ORIGEM_DESPESA == origem_repasse],
                              na.rm = TRUE),
            .by = c(ANO, DS_CARGO, SQ_CANDIDATO)) |>
  mutate(gasto = gasto_bruto - repasse)

# ------------------------------------------------------------------------------
# 3. Candidaturas aptas + resultado
#    (linhas de voto de legenda, com sq_candidato = número do partido, caem no join)
# ------------------------------------------------------------------------------
arq_cand <- function(ano, cargo) {
  if (cargo == "Deputado Federal") paste0("candidatos", ano, ".rds")
  else paste0("candidatos_estadual_", ano, ".rds")
}
arq_res <- function(ano, cargo) {
  if (cargo == "Deputado Federal") paste0("eleitos_e_compet_", ano, "_df.rds")
  else paste0("eleitos_e_compet_est_", ano, "_df.rds")
}

base <- expand_grid(ANO = anos, DS_CARGO = cargos) |>
  pmap(function(ANO, DS_CARGO) {
    res <- rd(arq_res(ANO, DS_CARGO)) |>
      select(sq_candidato, SG_UF, VOTOS_CAND_TOTAL, QE, competitivo, eleito)
    rd(arq_cand(ANO, DS_CARGO)) |>
      filter(situacao_candidatura == "APTO", genero %in% c("FEMININO", "MASCULINO")) |>
      select(sq_candidato, genero, raca, uf, partido) |>
      inner_join(res, by = c("sq_candidato", "uf" = "SG_UF")) |>
      mutate(ANO = ANO, DS_CARGO = DS_CARGO)
  }) |>
  list_rbind() |>
  left_join(gasto, by = c("ANO", "DS_CARGO", "sq_candidato" = "SQ_CANDIDATO")) |>
  mutate(across(c(gasto_bruto, repasse, gasto), \(x) replace_na(x, 0)),
         sem_despesa  = gasto_bruto == 0,
         partido_harm = harmonizar_partido_2026(partido),
         raca2        = raca2(raca),
         compet_voto  = as.integer(competitivo == 1 | eleito == 1),
         resultado    = factor(case_when(eleito == 1 ~ "Eleito/a",
                                         compet_voto == 1 ~ "Competitivo/a não eleito/a",
                                         TRUE ~ "Não competitivo/a"),
                               levels = c("Eleito/a", "Competitivo/a não eleito/a",
                                          "Não competitivo/a")),
         genero       = if_else(genero == "FEMININO", "Mulheres", "Homens")) |>
  left_join(tetos |> select(ANO, DS_CARGO, teto, fator_2022), by = c("ANO", "DS_CARGO")) |>
  mutate(gasto_real = gasto * fator_2022,
         pct_teto   = 100 * gasto / teto)

# Checagem: uma linha por candidatura
stopifnot(!anyDuplicated(base[c("ANO", "DS_CARGO", "sq_candidato")]))

# ------------------------------------------------------------------------------
# 4. Medidas relativas à disputa (ano × cargo × UF)
# ------------------------------------------------------------------------------
ref_uf <- base |>
  summarise(n_cand         = n(),
            n_eleitos      = sum(eleito == 1),
            eleitos_gasto0 = sum(eleito == 1 & gasto == 0),
            min_eleito     = min(gasto[eleito == 1]),
            p10_eleito     = quantile(gasto[eleito == 1], .10, names = FALSE),
            med_eleito     = median(gasto[eleito == 1]),
            med_todos      = median(gasto),
            pct_sem_desp   = 100 * mean(sem_despesa),
            .by = c(ANO, DS_CARGO, uf)) |>
  left_join(tetos |> select(ANO, DS_CARGO, teto), by = c("ANO", "DS_CARGO")) |>
  mutate(across(c(min_eleito, p10_eleito, med_eleito, med_todos),
                \(x) 100 * x / teto, .names = "{.col}_pct_teto"))
write_excel_csv2(ref_uf, file.path(out_dir, "referencias_gasto_eleitos_por_uf.csv"))

base <- base |>
  left_join(ref_uf |> select(ANO, DS_CARGO, uf, min_eleito, p10_eleito, med_eleito),
            by = c("ANO", "DS_CARGO", "uf")) |>
  mutate(razao_min = if_else(min_eleito > 0, gasto / min_eleito, NA_real_),
         razao_p10 = if_else(p10_eleito > 0, gasto / p10_eleito, NA_real_),
         pctl_uf   = 100 * percent_rank(gasto), .by = c(ANO, DS_CARGO, uf))
saveRDS(base, file.path(proc_dir, "competitividade_gasto_cand.rds"))

# ------------------------------------------------------------------------------
# 5. Descritivos da distribuição do gasto
# ------------------------------------------------------------------------------
resumo_dist <- function(d, v) {
  summarise(d, n = n(), pct_sem_despesa = 100 * mean(sem_despesa),
            media = mean(.data[[v]]),
            p10 = quantile(.data[[v]], .10), p25 = quantile(.data[[v]], .25),
            p50 = median(.data[[v]]), p75 = quantile(.data[[v]], .75),
            p90 = quantile(.data[[v]], .90), max = max(.data[[v]]),
            .by = c(ANO, DS_CARGO, resultado, genero)) |>
    arrange(DS_CARGO, ANO, resultado, genero)
}
write_excel_csv2(resumo_dist(base, "gasto_real"),
                 file.path(out_dir, "dist_gasto_real2022_resultado_genero.csv"))
write_excel_csv2(resumo_dist(base, "pct_teto"),
                 file.path(out_dir, "dist_pct_teto_resultado_genero.csv"))

# Repasses a outras candidaturas: quem repassa e quanto
repasses <- base |>
  summarise(n = n(), pct_com_repasse = 100 * mean(repasse > 0),
            repasse_total_mi_2022 = sum(repasse * fator_2022) / 1e6,
            pct_do_gasto_bruto = 100 * sum(repasse) / sum(gasto_bruto),
            med_share_repasse = 100 * median((repasse / gasto_bruto)[repasse > 0]),
            .by = c(ANO, DS_CARGO, genero, resultado)) |>
  arrange(DS_CARGO, ANO, genero, resultado)
write_excel_csv2(repasses, file.path(out_dir, "repasses_outros_candidatos.csv"))

# ------------------------------------------------------------------------------
# 6. Concordância entre patamares de gasto e competitividade pelo voto
#    sensibilidade  = % das competitivas pelo voto (≥ 10% QE ou eleitas) acima do patamar
#    especificidade = % das não competitivas pelo voto abaixo do patamar
# ------------------------------------------------------------------------------
patamares <- bind_rows(
  tibble(medida = "pct_teto",  corte = c(.5, 1, 2, 5, 10, 20)),
  tibble(medida = "razao_min", corte = c(.1, .25, .5, 1)),
  tibble(medida = "razao_p10", corte = c(.1, .25, .5, 1)),
  tibble(medida = "pctl_uf",   corte = c(50, 75, 90))
)
concordancia <- pmap(patamares, function(medida, corte) {
  base |>
    filter(!is.na(.data[[medida]])) |>
    mutate(acima = .data[[medida]] >= corte) |>
    summarise(pct_acima          = 100 * mean(acima),
              sensibilidade      = 100 * mean(acima[compet_voto == 1]),
              especificidade     = 100 * mean(!acima[compet_voto == 0]),
              pct_mulheres_acima = 100 * mean(genero[acima] == "Mulheres"),
              sens_mulheres      = 100 * mean(acima[compet_voto == 1 & genero == "Mulheres"]),
              sens_homens        = 100 * mean(acima[compet_voto == 1 & genero == "Homens"]),
              .by = c(ANO, DS_CARGO)) |>
    mutate(medida = medida, corte = corte, .before = 1)
}) |> list_rbind() |>
  arrange(medida, corte, DS_CARGO, ANO)
write_excel_csv2(concordancia, file.path(out_dir, "concordancia_patamares_gasto_voto.csv"))

# ------------------------------------------------------------------------------
# 7. Gráficos
# ------------------------------------------------------------------------------
cores_res <- c("Eleito/a" = "#104281", "Competitivo/a não eleito/a" = "#2a78d6",
               "Não competitivo/a" = "#86b6ef")
cores_gen <- c("Mulheres" = "#eb6834", "Homens" = "#2a78d6")   # convenção: laranja = F, azul = M
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(colour = "grey40", hjust = 0),
        legend.position = "top")
fonte <- paste("Fonte: TSE, prestação de contas final (despesas contratadas, sem repasses",
               "a outras candidaturas) e resultados.")
lab_pct <- \(x) paste0(format(x, big.mark = ".", decimal.mark = ",", drop0trailing = TRUE,
                              trim = TRUE, scientific = FALSE), "%")
salvar <- function(p, nome, w, h) {
  ggsave(file.path(out_dir, paste0(nome, ".png")), p, width = w, height = h, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, paste0(nome, ".pdf")), p, width = w, height = h)
}
base_pos <- base |> filter(gasto > 0) |> mutate(cargo_ano = paste(DS_CARGO, ANO))
lbl_sem <- base |>
  summarise(sem = sprintf("%.0f%% sem despesa", 100 * mean(sem_despesa)), .by = c(DS_CARGO, ANO)) |>
  mutate(cargo_ano = paste(DS_CARGO, ANO))

# 7a. Distribuição do % do teto por resultado
p <- ggplot(base_pos, aes(x = pct_teto, colour = resultado)) +
  geom_density(linewidth = 0.7, adjust = 1.2) +
  geom_vline(xintercept = c(1, 10), linetype = "dashed", colour = "grey60", linewidth = 0.3) +
  geom_text(data = lbl_sem, aes(x = Inf, y = Inf, label = sem), inherit.aes = FALSE,
            hjust = 1.05, vjust = 1.5, size = 3, colour = "grey30") +
  scale_x_log10(labels = lab_pct, breaks = c(.01, .1, 1, 10, 100)) +
  facet_wrap(~cargo_ano, ncol = 2) +
  scale_colour_manual(values = cores_res, name = NULL) +
  labs(title = "Gasto da candidatura em % do limite legal, por resultado eleitoral",
       subtitle = "Candidaturas aptas com gasto > 0 (escala log). Linhas tracejadas: 1% e 10% do limite.",
       x = "Gasto (% do limite legal do cargo)", y = "Densidade", caption = fonte) + tema
salvar(p, "dens_pct_teto_resultado", 10, 7)

# 7b. Mesmo, por gênero, dentro de cada resultado
p <- ggplot(base_pos, aes(x = pct_teto, y = resultado, fill = genero)) +
  geom_boxplot(outlier.shape = NA, width = 0.6, linewidth = 0.3,
               position = position_dodge(width = 0.7)) +
  scale_x_log10(labels = lab_pct, breaks = c(.01, .1, 1, 10, 100)) +
  facet_wrap(~cargo_ano, ncol = 2) +
  scale_fill_manual(values = cores_gen, name = NULL) +
  labs(title = "Gasto em % do limite legal — mulheres × homens, por resultado",
       subtitle = "Caixas: p25–p75 e mediana; candidaturas com gasto > 0 (escala log).",
       x = "Gasto (% do limite legal do cargo)", y = NULL, caption = fonte) + tema
salvar(p, "box_pct_teto_genero_resultado", 10, 7)

# 7c. Variação entre UFs do gasto dos eleitos (por que o % do teto não basta)
d_uf <- ref_uf |>
  mutate(cargo_ano = paste(DS_CARGO, ANO), uf = fct_reorder(uf, med_eleito_pct_teto)) |>
  select(cargo_ano, uf, `Menor gasto entre eleitos` = min_eleito_pct_teto,
         `p10 dos eleitos` = p10_eleito_pct_teto, `Mediana dos eleitos` = med_eleito_pct_teto) |>
  pivot_longer(-c(cargo_ano, uf), names_to = "ref", values_to = "v") |>
  mutate(ref = factor(ref, levels = c("Menor gasto entre eleitos", "p10 dos eleitos",
                                      "Mediana dos eleitos")))
p <- ggplot(d_uf, aes(x = v, y = uf, colour = ref)) +
  geom_line(aes(group = uf), colour = "grey80", linewidth = 0.4) +
  geom_point(size = 1.8) +
  facet_wrap(~cargo_ano, ncol = 4) +
  scale_colour_manual(values = c("#86b6ef", "#2a78d6", "#104281"), name = NULL) +
  labs(title = "Quanto gastam os eleitos em cada UF, em % do limite legal",
       subtitle = paste("O limite é igual em todas as UFs; a variação mostra que o % do limite,",
                        "sozinho, não compara UFs."),
       x = "% do limite legal do cargo", y = NULL, caption = fonte) + tema
salvar(p, "gasto_eleitos_por_uf", 12, 7.5)

# 7d. Sensibilidade × falsos positivos dos patamares (escolha do corte)
p <- concordancia |>
  filter(medida != "pctl_uf") |>
  mutate(medida = case_match(medida, "pct_teto" ~ "% do limite legal",
                             "razao_min" ~ "÷ menor gasto dos eleitos (UF)",
                             "razao_p10" ~ "÷ p10 dos eleitos (UF)"),
         cargo_ano = paste(DS_CARGO, ANO)) |>
  ggplot(aes(x = 100 - especificidade, y = sensibilidade, colour = medida)) +
  geom_abline(linetype = "dashed", colour = "grey70", linewidth = 0.3) +
  geom_path(linewidth = 0.5) + geom_point(size = 2) +
  geom_text(aes(label = corte), size = 2.6, vjust = -0.9, show.legend = FALSE) +
  facet_wrap(~cargo_ano, ncol = 2) +
  scale_colour_manual(values = c("#2a78d6", "#eb6834", "#1baf7a"), name = NULL) +
  coord_cartesian(xlim = c(0, 100), ylim = c(0, 100)) +
  labs(title = "Patamares de gasto × competitividade pelo voto (≥ 10% do QE ou eleita/o)",
       subtitle = paste("Cada ponto é um corte (rótulo). Canto superior esquerdo = patamar que",
                        "separa bem as candidaturas competitivas."),
       x = "Falsos positivos: % das não competitivas acima do patamar",
       y = "% das competitivas acima do patamar", caption = fonte) + tema
salvar(p, "concordancia_patamares", 10, 8)

message("Competitividade pelo gasto: resultados em ", out_dir)
