# ==============================================================================
# 11 — Tabelas e figuras do Cap. 4 (EC 111) a partir do R/10 (plano 2026-11-22)
#
# Não reestima nada: lê output/variaveis_principais_resultados.csv,
# output/transferencias_por_cargo.csv e a base por candidatura (para a razão das médias
# por candidatura em cada cargo). Escreve as tabelas em Markdown, com legenda e rótulo,
# em Quarto/thesis/chapters/_tabelas-cap3/ (incluídas no capítulo com {{< include >}}) e
# as figuras em Quarto/thesis/Figures/03-ec111-competitividade/.
#
# Convenções: efeitos em pontos percentuais, vírgula decimal, sinal de menos tipográfico;
# * = IC de 95% (pontual, erros agrupados por UF) exclui zero.
#
#   Rscript explorations/ec111-did-2026/R/11_tabelas_figuras_capitulo.R
# ==============================================================================

.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
suppressPackageStartupMessages({library(tidyverse)})

out_dir <- "explorations/ec111-did-2026/output"
tab_dir <- "Quarto/thesis/chapters/_tabelas-cap3"
fig_dir <- "Quarto/thesis/Figures/03-ec111-competitividade"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
fonte <- "Fonte: TSE; elaboração própria"

le <- \(f) read_csv2(file.path(out_dir, f), show_col_types = FALSE,
                     locale = locale(decimal_mark = ","))
res <- le("variaveis_principais_resultados.csv") |>
  mutate(sig = sign(ic_inf) == sign(ic_sup))
transf <- le("transferencias_por_cargo.csv")

nome_grupo <- c(mulher = "Mulheres", negra = "Pessoas negras", mulher_negra = "Mulheres negras")
cores_gr <- c("Mulheres" = "#eb6834", "Pessoas negras" = "#2a78d6", "Mulheres negras" = "#7b3f99")

#' Número no padrão do texto: vírgula decimal, sinal explícito, menos tipográfico
num <- function(x, d = 1, sinal = TRUE) {
  s <- formatC(abs(x), format = "f", digits = d, decimal.mark = ",", big.mark = ".")
  pre <- if_else(x < 0 & round(abs(x), d) > 0, "−", if_else(sinal & round(x, d) > 0, "+", ""))
  if_else(is.na(x), "—", paste0(pre, s))
}
celula <- \(att, sig) if_else(is.na(att), "—", paste0(num(att), if_else(sig %in% TRUE, "\\*", "")))
per_cols <- c("2014", "2022", "2026", "Dif. 2026 − 2022", "Federal × Pós")

#' Linhas de uma tabela de efeitos: variável × grupo × período
linhas_efeito <- function(medidas, rotulos, grupos = names(nome_grupo), periodos = per_cols) {
  res |>
    filter(medida %in% medidas, grupo %in% grupos, periodo %in% periodos) |>
    mutate(cel = celula(att, sig)) |>
    select(medida, grupo, periodo, cel) |>
    pivot_wider(names_from = periodo, values_from = cel) |>
    mutate(medida = factor(medida, medidas), grupo = factor(grupo, grupos)) |>
    arrange(medida, grupo) |>
    mutate(Variável = if_else(row_number() == 1, rotulos[as.character(medida)], ""),
           .by = medida) |>
    mutate(Grupo = unname(nome_grupo[as.character(grupo)]))
}

#' Escreve uma tabela Markdown com legenda e rótulo
escrever <- function(df, alinh, legenda, rotulo, arquivo) {
  cab <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("|", paste(alinh, collapse = "|"), "|")
  corpo <- apply(df, 1, \(r) paste0("| ", paste(replace_na(r, ""), collapse = " | "), " |"))
  writeLines(c(cab, sep, corpo, "", paste0(": ", legenda, " {#", rotulo, "}")),
             file.path(tab_dir, arquivo), useBytes = TRUE)
}

# ------------------------------------------------------------------------------
# 1. Tabela principal: uma variável por etapa
# ------------------------------------------------------------------------------
rot_princ <- c(cand = "Proporção de candidaturas",
               rec_partido = "Proporção das transferências do partido",
               gasto = "Proporção do gasto", voto = "Proporção dos votos nominais",
               pcv = "Proporção entre as competitivas pelo voto",
               pcg = "Proporção entre as competitivas pelo gasto",
               cadeira = "Proporção das cadeiras")
t1 <- linhas_efeito(names(rot_princ), rot_princ) |>
  transmute(Variável, Grupo, `Pré-teste 2014` = replace_na(`2014`, "—"), `2022`, `2026`,
            `Diferença 2026 − 2022` = `Dif. 2026 − 2022`, `Federal × Pós`)
escrever(t1, c(":---", ":---", rep("---:", 5)),
  paste("Efeito do voto em dobro sobre a proporção de mulheres, pessoas negras e mulheres negras",
        "em cada etapa da candidatura, federal × estadual, base 2018 (pontos percentuais).",
        "Candidaturas, transferências, gasto e votos: listas partido × UF; competitivas e",
        "cadeiras: disputas UF × cargo. Painel balanceado, sem ponderação. O pré-teste é a mesma",
        "conta entre 2014 e 2018; transferências, gasto e competitivas pelo gasto começam em 2018.",
        "Federal × Pós: termo único da @eq-reg-ec111. \\* IC de 95% exclui zero, com erros",
        "agrupados por UF.", fonte, "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-principal-ec111", "principal.md")

# ------------------------------------------------------------------------------
# 2. Sucesso relativo: diferença de taxas entre o grupo e o de comparação
# ------------------------------------------------------------------------------
rot_taxa <- c(tcv = "Competitiva pelo voto", tcg = "Competitiva pelo gasto", tel = "Eleita")
comp <- tribble(~grupo, ~sufixo, ~rotulo,
  "mulher", "", "Mulheres − homens",
  "negra", "", "Pessoas negras − demais",
  "negra", "_br", "Pessoas negras − pessoas brancas",
  "mulher_negra", "", "Mulheres negras − demais",
  "mulher_negra", "_hb", "Mulheres negras − homens brancos")
t2 <- pmap(comp, \(grupo, sufixo, rotulo) {
  g <- grupo
  bind_rows(
    tibble(Taxa = paste0("*", rotulo, "*")),
    res |> filter(medida %in% paste0(names(rot_taxa), sufixo), grupo == g,
                  periodo %in% per_cols) |>
      mutate(cel = celula(att, sig), base = if (sufixo == "") medida else str_remove(medida, sufixo)) |>
      select(base, periodo, cel) |>
      pivot_wider(names_from = periodo, values_from = cel) |>
      mutate(base = factor(base, names(rot_taxa))) |> arrange(base) |>
      transmute(Taxa = rot_taxa[as.character(base)], `Pré-teste 2014` = replace_na(`2014`, "—"),
                `2022`, `2026`, `Diferença 2026 − 2022` = `Dif. 2026 − 2022`, `Federal × Pós`))
}) |> list_rbind()
escrever(t2, c(":---", rep("---:", 5)),
  paste("Efeito do voto em dobro sobre o sucesso relativo: diferença entre a taxa do grupo e a do",
        "grupo de comparação (% das candidaturas que terminam competitivas ou eleitas), federal ×",
        "estadual, base 2018 (pontos percentuais). Competitiva = eleita ou a menos de 0,1 QE do",
        "limiar, pela margem de votos ou de gasto. Disputas UF × cargo, sem ponderação. As linhas",
        "com pessoas brancas e homens brancos são comparações adicionais. No gasto, não há",
        "pré-teste (doação empresarial em 2014). \\* IC de 95% exclui zero, com erros agrupados por",
        "UF.", fonte, "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-sucesso-ec111", "sucesso.md")

# ------------------------------------------------------------------------------
# 3. Transferências por cargo e nos dois cargos somados (realocação, H2)
# ------------------------------------------------------------------------------
cand <- readRDS("data/processed/cand_ec111_2014_2026.rds") |>
  mutate(ano = as.integer(ANO)) |> filter(ano >= 2018L)
razao_cargo <- map(names(nome_grupo), \(g) {
  cand |> mutate(gr = .data[[g]], cargo = if_else(federal, "Federal", "Estadual")) |>
    summarise(razao = mean(receita_partido[gr]) / mean(receita_partido[!gr]),
              .by = c(ano, cargo)) |>
    mutate(grupo = g)
}) |> list_rbind()

t3 <- transf |>
  select(grupo, ano, cargo, cand, transf) |>
  pivot_wider(names_from = cargo, values_from = c(cand, transf)) |>
  left_join(razao_cargo |> pivot_wider(names_from = cargo, values_from = razao,
                                       names_prefix = "razao_"), by = c("grupo", "ano")) |>
  mutate(grupo = factor(grupo, names(nome_grupo))) |> arrange(grupo, ano) |>
  mutate(Grupo = if_else(row_number() == 1, unname(nome_grupo[as.character(grupo)]), ""),
         .by = grupo) |>
  transmute(Grupo, Ano = as.character(ano),
            `Candidaturas, dois cargos` = num(`cand_Dois cargos`, sinal = FALSE),
            `Transferências, estadual` = num(transf_Estadual, sinal = FALSE),
            `Transferências, federal` = num(transf_Federal, sinal = FALSE),
            `Transferências, dois cargos` = num(`transf_Dois cargos`, sinal = FALSE),
            `Razão por candidatura, estadual` = num(razao_Estadual, 2, sinal = FALSE),
            `Razão por candidatura, federal` = num(razao_Federal, 2, sinal = FALSE))
escrever(t3, c(":---", ":---", rep("---:", 6)),
  paste("Proporção das candidaturas e das transferências do partido destinadas a cada grupo, por",
        "cargo e nos dois cargos somados (%), e razão entre o valor médio transferido por",
        "candidatura do grupo e por candidatura das demais (1 = igualdade). Totais nacionais, sem",
        "o DF.", fonte, "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-transferencias-cargo-ec111", "transferencias_cargo.md")

# ------------------------------------------------------------------------------
# 4. Onde ficaram os ganhos: competitivas × não competitivas
# ------------------------------------------------------------------------------
rot_dec <- c(recp = "Transferências do partido", gasto = "Gasto", voto = "Votos nominais")
t4 <- map(names(nome_grupo), \(g) {
  x <- res |> filter(grupo == g, periodo %in% c("2022", "2026"),
                     medida %in% c(paste0(names(rot_dec), "_c"), paste0(names(rot_dec), "_nc"))) |>
    mutate(base = str_remove(medida, "_n?c$"), parte = if_else(str_detect(medida, "_nc$"),
                                                               "não competitivas", "competitivas"),
           col = paste0(periodo, ": ", parte), cel = celula(att, sig)) |>
    select(base, col, cel) |>
    pivot_wider(names_from = col, values_from = cel) |>
    mutate(base = factor(base, names(rot_dec))) |> arrange(base)
  bind_rows(tibble(Variável = paste0("*", nome_grupo[g], "*")),
            x |> transmute(Variável = rot_dec[as.character(base)],
                           `2022: competitivas`, `2022: não competitivas`,
                           `2026: competitivas`, `2026: não competitivas`))
}) |> list_rbind()
escrever(t4, c(":---", rep("---:", 4)),
  paste("Onde ficaram os ganhos: efeito do voto em dobro sobre a proporção da lista que vai para",
        "candidaturas do grupo que terminaram competitivas e não competitivas (eleitas ou a menos",
        "de 0,1 QE do limiar pela margem de votos), federal × estadual, base 2018 (pontos",
        "percentuais). As duas partes somam o efeito sobre a proporção total. Listas partido × UF,",
        "painel balanceado, sem ponderação. \\* IC de 95% exclui zero, com erros agrupados por UF.",
        fonte, "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-decomposicao-ec111", "decomposicao.md")

# ------------------------------------------------------------------------------
# 5. Teste de falsificação: receita por origem (categorias de 2026-11-24)
# ------------------------------------------------------------------------------
# A parte residual (rendimentos, origem não identificada; < 0,1% da receita) fica fora da
# tabela; as quatro partes mostradas + a residual somam a receita total do grupo.
rot_fals <- c(rtp = "Vinda do partido",
              rtc_pub = "Repassada por outras candidaturas: FEFC e Fundo Partidário",
              rtc_priv = "Repassada por outras candidaturas: outros recursos",
              rtpriv = "Doações e recursos próprios")
t5 <- linhas_efeito(names(rot_fals), rot_fals,
                    periodos = c("2022", "2026", "Dif. 2026 − 2022", "Federal × Pós")) |>
  transmute(`Parte da receita total` = Variável, Grupo, `2022`, `2026`,
            `Diferença 2026 − 2022` = `Dif. 2026 − 2022`, `Federal × Pós`)
escrever(t5, c(":---", ":---", rep("---:", 4)),
  paste("Teste de falsificação: efeito do voto em dobro sobre a parte da receita total da lista",
        "recebida pelo grupo, por origem, federal × estadual, base 2018 (pontos percentuais). O",
        "teste é a última parte, doações de pessoas físicas, financiamento coletivo e recursos",
        "próprios: o voto em dobro não muda o incentivo dos doadores, e um efeito sobre ela",
        "indicaria uma mudança mais ampla. Os repasses de outras candidaturas são separados pela",
        "fonte declarada; o FEFC e o Fundo Partidário chegam às candidaturas pelos partidos. As",
        "partes somam o efeito sobre a proporção da receita total, com uma parte residual",
        "(rendimentos e origem não identificada, menos de 0,1% da receita) omitida. Listas",
        "partido × UF, painel balanceado, sem ponderação. \\* IC de 95% exclui zero, com erros",
        "agrupados por UF.", fonte, "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-falsificacao-ec111", "falsificacao.md")

# ------------------------------------------------------------------------------
# 6. Figuras
# ------------------------------------------------------------------------------
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.3),
        strip.text = element_text(face = "bold", hjust = 0), legend.position = "bottom",
        plot.caption = element_text(colour = "grey40", hjust = 0),
        axis.text = element_text(colour = "grey25"))

# 6a. Efeitos por etapa (2022 e 2026), um painel por grupo
f1 <- res |>
  filter(medida %in% names(rot_princ), periodo %in% c("2022", "2026")) |>
  mutate(Variável = factor(rot_princ[medida], rev(rot_princ)),
         Grupo = factor(nome_grupo[grupo], names(cores_gr)), Ano = periodo)
g1 <- ggplot(f1, aes(att, Variável, colour = Grupo, shape = Ano)) +
  geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.4) +
  geom_linerange(aes(xmin = banda_inf, xmax = banda_sup),
                 position = position_dodge(width = 0.6), linewidth = 0.35) +
  geom_linerange(aes(xmin = ic_inf, xmax = ic_sup),
                 position = position_dodge(width = 0.6), linewidth = 1.1) +
  geom_point(position = position_dodge(width = 0.6), size = 2.3, fill = "white", stroke = 0.9) +
  scale_shape_manual(values = c("2022" = 16, "2026" = 21), name = NULL) +
  scale_colour_manual(values = cores_gr, guide = "none") +
  scale_x_continuous(labels = \(x) num(x, 0)) +
  facet_wrap(~Grupo, nrow = 1) +
  labs(x = "Efeito, federal × estadual, base 2018 (pontos percentuais)", y = NULL) +
  tema + theme(panel.spacing.x = unit(1.4, "lines"))
ggsave(file.path(fig_dir, "efeitos_etapas.png"), g1, width = 8, height = 3.8, dpi = 300,
       bg = "white")

# 6b. Proporção das transferências por cargo e nos dois cargos somados
f2 <- transf |>
  mutate(Grupo = factor(nome_grupo[grupo], names(cores_gr)),
         serie = factor(cargo, c("Estadual", "Federal", "Dois cargos")),
         # a linha dos dois cargos leva a cor do grupo; as dos cargos ficam em cinza
         cor = if_else(cargo == "Dois cargos", as.character(Grupo), "Cargo"))
ref <- transf |> filter(cargo == "Dois cargos") |>
  mutate(Grupo = factor(nome_grupo[grupo], names(cores_gr)))
rotulos <- f2 |> filter(ano == 2026L)
g2 <- ggplot(f2, aes(ano, transf)) +
  geom_line(data = ref, aes(ano, cand), colour = "grey45", linetype = "dotted",
            linewidth = 0.6) +
  geom_line(aes(linetype = serie, linewidth = serie, colour = cor, group = serie)) +
  geom_point(aes(colour = cor, group = serie), size = 1.8) +
  geom_text(data = rotulos, aes(label = serie, colour = cor),
            hjust = -0.12, size = 2.9, show.legend = FALSE) +
  scale_linetype_manual(values = c("Estadual" = "dashed", "Federal" = "solid",
                                   "Dois cargos" = "solid"), guide = "none") +
  scale_linewidth_manual(values = c("Estadual" = 0.6, "Federal" = 0.6, "Dois cargos" = 1.1),
                         guide = "none") +
  scale_colour_manual(values = c(cores_gr, Cargo = "grey30"), guide = "none") +
  scale_x_continuous(breaks = c(2018, 2022, 2026), expand = expansion(mult = c(0.05, 0.05))) +
  scale_y_continuous(labels = \(x) paste0(num(x, 0, sinal = FALSE), "%")) +
  facet_wrap(~Grupo, nrow = 1, scales = "free_y") +
  labs(x = NULL, y = "% das transferências do partido") +
  coord_cartesian(clip = "off") +
  tema + theme(panel.grid.major.y = element_line(colour = "grey90", linewidth = 0.3),
               panel.spacing.x = unit(5.5, "lines"), plot.margin = margin(5, 70, 5, 5))
ggsave(file.path(fig_dir, "transferencias_por_cargo.png"), g2, width = 8, height = 3.3,
       dpi = 300, bg = "white")

# ------------------------------------------------------------------------------
# 6. Para quem foi o acréscimo: competitivas ex post e viáveis ex ante (R/12 e R/13;
#    plano 2026-11-24_cap4-cacaniquel-item1-implementacao.md)
# ------------------------------------------------------------------------------
esp <- le("cacaniquel_viabilidade_esperado.csv") |>
  filter(parte %in% c("recp_c", "recp_v"), periodo %in% c("2022", "2026")) |>
  mutate(sig = sign(ic_inf) == sign(ic_sup))
rot_part <- c(recp_c = "Competitivas ex post", recp_v = "Viáveis ex ante")
t6 <- map(names(nome_grupo), \(g) {
  x <- esp |> filter(grupo == g) |>
    mutate(obs = celula(att_parte, sig), espd = num(esperado), tot = num(att_total)) |>
    select(parte, periodo, s_2018, tot, obs, espd) |>
    pivot_wider(names_from = periodo, values_from = c(tot, obs, espd)) |>
    mutate(parte = factor(parte, names(rot_part))) |> arrange(parte)
  bind_rows(tibble(Parte = paste0("*", nome_grupo[g], "*")),
            x |> transmute(Parte = rot_part[as.character(parte)],
                           `Fatia federal 2018 (%)` = num(100 * s_2018, sinal = FALSE),
                           `2022: total` = tot_2022, `2022: observado` = obs_2022,
                           `2022: esperado` = espd_2022, `2026: total` = tot_2026,
                           `2026: observado` = obs_2026, `2026: esperado` = espd_2026))
}) |> list_rbind()
escrever(t6, c(":---", rep("---:", 7)),
  paste("Para quem foi o acréscimo das transferências: efeito do voto em dobro sobre a proporção",
        "das transferências do partido à lista que vai para candidaturas do grupo (total) e para",
        "a parte do grupo que terminou competitiva (eleita ou a menos de 0,1 QE do limiar) ou que",
        "era viável antes da eleição (eleita deputada, em qualquer dos dois cargos, ou a menos de",
        "0,1 QE do limiar na eleição anterior), observado e esperado se o acréscimo seguisse a",
        "divisão do cargo federal em 2018 (fatia × efeito total), federal × estadual, base 2018",
        "(pontos percentuais). Listas partido × UF, painel balanceado, sem ponderação. \\* IC de",
        "95% exclui zero, com erros agrupados por UF.", fonte,
        "(explorations/ec111-did-2026/R/12, R/13 e R/11)."),
  "tbl-viabilidade-ec111", "viabilidade.md")

mat <- le("viabilidade_matriz_2x2.csv") |> filter(grupo == "mulher")
razao <- le("viabilidade_tamanhos.csv") |> filter(grupo == "mulher")
ordem_cel <- c("Viável → competitiva", "Viável → não competitiva", "Não viável → competitiva",
               "Não viável → não competitiva")
cols_mat <- paste(rep(c("Estadual", "Federal"), each = 3), rep(c(2018, 2022, 2026), 2))
t7 <- bind_rows(
  mat |> mutate(col = paste(cargo, ano), v = num(transf, sinal = FALSE)) |>
    select(celula, col, v),
  razao |> mutate(celula = "Transferência média: viáveis ÷ não viáveis",
                  col = paste(cargo, ano), v = num(razao_v_nv, sinal = FALSE)) |>
    select(celula, col, v)) |>
  pivot_wider(names_from = col, values_from = v) |>
  mutate(celula = factor(celula, c(ordem_cel, "Transferência média: viáveis ÷ não viáveis"))) |>
  arrange(celula) |>
  transmute(`Viável antes → competitiva depois` = as.character(celula), !!!syms(cols_mat))
escrever(t7, c(":---", rep("---:", 6)),
  paste("Transferências do partido às mulheres segundo a viabilidade antes da eleição e a",
        "competitividade no resultado (% das transferências às candidatas do cargo no ano) e razão",
        "entre a transferência média às viáveis e às não viáveis. Viável: eleita deputada, em",
        "qualquer dos dois cargos, ou a menos de 0,1 QE do limiar na eleição anterior.",
        "Competitiva: eleita ou a menos de 0,1 QE do limiar. Totais nacionais, sem o DF.", fonte,
        "(explorations/ec111-did-2026/R/12 e R/11)."),
  "tbl-matriz-viabilidade-ec111", "matriz_viabilidade.md")

message("Tabelas: ", paste(list.files(tab_dir), collapse = ", "))
message("Figuras: efeitos_etapas.png, transferencias_por_cargo.png")
