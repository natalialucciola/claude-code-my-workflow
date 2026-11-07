# Explorations

This folder is a **sandbox** for experimental and exploratory work. All new ideas, prototypes, and research experiments go here first — never directly into production folders.

## How It Works

1. **Create a subfolder** for each exploration (e.g., `explorations/new-estimator/`)
2. **Work freely** — lower quality threshold (60/100) during exploration
3. **Decide:** graduate to production (80/100 required), keep exploring, or archive

## Rules

- See `.claude/rules/exploration-folder-protocol.md` for the full protocol
- See `.claude/rules/exploration-fast-track.md` for the lightweight workflow

## Structure

```
explorations/
├── [active-project]/       # Work in progress
│   ├── README.md           # Goal, hypotheses, status
│   ├── R/                  # Experimental code
│   ├── scripts/            # Test scripts
│   └── output/             # Results
└── ARCHIVE/                # Completed or abandoned
    ├── completed_[name]/   # Graduated to production
    └── abandoned_[name]/   # Documented why stopped
```

## Inventário (sumário da tese aprovado em 2026-11-07)

Cada pasta abaixo está no `main`, inclusive o que **não** entrou em capítulo — para consulta e reuso.

### Alimentam capítulos da tese

| Pasta | Capítulo | O que ficou só aqui (não está no capítulo) |
|---|---|---|
| `cap2-descritivo/` | 2 — `02-analise-descritiva.qmd` | Bases intermediárias (gitignored, regeneráveis por `R/01–03`). As tabelas e figuras do capítulo são **geradas por** `R/04_tabelas_figuras.R`. |
| `competitividade-eleitoral/` | 3 — `03-ec111-competitividade-eleitoral.qmd` | Estudo ABD × LSS das medidas; **margem de gasto OLPR (A), D2, D3 e tripla diferença do gasto 2014–2022** (`R/10`–`R/14`, seção "Competitividade pelo gasto derivada da margem OLPR" do README) — ainda não usada no capítulo. |
| `ec111-did-2026/` | 3 — `03-ec111-competitividade-eleitoral.qmd` | Relatório HTML do estudo; figuras por UF. |
| `ql-voto-2026/` | 4 — `04-sobreposicao-territorial-voto.qmd` | O capítulo usa a fatia de piso 2,5% (`output/fatia_025/`) e a robustez de 5%; as fatias `fatia_000/` e `fatia_050/` ficam só aqui. |
| `base-territorial-partidos/` | 5 — `05-sobreposicao-territorial-partido.qmd` | Registro do processo investigativo (bugs, diagnósticos, versões superadas). Scripts de produção em `scripts/R/sobreposicao_territorial_partido/`. |

### Explorações de tese sem capítulo (por enquanto)

| Pasta | Conteúdo | Estado |
|---|---|---|
| `competitividade-gasto/` | Competitividade da candidatura medida pelo gasto (`pct_teto`, `razao_min`, `razao_p10`, `pctl_uf`), DiD 2×2 2018→2022 e placebo 2014. | Antecessora de `ec111-did-2026/`; etapa 1 concluída (2026-09-28). |
| `ec111-did-ql-municipio/` | DiD da EC 111 com QL do voto por município, painel 2010–2026; entrada em território novo decomposta por grupo. | Ativa; decisões em aberto em `quality_reports/plans/2026-10-14_did-ec111-ql-municipio.md`. |

Os antigos placeholders de capítulo (Dados e Métodos; Índice G/QL; Alinhamento gasto-voto; Gasto na base territorial do partido) foram removidos em 2026-11-07 — continham só o título, não havia texto a preservar.

### Fora da tese

- `senadoras-2026/` — **projeto independente da tese** (artigo próprio, submissão à Revista Dados). Vive aqui só para reusar a infraestrutura de skills/agents; não vai "graduar" para um capítulo. Ver `senadoras-2026/README.md`.
