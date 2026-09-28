# ==============================================================================
# De onde veio o crescimento da votação das mulheres (2018 → 2022)?
# Das que gastaram mais / se aproximaram do patamar de gasto dos eleitos?
#
# Medida de voto: participação nos votos nominais do cargo (soma nacional das UFs),
# para comparar anos com eleitorados diferentes. share_i = votos_i / votos nominais
# de todas as candidaturas aptas do cargo no ano.
#
# Faixas de gasto (razao_p10 = gasto ÷ p10 do gasto dos eleitos da UF, cargo, ano):
#   sem despesa | < 0,1× | 0,1–0,5× | 0,5–1× | ≥ 1×
#
# (A) Composição: quanto da votação das mulheres vem de cada faixa, 2018 × 2022.
# (B) Decomposição da variação (pp) da participação das mulheres no voto:
#     novas (só 2022) − saíram (só 2018) + permaneceram (mesmo CPF e cargo nos dois
#     anos), estas separadas pela trajetória em relação ao patamar de 0,5×.
#     Mesma decomposição para homens e por raça, como comparação.
#
# Rodar a partir da raiz do repositório, depois do script 01:
#   Rscript explorations/competitividade-gasto/R/03_voto_por_faixa_gasto.R
# ==============================================================================

library(tidyverse)

out_dir <- "explorations/competitividade-gasto/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
patamar <- 0.5

niveis_faixa <- c("Sem despesa", "< 0,1×", "0,1–0,5×", "0,5–1×", "≥ 1×")
faixa_gasto <- function(gasto, r) {
  factor(case_when(gasto <= 0 ~ "Sem despesa",
                   r < 0.1 ~ "< 0,1×",
                   r < patamar ~ "0,1–0,5×",
                   r < 1 ~ "0,5–1×",
                   TRUE ~ "≥ 1×"), levels = niveis_faixa)
}

# CPF só para parear candidaturas entre anos — fica em memória, não é salvo
cpfs <- expand_grid(ANO = c("2018", "2022"), DS_CARGO = c("Deputado Federal", "Deputado Estadual")) |>
  pmap(function(ANO, DS_CARGO) {
    arq <- if (DS_CARGO == "Deputado Federal") paste0("candidatos", ANO, ".rds")
           else paste0("candidatos_estadual_", ANO, ".rds")
    readRDS(file.path("data/raw", arq)) |> as_tibble() |>
      filter(situacao_candidatura == "APTO") |>
      transmute(ANO = ANO, DS_CARGO = DS_CARGO, sq_candidato, cpfCand)
  }) |> list_rbind()

base <- readRDS("data/processed/competitividade_gasto_cand.rds") |>
  filter(!is.na(razao_p10)) |>
  left_join(cpfs, by = c("ANO", "DS_CARGO", "sq_candidato")) |>
  mutate(faixa    = faixa_gasto(gasto, razao_p10),
         raca     = case_match(raca2, "NEGRA" ~ "Negras/os", "BRANCA" ~ "Brancas/os", .default = "Outra"),
         DS_CARGO = factor(DS_CARGO, levels = c("Deputado Federal", "Deputado Estadual"))) |>
  mutate(share = 100 * VOTOS_CAND_TOTAL / sum(VOTOS_CAND_TOTAL), .by = c(ANO, DS_CARGO))

# ------------------------------------------------------------------------------
# (A) Composição da votação por faixa de gasto
# ------------------------------------------------------------------------------
comp <- base |>
  summarise(n = n(), share_votos = sum(share), eleitos = sum(eleito),
            votos_qe_mediana = median(VOTOS_CAND_TOTAL / QE),
            .by = c(ANO, DS_CARGO, genero, faixa)) |>
  complete(ANO, DS_CARGO, genero, faixa, fill = list(n = 0L, share_votos = 0, eleitos = 0)) |>
  mutate(pct_da_votacao_do_grupo = 100 * share_votos / sum(share_votos), .by = c(ANO, DS_CARGO, genero)) |>
  arrange(DS_CARGO, genero, faixa, ANO)
write_excel_csv2(comp, file.path(out_dir, "votacao_por_faixa_gasto_genero.csv"))

variacao_faixa <- comp |>
  select(ANO, DS_CARGO, genero, faixa, n, share_votos) |>
  pivot_wider(names_from = ANO, values_from = c(n, share_votos)) |>
  mutate(delta_share_pp = share_votos_2022 - share_votos_2018)
write_excel_csv2(variacao_faixa, file.path(out_dir, "variacao_votacao_por_faixa_gasto.csv"))

# ------------------------------------------------------------------------------
# (B) Decomposição: novas, saíram, permaneceram (por trajetória no patamar)
# ------------------------------------------------------------------------------
decompor <- function(d, grupo_var) {
  largo <- d |>
    filter(!is.na(cpfCand), !cpfCand %in% c("-4", "-1", "")) |>
    select(ANO, DS_CARGO, cpfCand, g = all_of(grupo_var), share, razao_p10, gasto) |>
    # mesmo CPF no mesmo cargo e ano deveria ser único; por segurança, soma
    summarise(g = first(g), share = sum(share), acima = first(razao_p10 >= patamar),
              .by = c(ANO, DS_CARGO, cpfCand)) |>
    pivot_wider(names_from = ANO, values_from = c(g, share, acima))
  largo |>
    mutate(g = coalesce(g_2022, g_2018),
           componente = case_when(
             is.na(share_2018) ~ "Novas candidaturas (só 2022)",
             is.na(share_2022) ~ "Saíram (só 2018)",
             !acima_2018 & acima_2022 ~ "Permaneceram: cruzaram o patamar",
             acima_2018 & acima_2022 ~ "Permaneceram: acima nos dois anos",
             !acima_2018 & !acima_2022 ~ "Permaneceram: abaixo nos dois anos",
             TRUE ~ "Permaneceram: caíram abaixo do patamar"),
           delta = coalesce(share_2022, 0) - coalesce(share_2018, 0)) |>
    summarise(n = n(), delta_pp = sum(delta),
              share_2018 = sum(share_2018, na.rm = TRUE), share_2022 = sum(share_2022, na.rm = TRUE),
              .by = c(DS_CARGO, g, componente)) |>
    mutate(recorte = grupo_var, .before = 1)
}
decomp <- bind_rows(decompor(base, "genero"),
                    decompor(filter(base, raca != "Outra"), "raca"),
                    decompor(filter(base, raca != "Outra") |>
                               mutate(gr = paste(genero, str_to_lower(raca))), "gr")) |>
  mutate(recorte = case_match(recorte, "genero" ~ "gênero", "raca" ~ "raça", "gr" ~ "gênero × raça")) |>
  arrange(recorte, DS_CARGO, g, componente)
write_excel_csv2(decomp, file.path(out_dir, "decomposicao_variacao_votacao.csv"))

# Novas candidaturas de 2022 (CPF ausente no mesmo cargo em 2018): votos por faixa de gasto
cpf_2018 <- base |> filter(ANO == "2018", !is.na(cpfCand)) |> distinct(DS_CARGO, cpfCand)
novas <- base |>
  filter(ANO == "2022", !is.na(cpfCand)) |>
  anti_join(cpf_2018, by = c("DS_CARGO", "cpfCand")) |>
  summarise(n = n(), share_votos = sum(share), eleitos = sum(eleito), .by = c(DS_CARGO, genero, faixa)) |>
  mutate(pct_da_votacao_das_novas = 100 * share_votos / sum(share_votos), .by = c(DS_CARGO, genero)) |>
  arrange(DS_CARGO, genero, faixa)
write_excel_csv2(novas, file.path(out_dir, "votacao_novas_candidaturas_por_faixa.csv"))

# Totais por grupo (checagem: soma dos componentes = variação da participação do grupo)
totais <- base |>
  summarise(share = sum(share), .by = c(ANO, DS_CARGO, genero)) |>
  pivot_wider(names_from = ANO, values_from = share, names_prefix = "share_") |>
  mutate(delta_pp = share_2022 - share_2018)
write_excel_csv2(totais, file.path(out_dir, "participacao_votacao_genero.csv"))
chk <- decomp |> filter(recorte == "gênero") |> summarise(soma = sum(delta_pp), .by = c(DS_CARGO, g)) |>
  inner_join(totais, by = c("DS_CARGO", "g" = "genero"))
# A decomposição exclui candidaturas sem CPF válido; a diferença deve ser desprezível
stopifnot(all(abs(chk$soma - chk$delta_pp) < 0.5))

# ------------------------------------------------------------------------------
# Gráficos
# ------------------------------------------------------------------------------
cores_ano <- c("2018" = "#86b6ef", "2022" = "#104281")
cor_barra <- "#2a78d6"
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.caption = element_text(colour = "grey40", hjust = 0), legend.position = "top")
fonte <- paste("Fonte: TSE (resultados; prestação de contas final, sem repasses).\nParticipação nos votos",
               "nominais de todas as candidaturas aptas do cargo (soma das UFs). Faixas: gasto ÷ p10\ndo",
               "gasto dos eleitos no mesmo ano, cargo e UF.")
salvar <- function(p, nome, w, h) {
  ggsave(file.path(out_dir, paste0(nome, ".png")), p, width = w, height = h, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, paste0(nome, ".pdf")), p, width = w, height = h)
}

# (A) Votação das mulheres por faixa de gasto, 2018 × 2022
d_a <- comp |> filter(genero == "Mulheres")
p <- ggplot(d_a, aes(x = share_votos, y = fct_rev(faixa))) +
  geom_line(aes(group = faixa), colour = "grey75", linewidth = 0.5) +
  geom_point(aes(colour = ANO, shape = ANO), size = 2.8, fill = "white", stroke = 1) +
  geom_text(aes(label = sprintf("%.1f", share_votos), colour = ANO,
                vjust = if_else(ANO == "2018", 2.1, -1.1)), size = 2.8, show.legend = FALSE) +
  facet_wrap(~DS_CARGO, ncol = 2) +
  scale_colour_manual(values = cores_ano, name = NULL) +
  scale_shape_manual(values = c("2018" = 21, "2022" = 16), name = NULL) +
  scale_x_continuous(labels = \(x) paste0(x, "%"), expand = expansion(mult = c(0.02, 0.1))) +
  labs(title = "Votação das mulheres por faixa de gasto — 2018 × 2022",
       subtitle = "% dos votos nominais do cargo obtidos por mulheres em cada faixa de gasto relativo ao patamar dos eleitos.",
       x = "% dos votos nominais do cargo", y = "Gasto ÷ p10 dos eleitos", caption = fonte) + tema
salvar(p, "votacao_mulheres_por_faixa_gasto", 10, 4.8)

# (B) Decomposição da variação da participação das mulheres (e dos homens, para comparar)
ordem_comp <- c("Novas candidaturas (só 2022)", "Saíram (só 2018)",
                "Permaneceram: cruzaram o patamar", "Permaneceram: acima nos dois anos",
                "Permaneceram: abaixo nos dois anos", "Permaneceram: caíram abaixo do patamar")
d_b <- decomp |>
  filter(recorte == "gênero") |>
  mutate(componente = factor(componente, levels = rev(ordem_comp)))
tot_b <- totais |> transmute(DS_CARGO, g = genero, lab = sprintf("Variação total: %+.1f pp", delta_pp))
p <- ggplot(d_b, aes(x = delta_pp, y = componente)) +
  geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.4) +
  geom_col(fill = cor_barra, width = 0.6) +
  geom_text(aes(label = sprintf("%+.1f", delta_pp), hjust = if_else(delta_pp >= 0, -0.2, 1.2)),
            size = 2.8, colour = "grey20") +
  geom_text(data = tot_b, aes(x = -Inf, y = Inf, label = lab), inherit.aes = FALSE,
            hjust = -0.05, vjust = 1.3, size = 3, fontface = "bold", colour = "grey20") +
  facet_grid(g ~ DS_CARGO) +
  scale_x_continuous(expand = expansion(mult = 0.25)) +
  labs(title = "De onde veio a variação da participação no voto, de 2018 para 2022",
       subtitle = paste0("Contribuição de cada grupo de candidaturas para a variação da participação ",
                         "de mulheres e de homens\nnos votos nominais (pontos percentuais). ",
                         "Permaneceram = mesmo CPF e cargo nos dois anos;\n",
                         "patamar = gasto ≥ 0,5× o p10 dos eleitos."),
       x = "Contribuição (pontos percentuais dos votos nominais)", y = NULL, caption = fonte) + tema
salvar(p, "decomposicao_variacao_votacao_genero", 10, 6.5)

message("Voto por faixa de gasto: resultados em ", out_dir)
