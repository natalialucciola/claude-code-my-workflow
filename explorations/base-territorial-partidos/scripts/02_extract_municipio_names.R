# Extrai um crosswalk enxuto (COD_MUN_TSE, SG_UF, municipio) do arquivo bruto
# de gasto federal 2018, só para poder identificar capitais por nome.
# O arquivo bruto (gasto_brasil_2018_TEMP.rds) é apagado depois de extrair.

library(dplyr)

df <- readRDS("data/raw/gasto_brasil_2018_TEMP.rds")
cat("Colunas disponíveis:", paste(names(df), collapse = ", "), "\n")

crosswalk <- df |>
  distinct(SG_UF, COD_MUN_TSE, municipio) |>
  arrange(SG_UF, municipio)

cat("Linhas no crosswalk:", nrow(crosswalk), "\n")
cat("UFs cobertas:", n_distinct(crosswalk$SG_UF), "\n")

saveRDS(crosswalk, "data/raw/municipios_nomes.rds")

# Lista oficial das 27 capitais (26 estados + DF)
capitais <- tibble::tribble(
  ~SG_UF, ~capital,
  "AC", "Rio Branco",
  "AL", "Maceió",
  "AP", "Macapá",
  "AM", "Manaus",
  "BA", "Salvador",
  "CE", "Fortaleza",
  "DF", "Brasília",
  "ES", "Vitória",
  "GO", "Goiânia",
  "MA", "São Luís",
  "MT", "Cuiabá",
  "MS", "Campo Grande",
  "MG", "Belo Horizonte",
  "PA", "Belém",
  "PB", "João Pessoa",
  "PR", "Curitiba",
  "PE", "Recife",
  "PI", "Teresina",
  "RJ", "Rio de Janeiro",
  "RN", "Natal",
  "RS", "Porto Alegre",
  "RO", "Porto Velho",
  "RR", "Boa Vista",
  "SC", "Florianópolis",
  "SP", "São Paulo",
  "SE", "Aracaju",
  "TO", "Palmas"
)

normalizar_nome <- function(x) {
  x |> toupper() |> iconv(from = "UTF-8", to = "ASCII//TRANSLIT")
}

crosswalk <- crosswalk |> mutate(municipio_norm = normalizar_nome(municipio))
capitais <- capitais |> mutate(capital_norm = normalizar_nome(capital))

match_capitais <- capitais |>
  left_join(crosswalk, by = c("SG_UF", "capital_norm" = "municipio_norm"))

cat("\n--- Match de capitais (deveria ser 27 linhas, todas com COD_MUN_TSE) ---\n")
print(match_capitais, n = Inf)
cat("\nCapitais sem match:", sum(is.na(match_capitais$COD_MUN_TSE)), "\n")

saveRDS(match_capitais |> filter(!is.na(COD_MUN_TSE)) |> select(SG_UF, COD_MUN_TSE, capital),
        "data/raw/capitais.rds")
