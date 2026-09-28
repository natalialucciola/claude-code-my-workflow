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

## Active Projects

- `base-territorial-partidos/` — sandbox de tese; graduou para `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd`, permanece como registro do processo investigativo.
- `competitividade-gasto/` — sandbox de tese; medida de competitividade da candidatura baseada em gasto (não em votos), comparável entre Deputado Federal e Estadual, 2018/2022.
- `senadoras-2026/` — **projeto independente da tese** (artigo próprio, submissão à Revista Dados). Vive aqui só para reusar a infraestrutura de skills/agents; não vai "graduar" para um capítulo. Ver `senadoras-2026/README.md`.
