# =============================================================================
# 01 — Importa votação de Deputado Federal, Estadual e Distrital (TSE), 2014–2026
#
# Entrada (data/raw/tse/, zips de dados abertos do TSE — ver PLANO):
#   votacao_candidato_munzona_{ano}.zip, votacao_partido_munzona_{ano}.zip,
#   perfil_eleitorado_{ano}.zip, consulta_cand_2026.zip
#   data/raw/candidatos{ano}.rds e candidatos_estadual_{ano}.rds (gênero/raça 2014–2022)
# Saída (data/processed/):
#   margem_cand.rds      uma linha por candidatura (votos nominais válidos, apta a cadeira,
#                        situação do TSE, lista, gênero, raça)
#   margem_listas.rds    uma linha por lista (SQ_COLIGACAO): votos totais (nominais + legenda)
#   margem_distritos.rds uma linha por UF × cargo × ano: cadeiras, votos válidos, eleitorado
#
# Rodar da raiz do repositório:
#   Rscript explorations/competitividade-eleitoral/R/01_importar_votacao.R
# =============================================================================
library(data.table)

dir_tse <- file.path("data", "raw", "tse")
dir_out <- file.path("data", "processed")
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)
anos    <- c(2014L, 2018L, 2022L, 2026L)
cargos  <- c(6L, 7L, 8L)            # Federal, Estadual, Distrital
ufs     <- c("AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA", "MG", "MS", "MT",
             "PA", "PB", "PE", "PI", "PR", "RJ", "RN", "RO", "RR", "RS", "SC", "SE", "SP", "TO")

# Lê um CSV de dentro do zip, só com as colunas pedidas (as que existirem)
ler_zip <- function(zip, csv, cols) {
  td <- tempfile(); dir.create(td); on.exit(unlink(td, recursive = TRUE))
  unzip(zip, csv, exdir = td)
  arq <- file.path(td, csv)
  disp <- names(fread(arq, nrows = 0L, encoding = "Latin-1"))
  fread(arq, select = intersect(cols, disp), encoding = "Latin-1", colClasses = "character")
}
num <- function(x) as.numeric(x)

# --- 1. Votação por candidato ----------------------------------------------
cols_cand <- c("ANO_ELEICAO", "SG_UF", "CD_CARGO", "DS_CARGO", "SQ_CANDIDATO", "NR_CANDIDATO",
               "NM_CANDIDATO", "NM_URNA_CANDIDATO", "NR_PARTIDO", "SG_PARTIDO", "SQ_COLIGACAO",
               "NM_COLIGACAO", "NR_FEDERACAO", "SG_FEDERACAO", "DS_SITUACAO_CANDIDATURA",
               "DS_SIT_TOT_TURNO", "QT_VOTOS_NOMINAIS", "QT_VOTOS_NOMINAIS_VALIDOS",
               "NM_TIPO_DESTINACAO_VOTOS")

cand <- rbindlist(lapply(anos, function(a) {
  zip <- file.path(dir_tse, sprintf("votacao_candidato_munzona_%d.zip", a))
  rbindlist(lapply(ufs, function(u) {
    x <- ler_zip(zip, sprintf("votacao_candidato_munzona_%d_%s.csv", a, u), cols_cand)
    x <- x[as.integer(CD_CARGO) %in% cargos]
    if (a == 2014L) {
      # 2014 não tem destinação: o voto nominal vale para a candidatura apta
      x[, `:=`(QT_VOTOS_NOMINAIS_VALIDOS = QT_VOTOS_NOMINAIS,
               NM_TIPO_DESTINACAO_VOTOS = fifelse(DS_SITUACAO_CANDIDATURA == "APTO",
                                                  "Válido", "Inapto"))]
    }
    x[, .(votos = sum(num(QT_VOTOS_NOMINAIS_VALIDOS), na.rm = TRUE),
          # apta a receber cadeira: algum voto com destinação "Válido" (nominal)
          apta = any(NM_TIPO_DESTINACAO_VOTOS == "Válido")),
      by = .(ano = as.integer(ANO_ELEICAO), uf = SG_UF, cd_cargo = as.integer(CD_CARGO),
             sq_candidato = SQ_CANDIDATO, nr_candidato = NR_CANDIDATO, nome = NM_CANDIDATO,
             nome_urna = NM_URNA_CANDIDATO, nr_partido = NR_PARTIDO, sg_partido = SG_PARTIDO,
             sq_lista = SQ_COLIGACAO, nm_lista = NM_COLIGACAO, situacao = DS_SITUACAO_CANDIDATURA,
             sit_tot = DS_SIT_TOT_TURNO, destinacao = NM_TIPO_DESTINACAO_VOTOS)]
  }))
}), fill = TRUE)

# Um candidato pode ter linhas com destinações diferentes (ex.: parte anulada); consolida
cand <- cand[, .(votos = sum(votos[destinacao == "Válido"]), apta = any(apta),
                 destinacao = paste(sort(unique(destinacao)), collapse = " | ")),
             by = .(ano, uf, cd_cargo, sq_candidato, nr_candidato, nome, nome_urna, nr_partido,
                    sg_partido, sq_lista, nm_lista, situacao, sit_tot)]
cand[, cargo := fcase(cd_cargo == 6L, "Federal", cd_cargo == 7L, "Estadual",
                      cd_cargo == 8L, "Distrital")]
cand[, eleito_tse := sit_tot %chin% c("ELEITO POR QP", "ELEITO POR MÉDIA", "ELEITO")]
stopifnot(!anyDuplicated(cand[, .(ano, sq_candidato)]))

# --- 2. Votação por partido (votos da lista = nominais válidos + legenda) ---
cols_part <- c("ANO_ELEICAO", "SG_UF", "CD_CARGO", "NR_PARTIDO", "SG_PARTIDO", "SQ_COLIGACAO",
               "NM_COLIGACAO", "NR_FEDERACAO", "QT_VOTOS_NOMINAIS", "QT_VOTOS_LEGENDA",
               "QT_VOTOS_NOMINAIS_VALIDOS", "QT_TOTAL_VOTOS_LEG_VALIDOS")
part <- rbindlist(lapply(anos, function(a) {
  zip <- file.path(dir_tse, sprintf("votacao_partido_munzona_%d.zip", a))
  rbindlist(lapply(ufs, function(u) {
    x <- ler_zip(zip, sprintf("votacao_partido_munzona_%d_%s.csv", a, u), cols_part)
    x <- x[as.integer(CD_CARGO) %in% cargos]
    if (a == 2014L) {
      x[, `:=`(QT_VOTOS_NOMINAIS_VALIDOS = QT_VOTOS_NOMINAIS,
               QT_TOTAL_VOTOS_LEG_VALIDOS = QT_VOTOS_LEGENDA)]
    }
    x[, .(nominais = sum(num(QT_VOTOS_NOMINAIS_VALIDOS), na.rm = TRUE),
          legenda  = sum(num(QT_TOTAL_VOTOS_LEG_VALIDOS), na.rm = TRUE)),
      by = .(ano = as.integer(ANO_ELEICAO), uf = SG_UF, cd_cargo = as.integer(CD_CARGO),
             nr_partido = NR_PARTIDO, sg_partido = SG_PARTIDO, sq_lista = SQ_COLIGACAO)]
  }))
}), fill = TRUE)

listas <- part[, .(votos_lista = sum(nominais + legenda), nominais_lista = sum(nominais),
                   legenda_lista = sum(legenda), n_partidos = .N),
               by = .(ano, uf, cd_cargo, sq_lista)]

# --- 3. Eleitorado por UF ---------------------------------------------------
eleitorado <- rbindlist(lapply(anos, function(a) {
  zip <- file.path(dir_tse, sprintf("perfil_eleitorado_%d.zip", a))
  nomes <- unzip(zip, list = TRUE)$Name
  # 2014 e 2018: um CSV nacional; 2022 e 2026: um CSV por UF
  arqs <- intersect(sprintf("perfil_eleitorado_%d_%s.csv", a, ufs), nomes)
  if (!length(arqs)) arqs <- sprintf("perfil_eleitorado_%d.csv", a)
  rbindlist(lapply(arqs, function(f) {
    # a coluna se chama QT_ELEITORES_PERFIL (2014, 2018) ou QT_ELEITORES (2022, 2026)
    x <- ler_zip(zip, f, c("SG_UF", "QT_ELEITORES_PERFIL", "QT_ELEITORES"))
    setnames(x, intersect(c("QT_ELEITORES_PERFIL", "QT_ELEITORES"), names(x)), "qt")
    x[SG_UF %chin% ufs, .(eleitorado = sum(num(qt), na.rm = TRUE)), by = .(uf = SG_UF)]
  }))[, .(eleitorado = sum(eleitorado)), by = uf][, ano := a]
}))

# --- 4. Distritos -----------------------------------------------------------
distritos <- cand[, .(cadeiras = sum(eleito_tse), n_cand = .N), by = .(ano, uf, cd_cargo, cargo)]
distritos <- merge(distritos, listas[, .(validos = sum(votos_lista)), by = .(ano, uf, cd_cargo)],
                   by = c("ano", "uf", "cd_cargo"))
distritos <- merge(distritos, eleitorado, by = c("ano", "uf"), all.x = TRUE)

# Conferência das cadeiras de 2026 com consulta_vagas
vagas26 <- ler_zip(file.path(dir_tse, "consulta_vagas_2026.zip"), "consulta_vagas_2026_BRASIL.csv",
                   c("SG_UF", "CD_CARGO", "QT_VAGA"))[as.integer(CD_CARGO) %in% cargos]
chk <- merge(distritos[ano == 2026L], vagas26[, .(uf = SG_UF, cd_cargo = as.integer(CD_CARGO),
                                                   qt_vaga = as.integer(QT_VAGA))],
             by = c("uf", "cd_cargo"))
if (nrow(chk[cadeiras != qt_vaga])) {
  warning("Cadeiras de 2026 diferentes de consulta_vagas:")
  print(chk[cadeiras != qt_vaga])
}
message("Cadeiras por cargo e ano:")
print(dcast(distritos, ano ~ cargo, value.var = "cadeiras", fun.aggregate = sum))

# --- 5. Gênero e raça -------------------------------------------------------
perfil <- rbindlist(lapply(c(2014L, 2018L, 2022L), function(a) {
  rbind(as.data.table(readRDS(file.path("data", "raw", sprintf("candidatos%d.rds", a)))),
        as.data.table(readRDS(file.path("data", "raw", sprintf("candidatos_estadual_%d.rds", a)))),
        fill = TRUE)[, .(ano = a, sq_candidato = as.character(sq_candidato), genero, raca)]
}))
cc26 <- ler_zip(file.path(dir_tse, "consulta_cand_2026.zip"), "consulta_cand_2026_BRASIL.csv",
                c("SQ_CANDIDATO", "CD_CARGO", "DS_GENERO", "DS_COR_RACA"))
perfil <- rbind(perfil, cc26[as.integer(CD_CARGO) %in% cargos,
                             .(ano = 2026L, sq_candidato = SQ_CANDIDATO, genero = DS_GENERO,
                               raca = DS_COR_RACA)])
perfil <- unique(perfil, by = c("ano", "sq_candidato"))
cand <- merge(cand, perfil, by = c("ano", "sq_candidato"), all.x = TRUE)
message("Cobertura de gênero por ano e cargo (proporção com gênero informado):")
print(cand[, .(cobertura = round(mean(!is.na(genero)), 4)), by = .(ano, cargo)][order(ano, cargo)])

cand[, `:=`(mulher = genero == "FEMININO",
            negra  = raca %chin% c("PRETA", "PARDA"))]

saveRDS(cand, file.path(dir_out, "margem_cand.rds"))
saveRDS(listas, file.path(dir_out, "margem_listas.rds"))
saveRDS(distritos, file.path(dir_out, "margem_distritos.rds"))
message("Candidaturas: ", nrow(cand), " | listas: ", nrow(listas), " | distritos: ", nrow(distritos))
