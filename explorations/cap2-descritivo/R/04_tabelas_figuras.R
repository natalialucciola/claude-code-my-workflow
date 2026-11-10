# ==============================================================================
# Script: 04_tabelas_figuras.R
# Purpose: Indicadores, tabelas e figuras do Capítulo 2 (análise descritiva da
#          participação de mulheres e negros, Deputado Federal e Estadual,
#          2014–2026). Padrão visual do Capítulo 6 (Okabe-Ito, theme_minimal,
#          PNG 300 dpi + PDF).
#
#   Tabelas são escritas como trechos Markdown em
#   Quarto/thesis/chapters/_tabelas-cap2/ e incluídas no .qmd com
#   {{< include >}} — nenhum número do capítulo é digitado à mão.
#
# Inputs:  explorations/cap2-descritivo/output/dados/
#            painel_candidaturas.rds (01), financiamento_candidaturas.rds (02),
#            geografia_gasto_candidaturas.rds (03)
# Outputs: explorations/cap2-descritivo/output/indicadores_*.csv
#          Quarto/thesis/Figures/02-analise-descritiva/*.png|pdf
#          Quarto/thesis/chapters/_tabelas-cap2/*.md
#
# Rodar a partir da raiz do repositório:
#   Rscript explorations/cap2-descritivo/R/04_tabelas_figuras.R
# ==============================================================================

library(tidyverse)
library(patchwork)

base_dir <- file.path("explorations", "cap2-descritivo")
dados    <- file.path(base_dir, "output", "dados")
out_dir  <- file.path(base_dir, "output")
fig_dir  <- file.path("Quarto", "thesis", "Figures", "02-analise-descritiva")
tab_dir  <- file.path("Quarto", "thesis", "chapters", "_tabelas-cap2")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

anos <- c(2014L, 2018L, 2022L, 2026L)
n_partidos_destaque <- 12L

# ---- Paleta Okabe-Ito (mesmas cores do Capítulo 6) e tema ----
cor_feminino <- "#E69F00"; cor_masculino <- "#0072B2"
cor_negra    <- "#009E73"; cor_branca    <- "#CC79A7"
cor_federal  <- "#D55E00"; cor_estadual  <- "#56B4E9"
cores_grupo4 <- c("Mulher negra" = "#009E73", "Mulher branca" = "#E69F00",
                  "Homem negro" = "#56B4E9", "Homem branco" = "#0072B2")
cores_bloco  <- c("Esquerda" = "#D55E00", "Centro-direita" = "#999999", "Direita" = "#0072B2")

tema <- theme_minimal(base_size = 11) +
  theme(strip.text = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        legend.position = "top", legend.justification = "center",
        plot.caption = element_text(hjust = 0, size = 8, margin = margin(t = 8)))

salvar_figura <- function(g, nome, largura = 7, altura = 4.5) {
  ggsave(file.path(fig_dir, paste0(nome, ".png")), g, width = largura, height = altura,
         dpi = 300, bg = "white")
  ggsave(file.path(fig_dir, paste0(nome, ".pdf")), g, width = largura, height = altura)
}

pct <- \(x, d = 1) formatC(100 * x, format = "f", digits = d, decimal.mark = ",")
int <- \(x) formatC(x, format = "d", big.mark = ".", decimal.mark = ",")
eixo_pct <- \(x) paste0(formatC(100 * x, format = "f", digits = 0), "%")

#' Escreve uma tabela Markdown (pipe table) com legenda e rótulo Quarto
escrever_tabela_md <- function(df, nome, legenda, rotulo, alinhamento = NULL) {
  alinhamento <- alinhamento %||% c("---", rep("---:", ncol(df) - 1))
  linhas <- c(
    paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(alinhamento, collapse = "|"), "|"),
    apply(df, 1, \(r) paste0("| ", paste(r, collapse = " | "), " |")),
    "",
    paste0(": ", legenda, " {#", rotulo, "}")
  )
  writeLines(linhas, file.path(tab_dir, paste0(nome, ".md")), useBytes = TRUE)
  write_csv(df, file.path(out_dir, paste0(nome, ".csv")))
}

# ==============================================================================
# 0. DADOS
# ==============================================================================

painel <- readRDS(file.path(dados, "painel_candidaturas.rds")) |>
  left_join(readRDS(file.path(dados, "financiamento_candidaturas.rds")),
            by = c("ANO_ELEICAO", "SQ_CANDIDATO")) |>
  left_join(readRDS(file.path(dados, "geografia_gasto_candidaturas.rds")) |>
              select(-gasto_geo),
            by = c("ANO_ELEICAO", "cargo", "SQ_CANDIDATO")) |>
  mutate(cargo = factor(cargo, levels = c("Federal", "Estadual")),
         ano = factor(ANO_ELEICAO, levels = anos))

tem_financiamento <- \(a) a %in% c(2014L, 2018L, 2022L, 2026L)

# Nos anos com prestação publicada, candidatura sem registro de receita/despesa
# = zero (100% dos eleitos têm registro; 5–16% das candidaturas não têm).
# 2026: prestação de contas do TSE de 08/11/2026 (final para >99% das candidaturas).
painel <- painel |>
  mutate(across(c(starts_with("receita"), gasto),
                \(x) if_else(tem_financiamento(ANO_ELEICAO), coalesce(x, 0), NA_real_)))

# Indicadores de composição para um grupo binário (mulher ou negra)
composicao <- function(df, var, ...) {
  df |>
    filter(!is.na(.data[[var]])) |>
    summarise(
      cand = n(),
      pct_cand = mean(.data[[var]]),
      pct_eleitos = mean(.data[[var]][eleito == 1]),
      pct_competitivas = mean(.data[[var]][competitivo == 1]),
      pct_votos = sum(votos[.data[[var]] == 1]) / sum(votos),
      ...
    )
}

dims <- list(Mulheres = "mulher", Negros = "negra")

# ==============================================================================
# 1. VISÃO GERAL — candidaturas, eleitos, composição (Tabela 1, Figura 1)
# ==============================================================================

geral <- imap(dims, \(v, rotulo) painel |>
  group_by(cargo, ANO_ELEICAO) |>
  composicao(v) |>
  ungroup() |>
  mutate(grupo = rotulo)) |>
  list_rbind()

mulher_negra <- painel |>
  filter(!is.na(grupo_genero_raca)) |>
  mutate(mn = as.integer(grupo_genero_raca == "Mulher negra")) |>
  group_by(cargo, ANO_ELEICAO) |>
  composicao("mn") |>
  ungroup() |>
  mutate(grupo = "Mulheres negras")

geral <- bind_rows(geral, mulher_negra)
write_csv(geral, file.path(out_dir, "indicadores_composicao.csv"))

totais <- painel |>
  summarise(candidaturas = n(), eleitos = sum(eleito), vagas = sum(vagas[!duplicated(SG_UF)]),
            .by = c(cargo, ANO_ELEICAO))

tab1 <- totais |>
  left_join(geral |> select(cargo, ANO_ELEICAO, grupo, pct_cand, pct_eleitos) |>
              pivot_wider(names_from = grupo, values_from = c(pct_cand, pct_eleitos)),
            by = c("cargo", "ANO_ELEICAO")) |>
  arrange(cargo, ANO_ELEICAO) |>
  transmute(
    Cargo = paste("Deputado", cargo), Ano = ANO_ELEICAO,
    Candidaturas = int(candidaturas), Eleitos = int(eleitos),
    `Mulheres (cand.)` = pct(pct_cand_Mulheres), `Mulheres (eleitas)` = pct(pct_eleitos_Mulheres),
    `Negros (cand.)` = pct(pct_cand_Negros), `Negros (eleitos)` = pct(pct_eleitos_Negros),
    `Mulheres negras (cand.)` = pct(`pct_cand_Mulheres negras`),
    `Mulheres negras (eleitas)` = pct(`pct_eleitos_Mulheres negras`)
  )
escrever_tabela_md(tab1, "tab-cap2-visao-geral",
                   "Candidaturas, eleitos e participação de mulheres, negros e mulheres negras (%), por cargo e ano",
                   "tbl-cap2-visao-geral", c("---", "---", rep("---:", 8)))

g1 <- geral |>
  select(cargo, ANO_ELEICAO, grupo, Candidaturas = pct_cand, Eleitos = pct_eleitos) |>
  pivot_longer(c(Candidaturas, Eleitos), names_to = "etapa", values_to = "pct") |>
  mutate(grupo = factor(grupo, levels = c("Mulheres", "Negros", "Mulheres negras"))) |>
  ggplot(aes(ANO_ELEICAO, pct, color = grupo, linetype = etapa, shape = etapa,
             group = interaction(grupo, etapa))) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.4) +
  geom_hline(yintercept = 0.30, linetype = "dotted", color = "grey55", linewidth = 0.4) +
  facet_wrap(~ cargo, labeller = as_labeller(\(x) paste("Deputado", x))) +
  scale_x_continuous(breaks = anos) +
  scale_y_continuous(labels = eixo_pct, limits = c(0, NA)) +
  scale_color_manual(values = c(Mulheres = cor_feminino, Negros = cor_negra,
                                "Mulheres negras" = "#000000"), name = NULL) +
  scale_linetype_manual(values = c(Candidaturas = "solid", Eleitos = "22"), name = NULL) +
  scale_shape_manual(values = c(Candidaturas = 16, Eleitos = 1), name = NULL) +
  labs(x = NULL, y = NULL,
       caption = paste0("Fonte: TSE. Candidaturas com ao menos um voto nominal válido. ",
                        "Linha pontilhada: piso de 30% da cota de gênero.")) +
  guides(linetype = guide_legend(override.aes = list(colour = "grey45"))) +
  tema + theme(legend.box = "vertical", legend.spacing.y = unit(0, "pt"))
salvar_figura(g1, "fig-cap2-composicao", 8, 4.6)

# ==============================================================================
# 2. SUCESSO E COMPETITIVIDADE por gênero × raça (Tabela 2, Figura 2)
# ==============================================================================

grupo4 <- painel |>
  filter(!is.na(grupo_genero_raca)) |>
  summarise(cand = n(), sucesso = mean(eleito), competitividade = mean(competitivo),
            votos_medianos = median(votos), .by = c(cargo, ANO_ELEICAO, grupo_genero_raca)) |>
  mutate(grupo_genero_raca = factor(grupo_genero_raca, levels = names(cores_grupo4)))
write_csv(grupo4, file.path(out_dir, "indicadores_grupo4.csv"))

tab2 <- grupo4 |>
  arrange(cargo, ANO_ELEICAO, grupo_genero_raca) |>
  transmute(Cargo = paste("Deputado", cargo), Ano = ANO_ELEICAO, Grupo = as.character(grupo_genero_raca),
            Candidaturas = int(cand), `Taxa de sucesso` = pct(sucesso, 1),
            `Competitivas` = pct(competitividade, 1), `Votos (mediana)` = int(round(votos_medianos)))
escrever_tabela_md(tab2, "tab-cap2-sucesso",
                   "Taxa de sucesso (eleitos/candidaturas, %), candidaturas competitivas (%) e votação mediana, por gênero e raça",
                   "tbl-cap2-sucesso", c("---", "---", "---", rep("---:", 4)))

g2 <- grupo4 |>
  pivot_longer(c(sucesso, competitividade), names_to = "medida", values_to = "valor") |>
  mutate(medida = factor(medida, levels = c("competitividade", "sucesso"),
                         labels = c("Candidaturas competitivas", "Taxa de sucesso (eleitos)"))) |>
  ggplot(aes(ANO_ELEICAO, valor, color = grupo_genero_raca, group = grupo_genero_raca)) +
  geom_line(linewidth = 0.8) + geom_point(size = 2.2) +
  facet_grid(medida ~ cargo, scales = "free_y",
             labeller = labeller(cargo = \(x) paste("Deputado", x))) +
  scale_x_continuous(breaks = anos) +
  scale_y_continuous(labels = eixo_pct, limits = c(0, NA)) +
  scale_color_manual(values = cores_grupo4, name = NULL) +
  labs(x = NULL, y = NULL,
       caption = "Competitiva: eleita ou com votos >= 10% do quociente eleitoral da UF. Fonte: TSE.") +
  tema
salvar_figura(g2, "fig-cap2-sucesso", 8, 5.5)

# ==============================================================================
# 3. FINANCIAMENTO, 2014–2026 (Tabela 3, Figura 3)
# ==============================================================================

fin <- painel |> filter(tem_financiamento(ANO_ELEICAO))

financiamento_grupo <- imap(dims, \(v, rotulo) fin |>
  filter(!is.na(.data[[v]])) |>
  summarise(
    pct_cand = mean(.data[[v]]),
    pct_receita = sum(receita_total[.data[[v]] == 1]) / sum(receita_total),
    pct_receita_publica = sum(receita_publica[.data[[v]] == 1]) / sum(receita_publica),
    pct_gasto = sum(gasto[.data[[v]] == 1]) / sum(gasto),
    receita_media_grupo = mean(receita_total[.data[[v]] == 1]),
    receita_media_ref = mean(receita_total[.data[[v]] == 0]),
    receita_mediana_grupo = median(receita_total[.data[[v]] == 1]),
    receita_mediana_ref = median(receita_total[.data[[v]] == 0]),
    .by = c(cargo, ANO_ELEICAO)
  ) |>
  mutate(grupo = rotulo)) |>
  list_rbind() |>
  mutate(razao_receita_cand = pct_receita / pct_cand,
         razao_media = receita_media_grupo / receita_media_ref)
write_csv(financiamento_grupo, file.path(out_dir, "indicadores_financiamento.csv"))

tab3 <- financiamento_grupo |>
  arrange(grupo, cargo, ANO_ELEICAO) |>
  transmute(Grupo = grupo, Cargo = paste("Deputado", cargo), Ano = ANO_ELEICAO,
            `Candidaturas (%)` = pct(pct_cand), `Receitas (%)` = pct(pct_receita),
            `Recursos públicos (%)` = pct(pct_receita_publica), `Gasto (%)` = pct(pct_gasto),
            `Receita média do grupo / da referência` = formatC(razao_media, format = "f", digits = 2,
                                                             decimal.mark = ","))
escrever_tabela_md(tab3, "tab-cap2-financiamento",
                   "Participação de mulheres e negros nas candidaturas, receitas, recursos públicos (FEFC e Fundo Partidário) e gasto (%), 2014–2026. Referência: homens e brancos",
                   "tbl-cap2-financiamento", c("---", "---", "---", rep("---:", 5)))

origem_grupo <- fin |>
  filter(genero %in% c("FEMININO", "MASCULINO")) |>
  mutate(Grupo = if_else(mulher == 1, "Mulheres", "Homens")) |>
  summarise(across(c(receita_partido, receita_pf, receita_propria, receita_pj, receita_outros_cand,
                     receita_total), \(x) sum(x, na.rm = TRUE)), .by = c(cargo, ANO_ELEICAO, Grupo)) |>
  mutate(Outras = receita_total - receita_partido - receita_pf - receita_propria - receita_pj -
           receita_outros_cand) |>
  pivot_longer(c(receita_partido, receita_pf, receita_propria, receita_pj, receita_outros_cand, Outras),
               names_to = "origem", values_to = "valor") |>
  mutate(fatia = valor / receita_total,
         origem = factor(origem,
                         levels = c("receita_partido", "receita_outros_cand", "receita_pf",
                                    "receita_propria", "receita_pj", "Outras"),
                         labels = c("Partido", "Outros candidatos", "Pessoas físicas",
                                    "Recursos próprios", "Pessoas jurídicas", "Outras")))
write_csv(origem_grupo, file.path(out_dir, "indicadores_origem_receita.csv"))

cores_origem <- c("Partido" = "#0072B2", "Outros candidatos" = "#56B4E9", "Pessoas físicas" = "#009E73",
                  "Recursos próprios" = "#E69F00", "Pessoas jurídicas" = "#CC79A7", "Outras" = "#BBBBBB")
g3a <- financiamento_grupo |>
  ggplot(aes(factor(ANO_ELEICAO), razao_receita_cand, color = grupo, group = grupo)) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "grey55", linewidth = 0.4) +
  geom_line(linewidth = 0.8) + geom_point(size = 2.4) +
  facet_wrap(~ cargo, labeller = as_labeller(\(x) paste("Deputado", x))) +
  scale_color_manual(values = c(Mulheres = cor_feminino, Negros = cor_negra), name = NULL) +
  labs(x = NULL, y = "Receitas (%) / candidaturas (%)",
       title = "A. Participação nas receitas relativa à participação nas candidaturas") +
  tema + theme(plot.title = element_text(size = 10, face = "bold"))
g3b <- origem_grupo |>
  filter(fatia > 0) |>
  ggplot(aes(Grupo, fatia, fill = origem)) +
  geom_col(width = 0.7) +
  facet_grid(cargo ~ ANO_ELEICAO, labeller = labeller(cargo = \(x) paste("Dep.", x))) +
  scale_y_continuous(labels = eixo_pct) +
  scale_fill_manual(values = cores_origem, name = NULL) +
  labs(x = NULL, y = NULL, title = "B. Composição das receitas por origem",
       caption = paste0("Fonte: TSE, prestação de contas final. Valor 1 em A: participação nas ",
                        "receitas igual à participação nas candidaturas.\n2026: arquivo do TSE de 08/11/2026 ",
                        "(prestação final para mais de 99% das candidaturas).")) +
  tema + theme(plot.title = element_text(size = 10, face = "bold"), legend.position = "right")
# Sem plot_annotation(): incompatível com o ggplot2 4.0 instalado; legenda vai no painel B
g3 <- g3a / g3b + plot_layout(heights = c(1, 1.4))
salvar_figura(g3, "fig-cap2-financiamento", 9, 8)

# ==============================================================================
# 4. GEOGRAFIA DAS CANDIDATURAS — região e magnitude (Tabelas 4 e 5, Figura 4)
# ==============================================================================

por_recorte <- function(df, recorte) {
  imap(dims, \(v, rotulo) df |>
    filter(!is.na(.data[[v]])) |>
    summarise(pct_cand = mean(.data[[v]]), pct_eleitos = mean(.data[[v]][eleito == 1]),
              n_eleitos = sum(eleito), .by = c(cargo, ANO_ELEICAO, all_of(recorte))) |>
    mutate(grupo = rotulo)) |>
    list_rbind()
}

regiao <- por_recorte(painel, "regiao")
magnitude <- por_recorte(painel, "faixa_magnitude")
uf <- por_recorte(painel, "SG_UF")
write_csv(regiao, file.path(out_dir, "indicadores_regiao.csv"))
write_csv(magnitude, file.path(out_dir, "indicadores_magnitude.csv"))
write_csv(uf, file.path(out_dir, "indicadores_uf.csv"))

tabela_recorte <- function(df, recorte, nome_col) {
  df |>
    filter(ANO_ELEICAO %in% c(2014L, 2026L)) |>
    select(cargo, ANO_ELEICAO, grupo, all_of(recorte), pct_cand, pct_eleitos) |>
    pivot_wider(names_from = c(grupo, ANO_ELEICAO), values_from = c(pct_cand, pct_eleitos)) |>
    arrange(cargo, .data[[recorte]]) |>
    transmute(Cargo = paste("Deputado", cargo), !!nome_col := as.character(.data[[recorte]]),
              `Mulheres cand. 2014` = pct(pct_cand_Mulheres_2014),
              `Mulheres cand. 2026` = pct(pct_cand_Mulheres_2026),
              `Mulheres eleitas 2014` = pct(pct_eleitos_Mulheres_2014),
              `Mulheres eleitas 2026` = pct(pct_eleitos_Mulheres_2026),
              `Negros cand. 2014` = pct(pct_cand_Negros_2014),
              `Negros cand. 2026` = pct(pct_cand_Negros_2026),
              `Negros eleitos 2014` = pct(pct_eleitos_Negros_2014),
              `Negros eleitos 2026` = pct(pct_eleitos_Negros_2026))
}

escrever_tabela_md(tabela_recorte(regiao, "regiao", "Região"), "tab-cap2-regiao",
                   "Participação de mulheres e negros entre candidaturas e eleitos (%), por região, 2014 e 2026",
                   "tbl-cap2-regiao", c("---", "---", rep("---:", 8)))

faixas <- painel |> distinct(cargo, faixa_magnitude, SG_UF, vagas) |>
  summarise(ufs = n(), vagas_min = min(vagas), vagas_max = max(vagas), .by = c(cargo, faixa_magnitude)) |>
  arrange(cargo, faixa_magnitude)
write_csv(faixas, file.path(out_dir, "faixas_magnitude.csv"))
magnitude_rotulo <- magnitude |>
  left_join(faixas, by = c("cargo", "faixa_magnitude")) |>
  mutate(faixa_rotulo = paste0(faixa_magnitude, " (", vagas_min,
                               if_else(vagas_min == vagas_max, "", paste0("–", vagas_max)),
                               " vagas, ", ufs, " UFs)"),
         faixa_magnitude = faixa_rotulo)
escrever_tabela_md(tabela_recorte(magnitude_rotulo, "faixa_magnitude", "Magnitude"), "tab-cap2-magnitude",
                   "Participação de mulheres e negros entre candidaturas e eleitos (%), por faixa de magnitude do distrito, 2014 e 2026",
                   "tbl-cap2-magnitude", c("---", "---", rep("---:", 8)))

g4 <- uf |>
  filter(ANO_ELEICAO %in% c(2014L, 2026L)) |>
  select(cargo, ANO_ELEICAO, grupo, SG_UF, pct_eleitos) |>
  mutate(regiao = unname(c(AC = "N", AM = "N", AP = "N", PA = "N", RO = "N", RR = "N", TO = "N",
                           AL = "NE", BA = "NE", CE = "NE", MA = "NE", PB = "NE", PE = "NE",
                           PI = "NE", RN = "NE", SE = "NE", DF = "CO", GO = "CO", MS = "CO",
                           MT = "CO", ES = "SE", MG = "SE", RJ = "SE", SP = "SE", PR = "S",
                           RS = "S", SC = "S")[SG_UF])) |>
  pivot_wider(names_from = ANO_ELEICAO, values_from = pct_eleitos, names_prefix = "a") |>
  mutate(SG_UF = fct_reorder(SG_UF, a2026, .fun = mean)) |>
  ggplot(aes(y = SG_UF)) +
  geom_segment(aes(x = a2014, xend = a2026, yend = SG_UF), color = "grey70", linewidth = 0.5) +
  geom_point(aes(x = a2014), shape = 1, size = 1.8, color = "grey40") +
  geom_point(aes(x = a2026, color = grupo), size = 2) +
  facet_grid(~ grupo + cargo, labeller = labeller(cargo = \(x) paste("Dep.", x))) +
  scale_x_continuous(labels = eixo_pct) +
  scale_color_manual(values = c(Mulheres = cor_feminino, Negros = cor_negra), guide = "none") +
  labs(x = "Participação entre os eleitos", y = NULL,
       caption = "Círculo vazio: 2014; círculo cheio: 2026. Fonte: TSE.") +
  tema + theme(panel.grid.major.y = element_line(color = "grey92"),
               axis.text.y = element_text(size = 7))
salvar_figura(g4, "fig-cap2-uf-eleitos", 9, 6.5)

# ==============================================================================
# 5. GEOGRAFIA DO VOTO E DO GASTO (Tabela 6)
# ==============================================================================

geo <- painel |>
  filter(!is.na(grupo_genero_raca)) |>
  summarise(
    mediana_mun_base_voto = median(n_mun_base),
    pct_voto_base = mean(pct_voto_base),
    pct_voto_capital = mean(pct_voto_capital),
    mediana_mun_base_gasto = median(n_mun_base_gasto, na.rm = TRUE),
    pct_gasto_capital = mean(pct_gasto_capital, na.rm = TRUE),
    .by = c(cargo, ANO_ELEICAO, grupo_genero_raca)
  ) |>
  mutate(grupo_genero_raca = factor(grupo_genero_raca, levels = names(cores_grupo4))) |>
  arrange(cargo, ANO_ELEICAO, grupo_genero_raca)
write_csv(geo, file.path(out_dir, "indicadores_geografia.csv"))

ou_traco <- \(x, f) if_else(is.na(x) | is.nan(x), "—", f(x))
tab6 <- geo |>
  transmute(Cargo = paste("Deputado", cargo), Ano = ANO_ELEICAO, Grupo = as.character(grupo_genero_raca),
            `Municípios-base do voto (mediana)` = int(round(mediana_mun_base_voto)),
            `Votos na base (%)` = pct(pct_voto_base),
            `Votos na capital (%)` = pct(pct_voto_capital),
            `Municípios-base do gasto (mediana)` = ou_traco(mediana_mun_base_gasto, \(x) int(round(x))),
            `Gasto na capital (%)` = ou_traco(pct_gasto_capital, pct))
escrever_tabela_md(tab6, "tab-cap2-geografia",
                   "Geografia do voto (2014–2026) e do gasto (2018–2022) por gênero e raça: médias por candidatura, exceto onde indicado",
                   "tbl-cap2-geografia", c("---", "---", "---", rep("---:", 5)))

# ==============================================================================
# 6. PARTIDOS — blocos ideológicos e maiores partidos (Tabela 7, Figura 5)
# ==============================================================================

bloco <- imap(dims, \(v, rotulo) painel |>
  filter(!is.na(.data[[v]]), bloco %in% names(cores_bloco)) |>
  summarise(pct_cand = mean(.data[[v]]), pct_eleitos = mean(.data[[v]][eleito == 1]),
            n_cand = n(), n_eleitos = sum(eleito), .by = c(cargo, ANO_ELEICAO, bloco)) |>
  mutate(grupo = rotulo)) |>
  list_rbind()
write_csv(bloco, file.path(out_dir, "indicadores_bloco.csv"))

g5 <- bloco |>
  pivot_longer(c(pct_cand, pct_eleitos), names_to = "etapa", values_to = "pct") |>
  mutate(etapa = if_else(etapa == "pct_cand", "Candidaturas", "Eleitos"),
         bloco = factor(bloco, levels = names(cores_bloco))) |>
  ggplot(aes(ANO_ELEICAO, pct, color = bloco, linetype = etapa, shape = etapa,
             group = interaction(bloco, etapa))) +
  geom_line(linewidth = 0.7) + geom_point(size = 2) +
  facet_grid(grupo ~ cargo, labeller = labeller(cargo = \(x) paste("Deputado", x))) +
  scale_x_continuous(breaks = anos) +
  scale_y_continuous(labels = eixo_pct, limits = c(0, NA)) +
  scale_color_manual(values = cores_bloco, name = NULL) +
  scale_linetype_manual(values = c(Candidaturas = "solid", Eleitos = "22"), name = NULL) +
  scale_shape_manual(values = c(Candidaturas = 16, Eleitos = 1), name = NULL) +
  labs(x = NULL, y = NULL,
       caption = paste0("Blocos segundo a posição média dos partidos no survey com especialistas de ",
                        "Bolognesi, Ribeiro, Codato e Silva (2025). Fonte: TSE.")) +
  guides(linetype = guide_legend(override.aes = list(colour = "grey45"))) +
  tema + theme(legend.box = "vertical", legend.spacing.y = unit(0, "pt"))
salvar_figura(g5, "fig-cap2-blocos", 8, 6)

destaque <- painel |>
  filter(!is.na(partido_2026)) |>
  summarise(eleitos = sum(eleito), .by = partido_2026) |>
  slice_max(eleitos, n = n_partidos_destaque) |>
  pull(partido_2026)

partidos <- painel |>
  filter(partido_2026 %in% destaque, ANO_ELEICAO %in% c(2014L, 2022L, 2026L)) |>
  summarise(pct_mulher_cand = mean(mulher[genero %in% c("FEMININO", "MASCULINO")]),
            pct_negra_cand = mean(negra[!is.na(raca2)]),
            pct_mulher_eleitos = mean(mulher[eleito == 1 & genero %in% c("FEMININO", "MASCULINO")]),
            pct_negra_eleitos = mean(negra[eleito == 1 & !is.na(raca2)]),
            eleitos = sum(eleito), .by = c(partido_2026, ANO_ELEICAO)) |>
  left_join(painel |> distinct(partido_2026, sigla_atual, bloco) |>
              filter(sigla_atual == partido_2026) |> select(partido_2026, bloco),
            by = "partido_2026")
write_csv(partidos, file.path(out_dir, "indicadores_partidos.csv"))

tab7 <- partidos |>
  select(partido_2026, bloco, ANO_ELEICAO, pct_mulher_cand, pct_mulher_eleitos, pct_negra_cand,
         pct_negra_eleitos, eleitos) |>
  pivot_wider(names_from = ANO_ELEICAO, values_from = c(pct_mulher_cand, pct_mulher_eleitos,
                                                        pct_negra_cand, pct_negra_eleitos, eleitos)) |>
  arrange(bloco, desc(eleitos_2026)) |>
  transmute(Partido = partido_2026, Bloco = coalesce(bloco, "—"),
            `Mulheres cand. 2014` = pct(pct_mulher_cand_2014),
            `Mulheres cand. 2026` = pct(pct_mulher_cand_2026),
            `Mulheres eleitas 2026` = ou_traco(pct_mulher_eleitos_2026, pct),
            `Negros cand. 2014` = pct(pct_negra_cand_2014),
            `Negros cand. 2026` = pct(pct_negra_cand_2026),
            `Negros eleitos 2026` = ou_traco(pct_negra_eleitos_2026, pct),
            `Eleitos 2026` = int(eleitos_2026))
escrever_tabela_md(tab7, "tab-cap2-partidos",
                   paste0("Participação de mulheres e negros (%) nos ", n_partidos_destaque,
                          " partidos que mais elegeram deputados (federais e estaduais) entre 2014 e 2026, ",
                          "pela identidade da legenda em 2026"),
                   "tbl-cap2-partidos", c("---", "---", rep("---:", 7)))

message("Tabelas em ", tab_dir, " | figuras em ", fig_dir)
