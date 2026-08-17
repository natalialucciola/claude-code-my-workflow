files <- c(
  "data/raw/candidatos2018.rds",
  "data/raw/candidatos_estadual_2014.rds",
  "data/raw/candidatos_estadual_2018.rds",
  "data/raw/eleitos_e_compet_est_2014_df.rds",
  "data/raw/eleitos_e_compet_est_2018_df.rds",
  "data/raw/ids_municipios_ibge.rds"
)

for (f in files) {
  df <- readRDS(f)
  cat("===", f, "===\n")
  cat("nrow:", nrow(df), " ncol:", ncol(df), "\n")
  cat(paste(names(df), collapse = ", "), "\n\n")
}

cat("--- ids_municipios_ibge: sample rows ---\n")
print(head(readRDS("data/raw/ids_municipios_ibge.rds"), 5))

cat("\n--- eleitos_e_compet_est_2018_df: sample rows ---\n")
print(head(readRDS("data/raw/eleitos_e_compet_est_2018_df.rds"), 5))

cat("\n--- candidatos2018: situacao_candidatura values ---\n")
print(table(readRDS("data/raw/candidatos2018.rds")$situacao_candidatura, useNA = "always"))
