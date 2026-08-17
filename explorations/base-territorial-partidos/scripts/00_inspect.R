files <- list.files("data/raw", pattern = "ql_gasto_eleit.*\\.rds", full.names = TRUE)

for (f in files) {
  df <- readRDS(f)
  cat("===", basename(f), "===\n")
  cat("nrow:", nrow(df), " ncol:", ncol(df), "\n")
  cat(paste(names(df), collapse = ", "), "\n")
  cat("QL_gasto_eleit summary:\n")
  print(summary(df$QL_gasto_eleit))
  cat("\n")
}
