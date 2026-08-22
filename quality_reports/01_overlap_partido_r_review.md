# R Code Review: 01_overlap_partido.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent
**File reviewed:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R` (215 lines)
**Standards applied:** `.claude/rules/r-code-conventions.md`, `.claude/rules/inference-robustness.md`, `.claude/rules/content-invariants.md` (INV-9/INV-10), `.claude/rules/exploration-folder-protocol.md`

## Summary

- **Total issues:** 12
- **Critical:** 0
- **High:** 3
- **Medium:** 6
- **Low:** 3

This script is the numbered entry point of the Chapter 6 pipeline (`scripts/R/sobreposicao_territorial_partido/`), "graduated" from `explorations/base-territorial-partidos/R/01_overlap_partido.R` on 2026-08-15 per the folder's own README. The graduation was incomplete: the header, the `source()` call, and the output directory were never updated to point at the new production location, so the "migrated" script is still functionally tethered to the exploration sandbox. Separately, the console-hygiene rule is violated pervasively (10 `message()` + 6 `print()` calls), and the multiple-testing discipline required by this repo's own `inference-robustness.md` is absent for the 8 unadjusted Welch t-tests the script runs.

## Issues

### Issue 1: Header and `source()` still point at the pre-migration exploration copy
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:16, 21`
- **Category:** Structure / Reproducibility
- **Severity:** High
- **Current:**
  ```r
  # Rodar a partir da raiz do repositório: Rscript explorations/base-territorial-partidos/R/01_overlap_partido.R
  # ==============================================================================

  library(tidyverse)

  source("explorations/base-territorial-partidos/R/harmonizar_partido.R")
  ```
- **Proposed fix:**
  ```r
  # Rodar a partir da raiz do repositório:
  #   Rscript scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R
  # ==============================================================================

  library(tidyverse)

  source("scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R")
  ```
- **Rationale:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R` already exists — it's item 1 in the pipeline's own README — but this script sources the *other* copy in `explorations/`. The two files are currently byte-identical, but nothing enforces that: a future edit to the "production" copy (the one a reader would naturally reach for) silently has no effect on Chapter 6's actual output, because the script still runs off the exploration copy. This is exactly the drift hazard the migration was meant to eliminate. The run-path comment is likewise stale and would mislead anyone trying to reproduce the chapter from the current repo layout.

### Issue 2: Header block is stale and misrepresents the script's current status
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:1-17`
- **Category:** Structure / Header
- **Severity:** High
- **Current:**
  ```r
  # ==============================================================================
  # Exploração: Coordenação territorial de listas partidárias
  # ...
  # Status: EXPLORATÓRIO — nada aqui é definitivo. Ver README.md.
  # Rodar a partir da raiz do repositório: Rscript explorations/base-territorial-partidos/R/01_overlap_partido.R
  # ==============================================================================
  ```
- **Proposed fix:**
  ```r
  # ==============================================================================
  # Script: 01_overlap_partido.R
  # Purpose: Sobreposição território-partido — nível município e candidato
  #          (pipeline do Capítulo 6, "Coordenação territorial de listas
  #          partidárias")
  # Inputs:  data/raw/ql_gasto_eleit_{2018,2022}.rds,
  #          data/raw/ql_gasto_eleit_est_{2018,2022}.rds
  # Outputs: cand_mun_ql1.rds, taxa_sobreposicao_candidato.rds,
  #          overlap_municipio_partido.rds, tab_overlap_municipio.rds/.csv,
  #          tab_taxa_sobreposicao_{genero,raca,genero_raca}.rds/.csv,
  #          teste_t_{genero,raca}.rds
  # Status: PRODUÇÃO — alimenta 06-sobreposicao-territorial-partido.qmd.
  #         Histórico investigativo em
  #         explorations/base-territorial-partidos/SESSION_LOG.md.
  #
  # 0. SETUP
  # ==============================================================================
  ```
- **Rationale:** The script has been load-bearing for a committed thesis chapter since 2026-08-15 (per `scripts/R/sobreposicao_territorial_partido/README.md`), but its own header still says `Status: EXPLORATÓRIO — nada aqui é definitivo`, which is actively false and could mislead a co-author or future-you into treating its outputs as disposable. It's also missing the formal Author/Inputs/Outputs fields the project's header convention calls for, and there is no numbered "0. Setup" section — the `library()`/`source()`/`out_dir` block sits above Section 1 with no heading.

### Issue 3: Pervasive `message()`/`print()` usage violates console-output hygiene
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:59-60, 87-88, 115, 149-152, 179-182, 195-196, 214`
- **Category:** Console Output
- **Severity:** High
- **Current:**
  ```r
  message("\n--- Tabela B: taxa de sobreposição por gênero (cargo x ano) ---")
  print(tab_genero)
  message("p-valores (teste t, FEMININO vs MASCULINO):")
  print(teste_genero)
  ```
- **Proposed fix:**
  ```r
  # (drop the message()/print() pairs entirely; the tables are already
  #  saveRDS()'d below and readable via readRDS() or View() when needed)
  ```
- **Rationale:** The script contains 10 `message()` calls and 6 `print()` calls across its 5 sections — every intermediate table (`tab_overlap_mun`, `tab_genero`, `teste_genero`, `tab_raca`, `teste_raca`, `tab_genero_raca`) is dumped to console, several with a decorative `"--- Tabela X ---"` banner. The convention caps this at one `message()` per major section and forbids `print()` for status/progress entirely. Every one of these tables is already (or should be, see Issue 9) saved via `saveRDS()`/`write_csv()` — console output adds no reproducibility value and clutters `Rscript` logs, making genuine errors harder to spot.

### Issue 4: Output directory hardcodes a lifecycle-managed exploration sandbox path
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:28-29`
- **Category:** Reproducibility
- **Severity:** Medium
- **Current:**
  ```r
  out_dir <- "explorations/base-territorial-partidos/output"
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  ```
- **Proposed fix:**
  ```r
  # Option A — keep outputs with the migrated production script:
  out_dir <- "scripts/R/sobreposicao_territorial_partido/_outputs"
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  # Option B — if the exploration output dir is kept deliberately (current
  # documented behavior), add an explicit comment stating so and flag the
  # dependency in exploration-folder-protocol.md so it's exempted from
  # "graduate → archive" lifecycle cleanup.
  ```
- **Rationale:** `scripts/R/sobreposicao_territorial_partido/README.md` documents this as intentional ("os scripts escrevem em `explorations/base-territorial-partidos/output/` (local original)"), but that conflicts with `.claude/rules/exploration-folder-protocol.md`, whose lifecycle for a "graduated" exploration is to move it into `ARCHIVE/completed_[project]/`. As written, the *production* Chapter 6 Quarto build (`06-sobreposicao-territorial-partido.qmd`) has a silent, undocumented hard dependency on a folder that the project's own protocol treats as disposable once graduated. At minimum this coupling should be called out explicitly in this script's header (per Issue 2) and cross-referenced in the exploration protocol so nobody archives `explorations/base-territorial-partidos/` and breaks the thesis build.

### Issue 5: Eight Welch t-tests run with no multiple-testing correction
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:136-147, 166-177`
- **Category:** Domain Correctness
- **Severity:** Medium
- **Rationale:** `.claude/rules/inference-robustness.md` requires that when a paper tests many hypotheses, the family and correction method be pre-registered and reported alongside unadjusted values. This script runs 4 gender tests + 4 race tests (8 total) with raw, unadjusted p-values, and the manuscript table (`@tbl-sobreposicao-genero-raca`) reports "<0.001" significance stars sourced from these unadjusted values. Given most gaps are already highly significant this likely doesn't flip the substantive conclusion, but the correction (even reported as a robustness footnote) is required by this project's own inference-robustness standard and should be computed and saved, not merely asserted informally.
- **Proposed fix:** After computing both `teste_genero` (4 tests) and `teste_raca` (4 tests), apply a stated correction across the 8-test family (e.g. `p.adjust(p.value, method = "BH")`) and save alongside the unadjusted values.

### Issue 6: Failed t-tests are silently dropped, not counted or reported
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:140-147, 170-177`
- **Category:** Error Handling
- **Severity:** Medium
- **Rationale:** `unnest()` on a column containing `NULL` for a failed `t.test()` (e.g., a cargo×ano cell with zero variance in one group, or only one group present) silently removes that row from the output — a cell that failed the t-test simply vanishes from `teste_t_genero.rds` with no trace. Per the review protocol's Error Handling category, failed computations must be counted and reported, not silently excluded from downstream tables that feed the thesis chapter.
- **Proposed fix:** Add a `teste_falhou = map_lgl(teste, is.null)` column before `unnest()`, and `message()` a count of failures if any exist.

### Issue 7: Sample restrictions to binary gender/race categories are not logged
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:126, 137, 156, 167, 186-187`
- **Category:** Domain Correctness
- **Severity:** Medium
- **Rationale:** `raca2` in Brazilian TSE-derived candidate data typically has more than two categories, and both filters silently drop any candidate outside the two named categories (Fem/Masc, Branca/Negra) from Tables B, C, and D. Without a reported exclusion count, a reader of the RDS output (or the chapter) cannot tell how much of the sample this restriction removes.
- **Proposed fix:** Compute and `message()` the exclusion count (`n_total - n_matching_filter`) before each restricted table is built.

### Issue 8: Duplicated t-test extraction logic (gender vs. race)
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:136-147, 166-177`
- **Category:** Functions
- **Severity:** Medium
- **Rationale:** The convention requires `snake_case`, verb-noun, documented functions for non-trivial repeated logic. This 10-line block is copy-pasted with only the group variable changed, meaning any future fix (e.g., Issue 6's failure-reporting, or Issue 5's correction) must be applied twice and is already at risk of the two copies drifting (they already differ subtly — see Issue 9 below).
- **Proposed fix:** Extract a documented helper `run_group_ttest(df, group_var, niveis)` using tidy-eval (`{{ group_var }}`) and call it once per grouping variable.

### Issue 9: `mean()`/`sum()` calls on `overlap` omit explicit `na.rm`
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:81-82, 110`
- **Category:** Numerical Discipline
- **Severity:** Low
- **Rationale:** `r-code-conventions.md` §8 requires `na.rm` to be stated explicitly on every `mean()`/`sum()`/`sd()`/`var()` call, never relying on the default. `overlap` should never be `NA` in practice, but the rule exists so a reviewer doesn't have to re-derive that guarantee by hand — an explicit `na.rm = FALSE` documents the assumption and fails loudly if it's ever violated.
- **Proposed fix:** Add `na.rm = FALSE` explicitly to both call sites.

### Issue 10: Repeated hardcoded category labels with no named constant
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:126, 137, 156, 167, 186-187`
- **Category:** Functions (magic values)
- **Severity:** Low
- **Rationale:** The same two literal string vectors (`c("FEMININO", "MASCULINO")`, `c("BRANCA", "NEGRA")`) are retyped six times across the script. A single source of truth avoids a category-name typo silently producing an empty filter in one of the six call sites while leaving the other five correct.
- **Proposed fix:** Define `generos_validos` and `racas_validas` once in the Setup section; reference everywhere.

### Issue 11: T-test output keeps only `p.value`, discarding the effect size and CI
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:147, 177`
- **Category:** RDS Data Pattern
- **Severity:** Low
- **Rationale:** `broom::tidy(t.test(...))` already computes the mean difference and its 95% CI, but the script discards everything except `p.value` before saving. The chapter's `@tbl-sobreposicao-genero-raca` table reports a point gap that currently has to be reconstructed by hand-differencing the descriptive tables rather than reading it directly (with its CI) from the saved test object.
- **Proposed fix:** Keep `estimate, conf.low, conf.high, p.value` in the saved RDS, not just `p.value`.

### Issue 12: Candidate-level t-test treats unequal-reliability observations as equally weighted
- **File:** `scripts/R/sobreposicao_territorial_partido/01_overlap_partido.R:107-113, 136-147, 166-177`
- **Category:** Domain Correctness
- **Severity:** Medium
- **Rationale:** `n_mun_ql1` (the denominator of `taxa_sobreposicao`) varies substantially across candidates — a candidate active above the QL threshold in only 1 municipality gets a binary 0/1 rate, while a candidate active in 10 gets a smoother estimate, yet both enter the Welch t-test as a single equally-weighted observation. This is a defensible design choice if "candidate" is the intended unit of theoretical interest, but it is not stated anywhere in the script or the chapter, and it materially affects the standard errors reported in `@tbl-sobreposicao-genero-raca`.
- **Proposed fix:** Document the design choice explicitly in a comment, and add a weighted binomial-GLM robustness check (`cbind(n_mun_overlap, n_mun_ql1 - n_mun_overlap) ~ genero`) as a footnote-level sanity check.

## Checklist Summary

| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | No | 2 |
| Console Output | No | 1 (systemic — 16 call sites) |
| Reproducibility | No | 2 |
| Functions | No | 2 |
| Domain Correctness | No | 3 |
| Figures | N/A | 0 (script produces no plots) |
| RDS Pattern | Partial | 1 |
| Comments | Yes | 0 |
| Error Handling | No | 1 |
| Polish | Yes | 0 (consistent `\|>`, 2-space indent, no `T`/`F`, no lines >100 chars outside the stale header comment) |
| Numerical Discipline | No | 1 |

**Not flagged (verified, no issue):** no `set.seed()` needed (script is fully deterministic); no `require()` usage; all paths relative to repo root; `dir.create(..., recursive = TRUE)` present; pipe style consistent (`|>` throughout); no bare `T`/`F`; no float `==`; no CDF calls requiring clamping; no growable-vector loops.

**One item noted for follow-up, out of this script's scope:** `06-sobreposicao-territorial-partido.qmd` hand-transcribes the `@tbl-sobreposicao-genero-raca` markdown table from `tab_genero`/`teste_genero`/`tab_raca`/`teste_raca` rather than rendering it programmatically from the saved RDS files — a manuscript-side reproducibility gap, not a bug in `01_overlap_partido.R` itself, but worth an `/audit-reproducibility` pass given the cross-artifact-review protocol.
