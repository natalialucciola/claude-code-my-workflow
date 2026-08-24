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
