# CLAUDE.MD -- Academic Project Development with Claude Code

<!-- HOW TO USE: Replace [BRACKETED PLACEHOLDERS] with your project info.
     Keep this file under ~150 lines — Claude loads it every session.
     See the guide at docs/workflow-guide.html for full documentation. -->

**Project:** Tese Nat — Sub-representação de Gênero/Raça na Política Brasileira (codename: `tese_nat`)
**Institution:** IESP-UERJ (Instituto de Estudos Sociais e Políticos, Universidade do Estado do Rio de Janeiro)
**Branch:** main

## Sobre o Projeto

Tese de doutorado em Ciência Política sobre os determinantes da sub-representação de gênero e raça na política brasileira e a inefetividade de políticas de representação afirmativa, com métodos quantitativos ligados à geografia do financiamento de campanha e à geografia do voto (candidaturas a Deputado Federal e Estadual, eleições 2014/2018/2022). Artefato principal: um Quarto book (`Quarto/thesis/`), prosa em português.

---

## Core Principles

- **Plan first** -- enter plan mode before non-trivial tasks; save plans to `quality_reports/plans/`
- **Verify after** -- render and confirm output at the end of every task
- **Single source of truth** -- `Quarto/thesis/` is authoritative for the manuscript; `Thesis_Template/` (IESP-UERJ LaTeX class) is a reference copy, not yet wired into any build
- **Quality gates** -- nothing ships below 80/100
- **[LEARN] tags** -- when corrected, save `[LEARN:category] wrong → right` to [MEMORY.md](MEMORY.md) (generic patterns only) or `.claude/state/personal-memory.md` (project-specific, gitignored)

Cross-session context lives in [MEMORY.md](MEMORY.md); past plans, specs, and session logs are in [quality_reports/](quality_reports/).

---

## Working Preferences

- **Rigor over speed** — structured, precise collaboration even if slower; don't shortcut verification.
- **Publication-ready visuals** — every figure meets a publication-polish bar, no default-theme placeholders in anything shared.
- **Memory discipline** — corrections become `[LEARN]` entries; don't ask the same decision twice.
- **Autonomy after plan approval** — once a plan is approved, work independently ("contractor mode"); only surface genuine ambiguity or decisions.
- **Check-in cadence** — more frequent check-ins during the first few sessions while the workflow is new, tapering as it becomes familiar.

---

## Folder Structure

```
tese_nat/
├── CLAUDE.md
├── .claude/                     # Rules, skills, agents, hooks
├── Bibliography_base.bib        # Centralized bibliography
├── Figures/                     # Legacy Beamer figures (unused by the book — see note below)
├── Quarto/
│   ├── thesis/                  # PRIMARY ARTIFACT — Quarto book (chapters, _quarto.yml)
│   │   └── Figures/[NN-chapter]/  # Chapter figures — MUST live inside the project tree (see note below)
│   └── theme-template.scss      # Slide theme (retained; not used by the book)
├── Thesis_Template/              # IESP-UERJ official LaTeX class (reference; not wired into the book build yet)
├── data/                        # Migrated .rds data — incremental, on-demand, gitignored
├── scripts/R/                   # R analysis scripts — migrated incrementally
├── master_supporting_docs/      # Literature PDFs, existing papers
├── docs/                        # GitHub Pages (auto-generated)
├── quality_reports/             # Plans, session logs, merge reports, decision records
├── explorations/                # Research sandbox (see rules)
├── templates/                   # Session log, quality report templates
└── Slides/, Preambles/          # Legacy Beamer infra — kept, currently unused by the thesis
```

---

## Commands

```bash
# Render the thesis Quarto book
quarto render Quarto/thesis
quarto preview Quarto/thesis

# Quality score
python scripts/quality_score.py Quarto/thesis/chapters/file.qmd

# Surface-count sync (README ↔ CLAUDE.md ↔ guide ↔ landing page)
./scripts/check-surface-sync.sh

# Página "Estado dos Capítulos" (gera _site/; publicar conforme o README)
python scripts/estado_capitulos/gerar.py            # --status | --marcar-publicado
```

**Página "Estado dos Capítulos":** https://claude.ai/artifact/8HGZSw58Vv8Lq9tmhjKsPc — resumo por capítulo com links para o HTML e o `.qmd`. Hooks em `.claude/settings.json` avisam Claude para republicá-la quando há commit novo no `main` nos caminhos da tese; procedimento em `scripts/estado_capitulos/README.md`, dados qualitativos em `quality_reports/estado-capitulos/capitulos.json`.

**Data/scripts migration policy:** R scripts and data migrate from the author's separate analysis project incrementally, one analysis at a time as it's actively used — never referenced by absolute path (`.claude/rules/content-invariants.md` INV-10). Migrated files land in `scripts/R/` and `data/`. See `data/README.md`.

---

## Quality Thresholds (advisory)

| Score | Checkpoint | Meaning |
|-------|------|---------|
| 80 | Commit | Good enough to save |
| 90 | PR | Ready for deployment |
| 95 | Excellence | Aspirational |

Enforced by `/commit` (halts + asks for override) **and** — once you run `./scripts/install-hooks.sh` — by a real git pre-commit hook (`.githooks/pre-commit`) that runs the surface-sync + quality (≥80) gates on every commit. Bypass sparingly with `SKIP_QUALITY_GATE=1` or `--no-verify`.

---

## Skills Quick Reference

The full table of all skills lives in [README.md](README.md#skills-claudeskills). Most-used, by workflow:

- **Writing / manuscript:** `/review-paper` (`--peer`) `/seven-pass-review` `/verify-claims` `/proofread` `/humanize` `/deploy`
- **Data / reproducibility:** `/data-analysis` `/audit-reproducibility` `/diagnose` `/review-r` `/capture-environment`
- **Research / literature:** `/interview-me` `/lit-review` `/research-ideation` `/validate-bib`
- **Meta / workflow:** `/commit` `/learn` `/new-skill` `/checkpoint` `/context-status` `/deep-audit` `/coauthor-brief`

R packages (`/r-package-check`) and more — see the README for the complete index. Slide-oriented skills (`/create-lecture`, `/compile-latex`, `/slide-excellence`) remain available for a future defense/qualifying-exam deck, but aren't part of the thesis-writing workflow.

---

## Quarto Book Conventions

- Cross-reference chapters/sections with `@sec-...` labels, not hardcoded numbers. Give section labels a chapter-specific prefix (e.g. `#sec-metodos-[chapter-slug]`) — a generic label like `#sec-dados-metodos` will collide once Chapter 2 is actually written.
- Use `.callout-note` / `.callout-important` for methodological asides instead of ad hoc formatting.
- One `.qmd` per chapter under `Quarto/thesis/chapters/`, numbered by intended order (`00-`, `01-`, ...).
- **Figures MUST live inside the Quarto project tree** (`Quarto/thesis/Figures/[NN-chapter-slug]/`), not the repo-root `Figures/`. Confirmed empirically (2026-08-15, Chapter 6): Quarto's book HTML build only copies and path-adjusts image resources that live inside the project directory (where `_quarto.yml` sits) — an image referenced from outside it (e.g. repo-root `Figures/`) renders as a broken link with no build error or warning. From a chapter file, reference as `../Figures/[NN-chapter-slug]/file.png`.
- PDF output via the IESP-UERJ class (`Thesis_Template/repUERJ.cls`) is not yet wired up — the book currently renders to HTML only. See `Thesis_Template/README.md`.

---

## Estado Atual — Capítulos

| Capítulo | Arquivo | Status | Conteúdo-chave |
| --- | --- | --- | --- |
| 0: Introdução | `chapters/00-introducao.qmd` | placeholder | — |
| 1: Revisão de Literatura | `chapters/01-revisao-literatura.qmd` | **rascunho** | 4 blocos: (I) fundamentos e tipologia de ação afirmativa por quê/como/onde (Pitkin, Htun, Krook, Dahlerup & Freidenvall, paridade latino-americana via Piscopo) + outras dimensões (raça, deficiência, povos indígenas, LGBTQIA+); (II) evidência comparada (Colômbia, Índia, Ruanda) e sínteses sistemáticas (Clayton, Schotte, Su & Chen); (III) trajetória legal brasileira de 30 anos (5 estações) e desenho eleitoral (lista aberta, Wylie & Santos). Reestruturado e revisado a partir dos 15+6 comentários em PDF da autora (02-05/09). Pendente: CoVe nas citações novas, decisão sobre termos em inglês remanescentes (*fast track*, *standing for*/*acting for*), proofread pós-reestruturação |
| 2: Panorama Descritivo, 2014–2026 | `chapters/02-analise-descritiva.qmd` | **rascunho** (de `explorations/cap2-descritivo/`) | Descritivo, sem hipóteses: mulheres, negros e mulheres negras em candidaturas, eleitos, sucesso/competitividade, financiamento (2014–2022; 2026 pendente da prestação de contas), votos e geografia (região/UF, magnitude, base de voto 2014–2026, base de gasto 2018–2022), partidos (12 maiores + blocos ideológicos de Bolognesi et al. 2025). Tabelas geradas por script em `chapters/_tabelas-cap2/` (incluídas, não digitadas). Pendente: CoVe nas 2 referências novas, proofread, financiamento 2026 |
| 3: EC 111 e Competitividade Eleitoral | `chapters/03-ec111-competitividade-eleitoral.qmd` | **rascunho** (de `explorations/competitividade-eleitoral/` + `explorations/ec111-did-2026/`) | A EC 111 aumentou a competitividade de mulheres e pessoas negras em 2022 e 2026? DiD federal × estadual (Callaway–Sant'Anna, base 2018, pré-teste 2014) com margem de votos (ABD/LSS) validada em 100% dos eleitos. Recursos a mulheres +12 p.p. estáveis em 2022 e 2026; ganhos de votos e recursos ficam com candidaturas não competitivas; composição das competitivas e cadeiras sem mudança. A aproximação de 3–4 p.p. das mulheres ao limiar vem da expansão de candidaturas masculinas fracas no federal e é frágil (quebra HonestDiD M̄ < 0,25). Pessoas negras: pré-teste falha. Pendente: prestação final de 2026, CoVe, biters 25.000 no funil |
| 4: Sobreposição Territorial do Voto, 2018–2026 | `chapters/04-sobreposicao-territorial-voto.qmd` | **rascunho** (de `explorations/ql-voto-2026/`) | QL do voto com piso de 2,5% dos votos do candidato (calibrado em 2018/2022 contra o gasto); Dados e Métodos + rascunho de Resultados (lacunas, incumbência, DDD, Modelo 2, robustez com piso de 5%). Pendente: EP do Modelo 2 raça 2026 (~3x menor que 2022, não investigado); DDD sem significância com piso de 5% |
| 5: Coordenação Territorial de Listas Partidárias | `chapters/05-sobreposicao-territorial-partido.qmd` | **rascunho** (graduado de `explorations/base-territorial-partidos/`) | Mecanismo central: lideranças partidárias protegem candidatos tradicionais (proxy: incumbência) enquanto aproveitam o incentivo da EC 111/2021 para mulheres/negros. Amostra: universo completo de partidos (34 legendas, 37.158 candidatos) — sem filtro de partidos, que não tinha justificativa teórica. Achados descritivos (H1/H2, gênero e raça) robustos em todas as células. Evidência causal (H3/H4/H5) fraca: no máximo marginal para gênero, nula para raça. Literatura e hipóteses centradas no mecanismo de proteção; inclui história legislativa da EC 111 (Gatto 2025); citações verificadas por CoVe |
| 6: Conclusão | `chapters/99-conclusao.qmd` | placeholder | — |

**Sumário aprovado em 2026-11-07.** Os antigos placeholders (Dados e Métodos, Índice G/QL, Alinhamento gasto-voto, Gasto na base territorial do partido) foram removidos — continham só o título. Métodos ficam dentro de cada capítulo empírico. **Numeração:** a coluna "Capítulo" segue o prefixo do arquivo; o livro renderizado conta a Introdução como Capítulo 1, então o número exibido é prefixo + 1 (ex.: `05-…` aparece como Capítulo 6). No texto, cite capítulos com `Capítulo [-@sec-...]`, nunca com número fixo. Explorações que não entraram em capítulo seguem acessíveis em `explorations/` (ver `explorations/README.md`).
