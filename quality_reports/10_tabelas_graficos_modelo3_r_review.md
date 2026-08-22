# R Code Review: 10_tabelas_graficos_modelo3.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent

## Summary
- **Total issues:** 17
- **Critical:** 1
- **High:** 4
- **Medium:** 6
- **Low:** 6

**Highest-priority fixes, in order:** Issue 1 (stale/self-referential prerequisite comment), Issue 4 (silent-failure risk in the term-extraction function — could produce a wrong or incomplete thesis table with zero warning), Issue 8 (verify the hand-typed manuscript table against a fresh run of this script before submission), then Issue 5 (deduplicate the shared helpers across 04/06/10 before a 4th sibling script copies the same drift).

## Issues

### Issue 1: Prerequisite header is stale after the `12_` → `10_` rename (self-referential / references non-existent scripts)
- **File:** `10_tabelas_graficos_modelo3.R:8`
- **Category:** Structure / Reproducibility
- **Severity:** Critical
- **Current:** `# Pré-requisito: rodar R/01, R/03, R/05, R/09, R/10 e R/11 antes.`
- **Rationale:** There is no `R/11`, and `R/10` is this file itself. Leftover text from before the renumbering. A future author following this comment would try to run a nonexistent script, or run "this script" as a prerequisite of itself.
- **Proposed fix:** `# Pré-requisito: rodar R/01_overlap_partido.R, R/03_ddd_incentivo_2022.R, R/05_modelo2_incumbente.R, R/07_titulo_eleitoral_2018_2022.R, R/08_lideranca_partido.R e R/09_modelo3_lideranca.R antes.`

### Issue 2: `print(tab_comparativa)` — non-debugging console output
- **File:** `10_tabelas_graficos_modelo3.R:87`
- **Category:** Console Output Hygiene
- **Severity:** High
- **Proposed fix:** Replace with a one-line row-count `message()`.

### Issue 3: Decorative `===` banner inside `message()`
- **File:** `10_tabelas_graficos_modelo3.R:122`
- **Category:** Console Output Hygiene
- **Severity:** Medium
- **Rationale:** Copy-pasted from siblings `06_tabelas_graficos_modelo2.R:164` and `09_modelo3_lideranca.R:239` — worth fixing all three at once.
- **Proposed fix:** Drop the `===` decoration.

### Issue 4: Silent-failure risk — no assertion that the term filter matched a row
- **File:** `10_tabelas_graficos_modelo3.R:37-47`
- **Category:** Error Handling / Domain Correctness
- **Severity:** High
- **Rationale:** `filter(term == termo)` on a `broom::tidy()` output that finds zero matches silently returns a zero-row tibble; `bind_rows()` would then quietly drop that model/group cell from the comparative table — a wrong or incomplete PhD-thesis table shipped silently. Interaction-term label order in `fixest` is a known source of drift across package versions.
- **Proposed fix:** Add a `stopifnot(nrow(resultado) == 1L)` inside `extrair_ddd()`, with an error listing available terms if it fails. **This is the single highest-value fix in this review for correctness.**

### Issue 5: Verbatim code duplication across 3+ scripts, with documentation drift already visible
- **File:** `10_tabelas_graficos_modelo3.R:18-47` (compare `06_tabelas_graficos_modelo2.R:18-50`)
- **Category:** Function Design / Comments
- **Severity:** High
- **Rationale:** `cor_feminino`/`cor_masculino`/`cor_negra`/`cor_branca`, `tema_dumbbell`, `sig_star()`, and `extrair_ddd()` are copy-pasted verbatim from `06_tabelas_graficos_modelo2.R`. Drift already happened: `06`'s comment explaining the `scale` parameter is missing entirely from this copy.
- **Proposed fix:** Extract into a shared `_helpers_tabelas.R` sourced by `04`, `06`, and `10`.

### Issue 6: `extrair_ddd()` and `sig_star()` lack roxygen documentation
- **File:** `10_tabelas_graficos_modelo3.R:33-47`
- **Category:** Function Design
- **Severity:** Medium
- **Proposed fix:** Add `#'` doc blocks explaining the significance-star convention and scaling contract.

### Issue 7: Missing `dir.create(out_dir, recursive = TRUE)` guard
- **File:** `10_tabelas_graficos_modelo3.R:16`
- **Category:** Reproducibility
- **Severity:** Medium
- **Proposed fix:** Add the standard `dir.create()` call.

### Issue 8: Generated `.tex` table appears orphaned — the manuscript hand-transcribes the same numbers instead of consuming this script's output
- **File:** `10_tabelas_graficos_modelo3.R:71-84`; consumed (or not) at `06-sobreposicao-territorial-partido.qmd:208-217`
- **Category:** RDS/Output Pattern (cross-artifact)
- **Severity:** High
- **Rationale:** This script's entire purpose is producing an artifact (`tabela_comparativa_modelo1_modelo2_modelo3.tex`) that the manuscript doesn't consume — it hand-types the same six rows as a literal markdown table instead. No mechanical guarantee that re-running the R pipeline and the hand-typed thesis table stay in sync if the DDD models are re-estimated.
- **Proposed fix:** Either wire the `.qmd` to consume the generated table programmatically, or add explicit cross-referencing comments in both places noting they must be updated together.

### Issue 9: No RDS saved for the computed comparative objects
- **File:** `10_tabelas_graficos_modelo3.R:61-68,101-117`
- **Category:** RDS Pattern
- **Severity:** Medium
- **Proposed fix:** `saveRDS()` both `tab_comparativa` and `g_comparativo`.

### Issue 10: `broom::tidy()` dispatches on `fixest` objects without `library(fixest)` being loaded
- **File:** `10_tabelas_graficos_modelo3.R:11-14`
- **Category:** Reproducibility
- **Severity:** Medium
- **Rationale:** Currently works via broom's conditional S3 registration, but is an implicit, version-fragile dependency.
- **Proposed fix:** Add explicit `library(fixest)`.

### Issue 11: `base_size = 12` is below the project's readability floor
- **File:** `10_tabelas_graficos_modelo3.R:23`
- **Category:** Figures
- **Severity:** Low
- **Rationale:** Lower severity since this is a book-context (not Beamer) figure, but inconsistent with the project's own stated `base_size = 14` default; identically duplicated from `06_tabelas_graficos_modelo2.R:23`.

### Issue 12: No `bg = "transparent"` on `ggsave()`
- **File:** `10_tabelas_graficos_modelo3.R:119-120`
- **Category:** Figures
- **Severity:** Low
- **Proposed fix:** Make the background choice explicit (`bg = "white"` for book-only use, `"transparent"` if future Beamer reuse is planned).

### Issue 13: Unused color constants
- **File:** `10_tabelas_graficos_modelo3.R:19,21`
- **Category:** Polish (dead code)
- **Severity:** Low

### Issue 14: Output directory still targets the legacy `explorations/` sandbox
- **File:** `10_tabelas_graficos_modelo3.R:16`
- **Category:** Structure / Reproducibility
- **Severity:** Low
- **Rationale:** Consistent with every sibling script, so not a fix for this file alone — flagging as a chapter-wide follow-up when the data layer eventually migrates to `data/`.

### Issue 15: Header lacks explicit Author/Inputs/Outputs, and no "0. Setup" section marker
- **File:** `10_tabelas_graficos_modelo3.R:1-31`
- **Category:** Structure & Header
- **Severity:** Medium
- **Rationale:** Systemic gap across 04/06/09/10 — treat as a one-time template fix.

### Issue 16: Long lines in non-mathematical code exceed the 100-char guideline
- **File:** `10_tabelas_graficos_modelo3.R:62-67,78,101,114,119-120`
- **Category:** Polish
- **Severity:** Low

### Issue 17: No discussion of the 6-way comparison as a testing family
- **File:** `10_tabelas_graficos_modelo3.R:61-69` (and chapter prose 200-223)
- **Category:** Domain Correctness (advisory)
- **Severity:** Low
- **Rationale:** Defensible as "alternative specifications of the same estimand, presented for triangulation" — but that framing should be stated explicitly rather than left implicit, since the chapter prose already treats p = 0.057 vs. p < 0.001 vs. p = 0.089 as meaningfully different evidentiary strength across models.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | No | 3 |
| Console Output | No | 2 |
| Reproducibility | No | 3 |
| Functions | No | 2 |
| Domain Correctness | No | 2 |
| Figures | No | 2 |
| RDS Pattern | No | 2 |
| Comments | No | 1 |
| Error Handling | No | 1 |
| Polish | No | 2 |
| Numerical Discipline | Yes | 0 |
