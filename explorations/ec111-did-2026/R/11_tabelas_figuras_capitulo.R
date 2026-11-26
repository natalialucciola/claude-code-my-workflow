# ==============================================================================
# 11 — Tabelas e figuras do Cap. 4 (EC 111) a partir do R/10, R/13 e R/14
#      (planos 2026-11-22 e 2026-11-25_cap4-ec111-dados-resultados.md)
#
# Não reestima nada: lê output/variaveis_principais_resultados.csv (R/10),
# output/recursos_publicos_resultados.csv e descritivo_competitividade_viabilidade.csv
# (R/14), output/cacaniquel_viabilidade_esperado.csv (R/13), os níveis e a base por
# candidatura. Escreve as tabelas em Markdown, com legenda e rótulo, em
# Quarto/thesis/chapters/_tabelas-cap3/ (incluídas com {{< include >}}) e as figuras em
# Quarto/thesis/Figures/03-ec111-competitividade/.
#
# Formato (25/11, itens 8 e 9 do plano): as estimativas saem em tabelas de regressão
# tradicionais, com as variáveis dependentes nas colunas, os termos nas linhas, o erro-padrão
# agrupado por UF entre parênteses e o p do wild cluster bootstrap entre colchetes; todas
# as tabelas de efeito usam a mesma ordem de termos (pré-teste, 2022, 2026, diferença,
# Federal × Pós).
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
# Legendas revisadas em 25/11 (redação), marcadas para a autora com a classe .revisao
# (Quarto/thesis/alteracoes.css; no PDF, Quarto/capitulo4-pdf/alterado.lua). Para tirar a
# marca, trocar rev() por identity.
rev <- \(x) paste0("[", x, "]{.revisao}")

le <- \(f) read_csv2(file.path(out_dir, f), show_col_types = FALSE,
                     locale = locale(decimal_mark = ","))
res <- bind_rows(le("variaveis_principais_resultados.csv"),
                 le("recursos_publicos_resultados.csv")) |>
  mutate(sig = sign(ic_inf) == sign(ic_sup))
stopifnot(!anyDuplicated(res[c("medida", "grupo", "periodo")]))
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
#' p-valor: duas casas, três abaixo de 0,01, "< 0,001" abaixo disso
fmt_p <- \(p) case_when(is.na(p) ~ NA_character_,
                        p < 0.001 ~ "< 0,001",
                        p < 0.01 ~ formatC(p, format = "f", digits = 3, decimal.mark = ","),
                        .default = formatC(p, format = "f", digits = 2, decimal.mark = ","))
#' Linha de erro-padrão: (EP) e, quando houver, [p do wild bootstrap]
celula_ep <- \(ep, p) if_else(is.na(ep), "",
                              paste0("(", num(ep, sinal = FALSE), ")",
                                     if_else(is.na(p), "", paste0(" [", fmt_p(p), "]"))))
inteiro <- \(x) formatC(x, format = "d", big.mark = ".", decimal.mark = ",")

#' Escreve uma tabela Markdown com legenda e rótulo (UTF-8 explícito no Windows)
escrever <- function(df, alinh, legenda, rotulo, arquivo) {
  cab <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("|", paste(alinh, collapse = "|"), "|")
  corpo <- apply(df, 1, \(r) paste0("| ", paste(replace_na(r, ""), collapse = " | "), " |"))
  con <- file(file.path(tab_dir, arquivo), open = "w", encoding = "UTF-8")
  writeLines(enc2utf8(c(cab, sep, corpo, "", paste0(": ", legenda, " {#", rotulo, "}"))), con)
  close(con)
}

termos <- c("2014" = "Federal × 2014 (pré-teste)", "2022" = "Federal × 2022",
            "2026" = "Federal × 2026", "Dif. 2026 − 2022" = "Diferença 2026 − 2022",
            "Federal × Pós" = "Federal × Pós")

#' Bloco de regressão: para cada termo, a linha do coeficiente e a do erro-padrão.
#' est: tibble com coluna (nome da coluna da tabela), periodo, att, ep, sig, p_wild
bloco_reg <- function(est, colunas, periodos) {
  map(periodos, \(p) {
    x <- est |> filter(periodo == p)
    coef <- set_names(map_chr(colunas, \(cl) {
      y <- x |> filter(coluna == cl)
      if (nrow(y) == 0) "—" else celula(y$att, y$sig)
    }), colunas)
    ep <- set_names(map_chr(colunas, \(cl) {
      y <- x |> filter(coluna == cl)
      if (nrow(y) == 0) "" else celula_ep(y$ep, y$p_wild)
    }), colunas)
    bind_rows(c(Termo = unname(termos[p]), coef), c(Termo = "", ep))
  }) |> list_rbind()
}
linha <- \(rotulo, valores, colunas) as_tibble_row(c(Termo = rotulo, set_names(valores, colunas)))
titulo <- \(txt, colunas) linha(paste0("*", txt, "*"), rep("", length(colunas)), colunas)

# ------------------------------------------------------------------------------
# 1. Tabelas de regressão por grupo: uma coluna por variável do funil (itens 8 e 9)
# ------------------------------------------------------------------------------
cols_funil <- c(cand = "(1) Candidaturas", rec_partido = "(2) Transferências do partido",
                rec_publico = "(3) Recursos públicos",
                lexcesso = "(4) Transferências − candidaturas", gasto = "(5) Gasto",
                voto = "(6) Votos", ltcv = "(7) Competitiva pelo voto",
                ltcg = "(8) Competitiva pelo gasto", ltel = "(9) Eleita")
anos_med <- c(cand = 4L, voto = 4L, ltcv = 4L, ltel = 4L)   # demais: 2018–2026

tabela_grupo <- function(g, rotulo, arquivo) {
  est <- res |> filter(grupo == g, medida %in% names(cols_funil)) |>
    mutate(coluna = cols_funil[medida])
  cl <- unname(cols_funil)
  info <- est |> distinct(medida, coluna, n_unidades, base_federal_2018) |>
    mutate(n_anos = coalesce(anos_med[medida], 3L)) |>
    arrange(match(coluna, cl))
  stopifnot(nrow(info) == length(cl))
  df <- bind_rows(
    titulo("A. Estudo de evento, base 2018", cl),
    bloco_reg(est, cl, c("2014", "2022", "2026", "Dif. 2026 − 2022")),
    titulo("B. Diferença em diferenças, 2018–2026", cl),
    bloco_reg(est, cl, "Federal × Pós"),
    linha("Média federal em 2018",num(info$base_federal_2018, sinal = FALSE), cl),
    linha("Listas", inteiro(info$n_unidades), cl),
    linha("Observações (A)", inteiro(info$n_unidades * info$n_anos), cl),
    linha("Observações (B)", inteiro(info$n_unidades * 3L), cl))
  escrever(df, c(":---", rep("---:", length(cl))),
    paste0(rev(paste0(
           "Efeito do voto em dobro em cada etapa da candidatura para ", tolower(nome_grupo[g]),
           ", federal × estadual, em pontos percentuais. O painel A traz os coeficientes da ",
           "@eq-att-ec111, com 2018 como referência e o termo de 2014 como pré-teste, e o painel ",
           "B, o termo único da @eq-reg-ec111. As colunas (1), (2), (3), (5) e (6) medem a parte do ",
           "grupo no total da lista, e a coluna (3) soma o FEFC e o Fundo Partidário recebidos do ",
           "partido e repassados por outras candidaturas. A coluna (4) é a proporção das ",
           "transferências menos a proporção das candidaturas do grupo, e as colunas (7) a (9) ",
           "são a taxa de candidaturas do grupo que terminam competitivas (eleitas ou a menos de ",
           "0,1 QE do limiar, pela margem de votos ou de gasto) ou eleitas, menos a taxa do ",
           "restante das candidaturas da lista, calculada apenas nas listas com os dois ",
           "grupos em todos os anos. Recursos, gasto e competitividade pelo gasto começam em 2018 ",
           "e por isso não têm pré-teste (—). As estimações usam as listas do painel balanceado, ",
           "sem ponderação e com efeitos fixos de lista e de ano. O erro-padrão agrupado por UF ",
           "(26 UFs) está entre parênteses e o p-valor do *wild cluster bootstrap* restrito, entre ",
           "colchetes. \\* IC de 95% exclui zero.")), " ", fonte,
           " (explorations/ec111-did-2026/R/10, R/14 e R/11)."),
    rotulo, arquivo)
}
tabela_grupo("mulher", "tbl-reg-mulheres-ec111", "reg_mulheres.md")
tabela_grupo("negra", "tbl-reg-negras-ec111", "reg_negras.md")
tabela_grupo("mulher_negra", "tbl-reg-mulheres-negras-ec111", "reg_mulheres_negras.md")

# ------------------------------------------------------------------------------
# 2. Comparações adicionais do sucesso relativo (pessoas brancas, homens brancos)
# ------------------------------------------------------------------------------
cols_taxa <- c(ltcv = "(1) Competitiva pelo voto", ltcg = "(2) Competitiva pelo gasto",
               ltel = "(3) Eleita")
comp <- tribble(~g, ~sufixo, ~rotulo,
  "negra", "_br", "Pessoas negras − pessoas brancas",
  "mulher_negra", "_hb", "Mulheres negras − homens brancos")
cl <- unname(cols_taxa)
t2 <- pmap(comp, \(g, sufixo, rotulo) {
  est <- res |> filter(grupo == g, medida %in% paste0(names(cols_taxa), sufixo)) |>
    mutate(coluna = cols_taxa[str_remove(medida, sufixo)])
  n <- est |> distinct(coluna, n_unidades) |> arrange(match(coluna, cl))
  bind_rows(titulo(rotulo, cl),
            bloco_reg(est, cl, names(termos)),
            linha("Listas", inteiro(n$n_unidades), cl))
}) |> list_rbind()
escrever(t2, c(":---", rep("---:", 3)),
  paste(rev(paste(
        "Efeito do voto em dobro sobre o sucesso relativo nas comparações adicionais, medido pela",
        "diferença entre a taxa do grupo e a de pessoas brancas ou de homens brancos na mesma",
        "lista, federal × estadual, base 2018, em pontos percentuais. A taxa é a proporção das",
        "candidaturas que terminam competitivas, isto é, eleitas ou a menos de 0,1 QE do limiar",
        "pela margem de votos ou de gasto, ou que se elegem. Entram as listas com os dois grupos",
        "em todos os anos, no painel balanceado, sem ponderação e com efeitos fixos de lista e de",
        "ano, e a competitividade pelo gasto não tem pré-teste. O erro-padrão agrupado por UF está",
        "entre parênteses e o p-valor do *wild cluster bootstrap*, entre colchetes. \\* IC de 95%",
        "exclui zero.")), fonte, "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-sucesso-ec111", "sucesso.md")

# ------------------------------------------------------------------------------
# 3. Quem fica com os lugares competitivos e as cadeiras da lista (mecanismo; TWFE
#    ponderado pelo denominador, painel desbalanceado; plano 2026-11-24)
# ------------------------------------------------------------------------------
pond <- le("competitividade_lista_ponderada.csv") |>
  filter(papel == "mecanismo: peso = denominador") |>
  mutate(sig = sign(ic_inf) == sign(ic_sup), p_wild = NA_real_)
cols_comp <- c(lpcv = "(1) Competitivas pelo voto", lpcg = "(2) Competitivas pelo gasto",
               lcadeira = "(3) Eleitos")
cl <- unname(cols_comp)
t3 <- map(names(nome_grupo), \(g) {
  est <- pond |> filter(grupo == g) |> mutate(coluna = cols_comp[medida])
  n <- est |> distinct(coluna, n_listas, n_obs) |> arrange(match(coluna, cl))
  bind_rows(titulo(nome_grupo[g], cl),
            bloco_reg(est, cl, c("2014", "2022", "2026", "Federal × Pós")),
            linha("Listas", inteiro(n$n_listas), cl),
            linha("Observações (estudo de evento)", inteiro(n$n_obs), cl))
}) |> list_rbind()
escrever(t3, c(":---", rep("---:", 3)),
  paste(rev(paste(
        "Efeito do voto em dobro sobre a proporção do grupo entre as candidaturas competitivas e",
        "entre os eleitos da lista, federal × estadual, base 2018, em pontos percentuais. A",
        "regressão tem efeitos fixos de lista e de ano e é ponderada pelo número de competitivas,",
        "ou de eleitos, da lista no ano, de modo que a lista sem nenhuma não entra naquele ano e o",
        "painel é desbalanceado. A competitividade pelo gasto não tem pré-teste. O erro-padrão",
        "agrupado por UF está entre parênteses. \\* IC de 95% exclui zero.")), fonte,
        "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-composicao-lista-ec111", "composicao_lista.md")

# ------------------------------------------------------------------------------
# 4. Teste de falsificação: receita por origem (categorias de 2026-11-24)
# ------------------------------------------------------------------------------
# A parte residual (rendimentos, origem não identificada; < 0,1% da receita) fica fora da
# tabela; as quatro partes mostradas + a residual somam a receita total do grupo.
cols_fals <- c(rtp = "(1) Vinda do partido",
               rtc_pub = "(2) Outras candidaturas: FEFC e Fundo Partidário",
               rtc_priv = "(3) Outras candidaturas: outros recursos",
               rtpriv = "(4) Doações e recursos próprios")
cl <- unname(cols_fals)
t4 <- map(names(nome_grupo), \(g) {
  est <- res |> filter(grupo == g, medida %in% names(cols_fals)) |>
    mutate(coluna = cols_fals[medida])
  n <- est |> distinct(coluna, n_unidades) |> arrange(match(coluna, cl))
  bind_rows(titulo(nome_grupo[g], cl),
            bloco_reg(est, cl, c("2022", "2026", "Dif. 2026 − 2022", "Federal × Pós")),
            linha("Listas", inteiro(n$n_unidades), cl))
}) |> list_rbind()
escrever(t4, c(":---", rep("---:", 4)),
  paste(rev(paste(
        "Teste de falsificação, com o efeito do voto em dobro sobre a parte da receita total da",
        "lista recebida pelo grupo, por origem, federal × estadual, base 2018, em pontos",
        "percentuais. O teste é a coluna (4), que reúne doações de pessoas físicas, financiamento",
        "coletivo e recursos próprios, porque o voto em dobro não muda o incentivo dos doadores e",
        "um efeito sobre essa receita indicaria uma mudança mais ampla na arrecadação. Os repasses",
        "de outras candidaturas são separados pela fonte declarada. As colunas somam o efeito sobre",
        "a proporção da receita total, exceto por uma parte residual, de rendimentos e de origem",
        "não identificada, que fica abaixo de 0,1% da receita e é omitida. As estimações usam o",
        "painel balanceado, sem ponderação e com efeitos fixos de lista e de ano. O erro-padrão",
        "agrupado por UF está entre parênteses e o p-valor do *wild cluster bootstrap*, calculado",
        "apenas para o teste, entre colchetes. \\* IC de 95% exclui zero.")), fonte,
        "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-falsificacao-ec111", "falsificacao.md")

# ------------------------------------------------------------------------------
# 5. Transferências por cargo e nos dois cargos somados (realocação, H2; descritiva)
# ------------------------------------------------------------------------------
cand <- readRDS("data/processed/cand_ec111_2014_2026.rds") |>
  mutate(ano = as.integer(ANO)) |> filter(ano >= 2018L)
razao_cargo <- map(names(nome_grupo), \(g) {
  cand |> mutate(gr = .data[[g]], cargo = if_else(federal, "Federal", "Estadual")) |>
    summarise(razao = mean(receita_partido[gr]) / mean(receita_partido[!gr]),
              .by = c(ano, cargo)) |>
    mutate(grupo = g)
}) |> list_rbind()

t5 <- transf |>
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
escrever(t5, c(":---", ":---", rep("---:", 6)),
  paste(rev(paste(
        "Proporção das candidaturas e das transferências do partido destinadas a cada grupo, por",
        "cargo e nos dois cargos somados (%), e razão entre o valor médio transferido a cada",
        "candidatura do grupo e a cada candidatura das demais, em que 1 indica igualdade. Totais",
        "nacionais, sem o DF.")), fonte, "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-transferencias-cargo-ec111", "transferencias_cargo.md")

# ------------------------------------------------------------------------------
# 6. Onde ficaram os ganhos: competitivas × não competitivas (mesmas colunas de termos)
# ------------------------------------------------------------------------------
rot_dec <- c(recp = "Transferências do partido", gasto = "Gasto", voto = "Votos nominais")
parte <- c(c = "competitivas", nc = "não competitivas")
t6 <- map(names(nome_grupo), \(g) {
  x <- res |>
    filter(grupo == g, medida %in% c(paste0(names(rot_dec), "_c"), paste0(names(rot_dec), "_nc")),
           periodo %in% names(termos)) |>
    mutate(base = str_remove(medida, "_n?c$"), pt = str_extract(medida, "n?c$"),
           cel = celula(att, sig)) |>
    select(base, pt, periodo, cel) |>
    pivot_wider(names_from = periodo, values_from = cel) |>
    mutate(base = factor(base, names(rot_dec)), pt = factor(pt, names(parte))) |>
    arrange(base, pt)
  bind_rows(tibble(Variável = paste0("*", nome_grupo[g], "*")),
            x |> transmute(Variável = paste0(rot_dec[as.character(base)], ": ",
                                             parte[as.character(pt)]),
                           `Pré-teste 2014` = replace_na(`2014`, "—"), `2022`, `2026`,
                           `Diferença 2026 − 2022` = `Dif. 2026 − 2022`, `Federal × Pós`))
}) |> list_rbind()
escrever(t6, c(":---", rep("---:", 5)),
  paste(rev(paste(
        "Efeito do voto em dobro sobre a proporção da lista que vai para candidaturas do grupo",
        "que terminaram competitivas, isto é, eleitas ou a menos de 0,1 QE do limiar pela margem",
        "de votos, e para as que terminaram não competitivas, federal × estadual, base 2018, em",
        "pontos percentuais. As duas partes somam o efeito sobre a proporção total, apresentado",
        "nas colunas (2), (5) e (6) das tabelas por grupo, e transferências e gasto não têm",
        "pré-teste. As estimações usam o painel balanceado, sem ponderação. \\* IC de 95% exclui",
        "zero, com erros agrupados por UF.")), fonte, "(explorations/ec111-did-2026/R/10 e R/11)."),
  "tbl-decomposicao-ec111", "decomposicao.md")

# ------------------------------------------------------------------------------
# 7. Para quem foi o acréscimo: competitivas ex post e viáveis ex ante (R/12 e R/13)
# ------------------------------------------------------------------------------
esp <- le("cacaniquel_viabilidade_esperado.csv") |>
  filter(parte %in% c("recp_c", "recp_v"), periodo %in% c("2022", "2026", "Federal × Pós")) |>
  mutate(sig = sign(ic_inf) == sign(ic_sup))
t7 <- map(names(nome_grupo), \(g) {
  x <- esp |> filter(grupo == g) |>
    mutate(obs = celula(att_parte, sig), espd = num(esperado), tot = num(att_total),
           fatia = num(100 * s_2018, sinal = FALSE)) |>
    select(parte, periodo, tot, obs, espd, fatia) |>
    pivot_wider(names_from = parte, values_from = c(obs, espd, fatia)) |>
    mutate(periodo = factor(periodo, c("2022", "2026", "Federal × Pós"))) |> arrange(periodo) |>
    mutate(across(starts_with("fatia"), \(v) if_else(row_number() == 1, v, "")))
  bind_rows(tibble(Termo = paste0("*", nome_grupo[g], "*")),
            x |> transmute(Termo = unname(termos[as.character(periodo)]),
                           `Efeito total` = tot,
                           `Competitivas ex post: fatia 2018 (%)` = fatia_recp_c,
                           `Competitivas ex post: observado` = obs_recp_c,
                           `Competitivas ex post: esperado` = espd_recp_c,
                           `Viáveis ex ante: fatia 2018 (%)` = fatia_recp_v,
                           `Viáveis ex ante: observado` = obs_recp_v,
                           `Viáveis ex ante: esperado` = espd_recp_v))
}) |> list_rbind()
escrever(t7, c(":---", rep("---:", 7)),
  paste(rev(paste(
        "Efeito do voto em dobro sobre a proporção das transferências do partido à lista que vai",
        "para candidaturas do grupo, no total e na parte do grupo que terminou competitiva ou que",
        "era viável antes da eleição, observado e esperado caso o acréscimo seguisse a divisão do",
        "cargo federal em 2018, federal × estadual, base 2018, em pontos percentuais. Competitiva",
        "é a candidatura eleita ou a menos de 0,1 QE do limiar, e viável, a candidatura cuja",
        "pessoa foi eleita deputada, em qualquer dos dois cargos, ou ficou a menos de 0,1 QE do",
        "limiar na eleição anterior. O valor esperado é a fatia de 2018 multiplicada pelo efeito",
        "total. As estimações usam o painel balanceado, sem ponderação. \\* IC de 95% exclui zero,",
        "com erros agrupados por UF.")), fonte, "(explorations/ec111-did-2026/R/12, R/13 e R/11)."),
  "tbl-viabilidade-ec111", "viabilidade.md")

mat <- le("viabilidade_matriz_2x2.csv") |> filter(grupo == "mulher")
razao <- le("viabilidade_tamanhos.csv") |> filter(grupo == "mulher")
ordem_cel <- c("Viável → competitiva", "Viável → não competitiva", "Não viável → competitiva",
               "Não viável → não competitiva")
cols_mat <- paste(rep(c("Estadual", "Federal"), each = 3), rep(c(2018, 2022, 2026), 2))
t8 <- bind_rows(
  mat |> mutate(col = paste(cargo, ano), v = num(transf, sinal = FALSE)) |>
    select(celula, col, v),
  razao |> mutate(celula = "Transferência média: viáveis ÷ não viáveis",
                  col = paste(cargo, ano), v = num(razao_v_nv, sinal = FALSE)) |>
    select(celula, col, v)) |>
  pivot_wider(names_from = col, values_from = v) |>
  mutate(celula = factor(celula, c(ordem_cel, "Transferência média: viáveis ÷ não viáveis"))) |>
  arrange(celula) |>
  transmute(`Viável antes → competitiva depois` = as.character(celula), !!!syms(cols_mat))
escrever(t8, c(":---", rep("---:", 6)),
  paste(rev(paste(
        "Transferências do partido às mulheres segundo a viabilidade antes da eleição e a",
        "competitividade no resultado, em % das transferências às candidatas do cargo no ano, e",
        "razão entre a transferência média às viáveis e às não viáveis. Viável é a candidata",
        "eleita deputada, em qualquer dos dois cargos, ou a menos de 0,1 QE do limiar na eleição",
        "anterior, e competitiva, a eleita ou a menos de 0,1 QE do limiar. Totais nacionais, sem o",
        "DF.")), fonte, "(explorations/ec111-did-2026/R/12 e R/11)."),
  "tbl-matriz-viabilidade-ec111", "matriz_viabilidade.md")

# ------------------------------------------------------------------------------
# 8. Descritiva: competitividade, eleição e viabilidade, grupo × restante (item 5)
# ------------------------------------------------------------------------------
desc <- le("descritivo_competitividade_viabilidade.csv")
f1 <- \(x) num(x, sinal = FALSE)
t9 <- desc |>
  select(grupo, cargo, ano, lado, pct_cv, pct_cg, pct_el, pct_viavel) |>
  pivot_wider(names_from = lado, values_from = starts_with("pct_")) |>
  mutate(grupo = factor(grupo, names(nome_grupo)), cargo = factor(cargo, c("Federal", "Estadual"))) |>
  arrange(grupo, cargo, ano) |>
  mutate(Grupo = if_else(row_number() == 1, unname(nome_grupo[as.character(grupo)]), ""),
         .by = grupo) |>
  mutate(Cargo = if_else(row_number() == 1, as.character(cargo), ""), .by = c(grupo, cargo)) |>
  transmute(Grupo, Cargo, Ano = as.character(ano),
            `Competitivas pelo voto: grupo` = f1(pct_cv_grupo),
            `Competitivas pelo voto: restante` = f1(pct_cv_complemento),
            `Competitivas pelo gasto: grupo` = f1(pct_cg_grupo),
            `Competitivas pelo gasto: restante` = f1(pct_cg_complemento),
            `Eleitas: grupo` = f1(pct_el_grupo), `Eleitas: restante` = f1(pct_el_complemento),
            `Viáveis antes da eleição: grupo` = f1(pct_viavel_grupo),
            `Viáveis antes da eleição: restante` = f1(pct_viavel_complemento))
escrever(t9, c(":---", ":---", ":---", rep("---:", 8)),
  paste(identity(paste(  # marca .revisao retirada em 26/11 (texto antes de Resultados)
        "Competitividade, eleição e viabilidade das candidaturas do grupo e do restante das",
        "candidaturas, por cargo e eleição, em % das candidaturas aptas. Competitiva é a",
        "candidatura eleita ou a menos de 0,1 QE do limiar, pela margem de votos ou de gasto, e",
        "viável antes da eleição, a que foi eleita deputada, em qualquer dos dois cargos, ou ficou",
        "a menos de 0,1 QE do limiar na eleição anterior. O restante corresponde aos homens, no",
        "caso das mulheres, e às demais candidaturas, no caso de pessoas negras e de mulheres",
        "negras. Gasto e viabilidade começam em 2018 (—). Totais nacionais, sem o DF.")),
        fonte, "(explorations/ec111-did-2026/R/14 e R/11)."),
  "tbl-descritivo-competitividade-ec111", "descritivo_competitividade.md")

# ------------------------------------------------------------------------------
# 9. Figuras
# ------------------------------------------------------------------------------
tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.3),
        strip.text = element_text(face = "bold", hjust = 0), legend.position = "bottom",
        plot.caption = element_text(colour = "grey40", hjust = 0),
        axis.text = element_text(colour = "grey25"))

# 9a. Efeitos por etapa (2022 e 2026), um painel por grupo
rot_fig <- c(cand = "Candidaturas", rec_partido = "Transferências do partido",
             lexcesso = "Transferências − candidaturas", gasto = "Gasto", voto = "Votos",
             ltcv = "Taxa de competitivas (voto)", ltcg = "Taxa de competitivas (gasto)",
             ltel = "Taxa de eleitas")
f1d <- res |>
  filter(medida %in% names(rot_fig), periodo %in% c("2022", "2026")) |>
  mutate(Variável = factor(rot_fig[medida], rev(rot_fig)),
         Grupo = factor(nome_grupo[grupo], names(cores_gr)), Ano = periodo)
g1 <- ggplot(f1d, aes(att, Variável, colour = Grupo, shape = Ano)) +
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
ggsave(file.path(fig_dir, "efeitos_etapas.png"), g1, width = 8, height = 4.2, dpi = 300,
       bg = "white")

# 9b. Proporção das transferências por cargo e nos dois cargos somados
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

# 9c. Dados brutos de cada variável dependente, na ordem do funil (item 6 do plano):
#     média das listas do painel balanceado de cada variável, por cargo e ano
niv <- le("variaveis_principais_niveis.csv") |> filter(nivel == "lista")
niveis_fig <- function(rot, ylab, arquivo, h, zero = FALSE) {
  d <- niv |> filter(medida %in% names(rot)) |>
    mutate(painel = factor(rot[medida], rot),
           Grupo = factor(nome_grupo[grupo], names(cores_gr)),
           cargo = factor(cargo, c("Federal", "Estadual")))
  stopifnot(!anyNA(d$painel), nrow(d) > 0)
  p <- ggplot(d, aes(ano, media, colour = Grupo, linetype = cargo, shape = cargo)) +
    annotate("rect", xmin = 2020, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "grey95") +
    { if (zero) geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.4) } +
    geom_line(linewidth = 0.6) + geom_point(size = 1.8, fill = "white") +
    facet_wrap(~painel, nrow = 1, scales = "free_y") +
    scale_x_continuous(breaks = c(2014, 2018, 2022, 2026), limits = c(2013, 2027)) +
    scale_y_continuous(labels = \(x) num(x, 0, sinal = zero)) +
    scale_colour_manual(values = cores_gr, name = NULL) +
    scale_linetype_manual(values = c(Federal = "solid", Estadual = "22"), name = NULL) +
    scale_shape_manual(values = c(Federal = 16, Estadual = 21), name = NULL) +
    labs(x = NULL, y = ylab) +
    tema + theme(panel.grid.major.y = element_line(colour = "grey90", linewidth = 0.3),
                 panel.spacing.x = unit(1.2, "lines"))
  ggsave(file.path(fig_dir, arquivo), p, width = 9, height = h, dpi = 300, bg = "white")
}
niveis_fig(c(cand = "Candidaturas", rec_partido = "Transferências do partido",
             gasto = "Gasto", voto = "Votos nominais"),
           "Parcela média do grupo nas listas (%)", "niveis_funil.png", 3.4)
niveis_fig(c(ltcv = "Competitiva pelo voto", ltcg = "Competitiva pelo gasto", ltel = "Eleita"),
           "Taxa do grupo − taxa do restante (p.p.)", "niveis_taxas.png", 3.4, zero = TRUE)

message("Tabelas: ", paste(list.files(tab_dir), collapse = ", "))
message("Figuras: efeitos_etapas.png, transferencias_por_cargo.png, niveis_funil.png, ",
        "niveis_taxas.png")
