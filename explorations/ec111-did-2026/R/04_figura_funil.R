# ==============================================================================
# Figura-síntese do funil para o Cap. 3: efeito da EC 111 em 2022 e em 2026 por
# estágio (candidaturas → receita → gasto → votos), um painel por grupo.
#
# Lê output/did_2026_resultados.csv (script 03); não reestima nada.
# Listas partido × UF × cargo, painel balanceado, sem ponderação; IC 95% pontual.
#
# Rodar da raiz, depois de 03_did_event_study.R:
#   Rscript explorations/ec111-did-2026/R/04_figura_funil.R
# Saída: output/did_2026_funil_sintese.{png,pdf}
# ==============================================================================

library(tidyverse)

out_dir <- "explorations/ec111-did-2026/output"
res <- read_csv2(file.path(out_dir, "did_2026_resultados.csv"), show_col_types = FALSE)

estagios <- c(cand = "Candidaturas", rec_total = "Receita total",
              rec_partido = "Transferências do partido", gasto = "Gasto",
              voto = "Votos nominais")
cores_gr <- c("Mulheres" = "#eb6834", "Pessoas negras" = "#2a78d6", "Mulheres negras" = "#7b3f99")

d <- res |>
  filter(nivel == "lista", !ponderado, balanceado, medida %in% names(estagios),
         periodo %in% c("2022", "2026"), grupo %in% names(cores_gr)) |>
  mutate(estagio = factor(unname(estagios[medida]), levels = rev(estagios)),
         grupo = factor(grupo, levels = names(cores_gr)),
         periodo = factor(periodo, levels = c("2026", "2022")),
         provisorio = medida %in% c("rec_total", "rec_partido", "gasto") & periodo == "2026")
stopifnot(nrow(d) == length(estagios) * 3L * 2L)

p <- ggplot(d, aes(x = att, y = estagio, colour = grupo, shape = periodo)) +
  geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.4) +
  geom_linerange(aes(xmin = ic_inf, xmax = ic_sup), position = position_dodge(width = 0.6),
                 linewidth = 0.7) +
  geom_point(aes(fill = periodo), position = position_dodge(width = 0.6), size = 2.2, stroke = 0.9) +
  facet_wrap(~grupo, nrow = 1) +
  scale_colour_manual(values = cores_gr, guide = "none") +
  scale_shape_manual(values = c("2022" = 21, "2026" = 24), name = NULL,
                     breaks = c("2022", "2026")) +
  scale_fill_manual(values = c("2022" = "white", "2026" = "grey30"), name = NULL,
                    breaks = c("2022", "2026")) +
  labs(x = "Efeito estimado, federal × estadual, base 2018 (pontos percentuais da lista)", y = NULL,
       caption = paste0("Fonte: TSE. Callaway & Sant'Anna (pacote did); listas partido × UF balanceadas, ",
                        "sem DF, sem ponderação; barras: IC 95% pontual (EP agrupados por lista).\n",
                        "Receita, transferências e gasto de 2026: prestação de contas final ",
                        "(TSE, arquivo de 08/11/2026).")) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0, size = 10),
        legend.position = "top", legend.justification = "left",
        plot.caption = element_text(colour = "grey40", hjust = 0), plot.caption.position = "plot",
        panel.spacing.x = unit(1.2, "lines"))

ggsave(file.path(out_dir, "did_2026_funil_sintese.png"), p, width = 10, height = 4.2, dpi = 300,
       bg = "white")
ggsave(file.path(out_dir, "did_2026_funil_sintese.pdf"), p, width = 10, height = 4.2)
message("Figura-síntese do funil salva em ", out_dir)
