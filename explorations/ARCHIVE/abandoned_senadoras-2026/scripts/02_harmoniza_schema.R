# =============================================================================
# 02_harmoniza_schema.R
# Objetivo: validar e harmonizar os nomes/valores de coluna entre anos (o
#           layout do TSE muda ao longo do tempo), filtrar para os cargos do
#           escopo (Senador + cargos de comparação da PP3: Deputado Federal,
#           Governador, Vice-Governador, Presidente, Vice-Presidente) e
#           produzir uma base única empilhada. Ver plano, Seção 3 e 4.
#
# Inputs:  dados/brutos/candidatos_<ano>.rds
# Outputs: dados/processados/candidatos_painel_bruto.rds (todas as colunas
#            harmonizadas, todos os cargos do escopo, todos os anos)
#          dados/dicionarios/dicionario_colunas.csv (registro do de-para
#            de nomes de coluna por ano, para auditoria/reprodutibilidade)
# =============================================================================

library(dplyr)
library(purrr)
library(janitor)
library(readr)

arquivos <- list.files("dados/brutos", pattern = "^candidatos_\\d{4}\\.rds$", full.names = TRUE)

# TODO: para cada arquivo, rodar janitor::clean_names() e depois inspecionar
# manualmente quais colunas correspondem a: ano da eleição, cargo, UF,
# partido, coligação/federação, sexo/gênero, situação de candidatura,
# situação de totalização, idade, grau de instrução, ocupação, raça/cor,
# CPF do candidato. Registrar o mapeamento (nome original -> nome
# padronizado) em dados/dicionarios/dicionario_colunas.csv à medida que for
# descobrindo, para não ter que redescobrir a cada execução.
#
# Nomes padronizados sugeridos (usar estes daqui pra frente no projeto):
#   ano, cargo, uf, partido, coligacao_federacao, sexo, sit_candidatura,
#   sit_totalizacao, idade, grau_instrucao, ocupacao, raca_cor, cpf_candidato

CARGOS_ESCOPO <- c(
  "SENADOR", "DEPUTADO FEDERAL", "GOVERNADOR", "VICE-GOVERNADOR",
  "PRESIDENTE", "VICE-PRESIDENTE"
)

# TODO: implementar a função de harmonização por ano e o empilhamento (bind_rows)
# harmoniza_um_ano <- function(caminho) { ... }
# painel_bruto <- map_dfr(arquivos, harmoniza_um_ano)
# painel_bruto <- painel_bruto %>% filter(cargo %in% CARGOS_ESCOPO)

# saveRDS(painel_bruto, "dados/processados/candidatos_painel_bruto.rds")

# --- Checagem de sanidade rápida (rodar depois de implementar acima) -----
# table(painel_bruto$ano, painel_bruto$sexo)
# Comparar contra os números já apurados manualmente na conversa que gerou
# este projeto: 69 candidatas mulheres ao Senado em 2026 (22% do total de
# 315 candidaturas). Ver checklist item 9 no plano — essa validação também
# será refeita com mais detalhe em 08_checagem_sanidade.R.
