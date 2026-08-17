out <- "explorations/base-territorial-partidos/output"
cat("=== tab_genero (cargo x ano) ===\n")
print(readRDS(file.path(out, "tab_taxa_sobreposicao_genero.rds")))
cat("\n=== teste_t_genero (cargo x ano) ===\n")
print(readRDS(file.path(out, "teste_t_genero.rds")))
cat("\n=== tab_raca (cargo x ano) ===\n")
print(readRDS(file.path(out, "tab_taxa_sobreposicao_raca.rds")))
cat("\n=== teste_t_raca (cargo x ano) ===\n")
print(readRDS(file.path(out, "teste_t_raca.rds")))
