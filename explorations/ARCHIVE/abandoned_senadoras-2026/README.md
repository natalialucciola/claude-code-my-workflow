# Abandoned: senadoras-2026 (2026-08-19 – 2026-11-07)

## Why Abandoned
Resultados não promissores (decisão da usuária em 2026-11-07). <!-- REVISAR: detalhar em 1-2 frases quais resultados/sinais motivaram a decisão -->

## What Was Tried
- Plano de pesquisa completo em `docs/plano-pesquisa.md` (4 perguntas de pesquisa sobre o aumento de mulheres candidatas ao Senado em 2026: trajetória histórica, oferta partidária, substituição entre cargos, perfil/experiência), com 9 scripts R esqueleto (`00_setup.R` a `08_checagem_sanidade.R`).
- `00_setup.R` validado (`electionsBR` 0.5.0; `candidate_asset()`/`party_composition()` citadas no plano não existem nesta versão — usar `seats_fed()`).
- Download automático via `electionsBR` bloqueado: `cdn.tse.jus.br` retorna HTTP 403 (Akamai) a clientes não-navegador; o pacote não checa o status HTTP e devolve data frame vazio ("erro 1 na extração a partir de arquivo zip"). Confirmado em 19 e 20/08/2026; mesmo problema na issue #52 do `electionsBR`, sem solução.
- Workaround manual implementado em `scripts/utils_tse.R` (`carregar_zip_candidatos_tse(ano)`, lê zips baixados pelo navegador) e `01_download_candidatos.R` reescrito para usá-lo — nunca testado com dado real.
- Pelo `SESSION_LOG.md`, os scripts `02`–`08` continuam sem lógica implementada.

## Learnings
- [LEARN:dados-tse] `electionsBR` falha em silêncio quando o TSE bloqueia o download (403 do Akamai): retorna 0 linhas em vez de erro. Sempre conferir `nrow()` após baixar; o caminho confiável é baixar o zip pelo navegador em dadosabertos.tse.jus.br e ler localmente (ver `scripts/utils_tse.R`, reaproveitável).
- [LEARN:dados-tse] CEPESPdata (`elections_cepesp()`) também estava quebrado em 09/2025 (issue #53 do `electionsBR`); não contar com ele como fonte alternativa.

## Would Revisiting Require
- Uma pergunta de pesquisa ou um sinal empírico que justifique o artigo (o motivo do abandono foi o resultado, não a infraestrutura).
- Os zips de `consulta_cand` baixados manualmente (vários já estão em `data/raw/tse/` do repo principal) e a implementação dos scripts `02`–`08`.

---

*Conteúdo original do README preservado abaixo.*

# senadoras-2026

> **Projeto independente da tese** — não é uma exploration que "graduará" para um capítulo de `Quarto/thesis/`. Vive em `explorations/` por reusar a infraestrutura do Claude Code deste repo (skills, agents, rules), mas o artefato final é um artigo próprio, para submissão à Revista Dados. Ver `SESSION_LOG.md` para o histórico de sessões.

Projeto de pesquisa: o aumento da presença de mulheres nas candidaturas ao Senado Federal em 2026 — descrição da trajetória histórica (nacional, por UF, por partido) e investigação dos motivos (oferta partidária, substituição entre cargos, perfil/experiência das candidatas). Trabalho preparatório para submissão à Revista Dados.

## Como começar

1. Leia `docs/plano-pesquisa.md` primeiro — é o documento de referência com as perguntas de pesquisa, hipóteses, fontes de dados, plano de variáveis, plano analítico por pergunta, estrutura sugerida do artigo e o checklist de execução (Seção 7 do plano) que os scripts abaixo seguem.
2. Rode os scripts de `scripts/` na ordem numérica. Cada um corresponde a um passo do checklist do plano.
3. Resultados intermediários (dados baixados e tratados) vão para `dados/`; resultados finais (tabelas, gráficos) vão para `outputs/`.

## Estrutura de pastas

```
senadoras-2026/
├── docs/
│   └── plano-pesquisa.md      # documento de referência (perguntas, método, checklist)
├── dados/
│   ├── brutos/                # dados baixados sem tratamento (TSE / electionsBR / CEPESPdata), NÃO editar à mão
│   ├── processados/           # bases já harmonizadas entre anos, prontas para análise
│   └── dicionarios/           # dicionários de "de-para" de nomes de coluna por ano (ver Seção 4 do plano)
├── scripts/                   # um script por etapa do checklist (Seção 7 do plano), numerados em ordem de execução
├── outputs/
│   ├── figuras/                # gráficos para o artigo
│   └── tabelas/                # tabelas para o artigo
└── README.md
```

## Scripts

| Script | Etapa do checklist (plano, Seção 7) |
|---|---|
| `00_setup.R` | Checar pacotes, versão do `electionsBR`, disponibilidade de dados 2026 |
| `01_download_candidatos.R` | Baixar `consulta_cand` de todos os anos/cargos do escopo |
| `02_harmoniza_schema.R` | Validar e harmonizar nomes de coluna entre anos; gerar dicionário |
| `03_painel_candidato.R` | Construir painel de candidatos por CPF (experiência prévia) |
| `04_tamanho_partido.R` | Construir base de tamanho de bancada por partido/ano |
| `05_analise_pp1_descritiva.R` | Séries históricas nacional/UF/partido + testes de proporção |
| `06_analise_pp2_pp3.R` | Modelos de tamanho de partido e substituição entre cargos |
| `07_analise_pp4_perfil.R` | Comparação de perfil/experiência das candidatas |
| `08_checagem_sanidade.R` | Conferir números do pipeline contra os números já apurados manualmente (ver plano, Seção 7, item 9) |

Cada script está com um cabeçalho descrevendo objetivo, inputs e outputs esperados — preencher a lógica de cada um segue o plano analítico da Seção 5 do documento de referência.

## Status

Projeto criado em preparação; nenhum script foi executado ainda. Nenhum dado foi baixado. Ver `docs/plano-pesquisa.md` para o plano completo antes de rodar.
