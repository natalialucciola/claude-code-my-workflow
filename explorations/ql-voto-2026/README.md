# ql-voto-2026 — Capítulo 6 com QL do voto, incluindo 2026

**Objetivo.** Reproduzir o estudo do Capítulo 6 (*Coordenação territorial de listas
partidárias*) incluindo as eleições de 2026. A medida de base territorial do capítulo, o
quociente locacional do **gasto** de campanha (`QL_gasto_eleit`), não existe ainda para 2026: a
prestação de contas final vence ~30 dias após o pleito e o TSE ainda não a publicou. Esta
exploração refaz o estudo com o quociente locacional do **voto** (`QL_voto`), para 2018, 2022 e
2026, e usa 2018/2022 para validar a troca de medida contra os resultados do capítulo.

**Status:** primeira rodada completa (2026-10-13) — resultados e ressalvas em `SESSION_LOG.md`. Especificação principal em `output/fatia_025/` (figuras em `output/fatia_025/figuras/`). Não altera o `.qmd` nem os outputs do capítulo.

## Medida

Para cada cargo × UF × ano:

```
QL_voto[c, i] = (v[c, i] / V[c]) / (W[i] / W[UF])
```

`v[c, i]` = votos nominais válidos do candidato *c* no município *i*; `V[c]` = total do
candidato; `W[i]`, `W[UF]` = votos nominais válidos do cargo no município e na UF.
A base do candidato é `QL_voto > 1` **e** fatia do município nos votos do candidato ≥ 2,5%.
Só `QL_voto > 1` (o limiar que o capítulo usa para o gasto) gera bases ~10x maiores que as de
gasto e satura a sobreposição; o piso de 2,5% foi escolhido em `R/05b_calibracao_base_voto.R`
contra as lacunas do capítulo em 2018/2022, antes de olhar 2026 (5% e 0 rodam como variantes,
ver `R/config.R`). A sobreposição, a incumbência, a DDD e o alcance usam as definições do
capítulo.

## Ordem de execução (a partir da raiz do repo)

| Script | Faz |
|---|---|
| `R/00_baixar_dados_tse.R` | Baixa votação por candidato/partido (2018, 2022, 2026), candidatos e vagas 2026 para `data/raw/tse/` |
| `R/01_construir_ql_voto.R` | Bases candidato × município com `QL_voto`; resultado 2026 (regra do QE validada em 2022) |
| `R/02_sobreposicao.R` | Sobreposição (município, candidato), gênero, raça, capital, resultado, incumbência |
| `R/03_ddd.R` | DDD: réplica 2018–2022 e modelo de três eleições (2022 e 2026 contra 2018) |
| `R/04_modelo2_alcance.R` | Modelo 2 (sobreposição com incumbente, H4) e alcance territorial (H5) |
| `R/05_validacao_gasto_voto.R` | Concordância gasto × voto em 2018/2022 |
| `R/06_tabelas_graficos.R` | Tabela de lacunas e figuras (`output/figuras/`) |

Dados de entrada além dos zips do TSE: os `.rds` de `data/raw/` já usados pelo capítulo
(candidaturas, eleitos, capitais) — ver `data/README.md`.

## Diferenças em relação ao capítulo

- Medida territorial: voto, não gasto (ver acima).
- Universo: candidatos com ≥ 1 voto nominal válido (o capítulo usa candidatos com gasto).
- Partido em 2026: sigla vigente (MOBILIZA = ex-PMN, DEMOCRATA = ex-PMB, PRD, MISSÃO);
  2018/2022 com `harmonizar_partido()` do capítulo.
- Modelo 3 (liderança formal, SGIP) não refeito nesta rodada.
