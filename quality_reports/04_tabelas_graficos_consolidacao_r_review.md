# R Code Review: 04_tabelas_graficos_consolidacao.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent

## Summary
- **Total issues:** 22
- **Critical:** 1
- **High:** 4
- **Medium:** 7
- **Low:** 10

## Priority triage
1. **Verify Issue 1 first** — run the script standalone and confirm whether it actually errors on `tidy()`. If it does, this single missing `library(fixest)` line blocks the whole script.
2. **Issues 2-5** are the substantive domain/rigor findings worth fixing before this script's tables are treated as final — the NA-mislabeling landmine, missing multiple-testing correction, accessibility-claim mismatch, and manual-transcription drift risk vs. the chapter's static tables.
3. Everything else (6-22) is genuine but lower-stakes polish/robustness.

## Issues

### Issue 1: Missing `library(fixest)` — `tidy()` will likely fail on the loaded model objects
- **File:** `04_tabelas_graficos_consolidacao.R:19-23,98,109-112`
- **Category:** Reproducibility / Domain Correctness
- **Severity:** Critical
- **Rationale:** `ddd_modelo_genero.rds` etc. are `fixest` model objects. `broom::tidy()` dispatches to `tidy.fixest`, which `fixest` registers only when its namespace is loaded. `readRDS()` deserializes an object without loading the defining package. On a fresh `Rscript` invocation where nothing else has loaded `fixest`, `tidy(modelo, conf.int = TRUE)` will error with "no applicable method for 'tidy'". Please verify by running the script standalone in a clean session.
- **Proposed fix:** Add `library(fixest)` to the header's library block.

### Issue 2: `sig_star()` silently mislabels missing/failed p-values as "not significant"
- **File:** `04_tabelas_graficos_consolidacao.R:52-54,76`
- **Category:** Domain Correctness / Error Handling
- **Severity:** High
- **Rationale:** `01_overlap_partido.R`'s t-tests are wrapped in `tryCatch(..., error = function(e) NULL)`; a failed cell drops out of `unnest()`, producing `NA` for `p.value` after the join. `case_when(p < 0.001 ~ ..., TRUE ~ "ns")` evaluates `NA < 0.001` as `NA` (no match), falling through to `"ns"` — so a *failed statistical test* prints as "ns" in the dissertation table, indistinguishable from a genuine null result. Dormant today (all 8 t-tests currently succeed) but a landmine for any future re-run.
- **Proposed fix:** Add `is.na(p) ~ "n/d"` as the first `case_when()` branch.

### Issue 3: No multiple-testing correction on the significance stars feeding the published tables
- **File:** `04_tabelas_graficos_consolidacao.R:52-54,76,120`
- **Category:** Domain Correctness
- **Severity:** High
- **Rationale:** Per `.claude/rules/inference-robustness.md`, a family of tests reported together should have a pre-registered correction. The DDD family is exactly where it matters: two of the four p-values (0.057, 0.068) sit right at the significance edge, and the manuscript prose already hedges cautiously but isn't backed by a documented correction. The true family across Models 1/2/3 is at least 12 tests, not 4.
- **Proposed fix:** Apply `p.adjust(method = "holm")` within each family before starring, reporting both raw and adjusted values.

### Issue 4: Header's accessibility claim ("shape distinguishes group") is not implemented for 2 of 3 figures
- **File:** `04_tabelas_graficos_consolidacao.R:4-8,158-179,201-215`
- **Category:** Figures / Domain Correctness
- **Severity:** High
- **Rationale:** The header explicitly claims shape is used as a redundant, colorblind/grayscale-safe encoding of *group*. In `g_genero`/`g_raca`, shape is actually bound to **year**, not group — group is color-only. Only `g_ddd` (the DDD coefficient plot) does what the header describes. A grayscale photocopy of `g_genero`/`g_raca` would have to rely on Okabe-Ito luminance contrast alone to distinguish Feminino from Masculino.
- **Proposed fix:** Either implement group-encoded shape for `g_genero`/`g_raca`, or correct the header comment to describe what's actually implemented.

### Issue 5: Consolidated tables are computed but never programmatically consumed — chapter hand-transcribes the same numbers
- **File:** `04_tabelas_graficos_consolidacao.R:80-135`
- **Category:** RDS Pattern / Reproducibility (cross-artifact)
- **Severity:** High
- **Rationale:** Confirmed via grep that `tabela_consolidada_r1.tex/csv` and `tabela_consolidada_ddd.tex/csv` are never referenced in the chapter — `@tbl-sobreposicao-genero-raca` and `@tbl-ddd` are static hand-typed markdown tables. Arithmetic is currently self-consistent, but there is no automated link back to this script's output — exactly the failure mode `/audit-reproducibility` and the passport system exist to prevent.
- **Proposed fix:** Wire the CSVs into the chapter via an inline R chunk, or at minimum register these numbers in `quality_reports/passports/`.

### Issue 6: `tab_r1_consolidada` and `tab_ddd_consolidada` are never saved as `.rds`
- **File:** `04_tabelas_graficos_consolidacao.R:80-135`
- **Category:** RDS Pattern
- **Severity:** Medium
- **Proposed fix:** Add `saveRDS()` for both tables alongside the existing `.tex`/`.csv` output.

### Issue 7: Substantial duplication between the `g_genero` and `g_raca` plotting blocks
- **File:** `04_tabelas_graficos_consolidacao.R:158-179` vs `201-215`
- **Category:** Function Design / Comments
- **Severity:** Medium
- **Rationale:** Two nearly identical ~20-line `ggplot()` chains, differing only in the grouping variable and palette — a fix to the halo trick or dodge width in one is easy to forget applying to its twin.
- **Proposed fix:** Extract a shared `plot_dumbbell_taxa(df, group_var, color_map, legend_name, title, caption)` helper.

### Issue 8: `sig_star()` and `extrair_ddd()` lack roxygen-style documentation
- **File:** `04_tabelas_graficos_consolidacao.R:52-54,97-107`
- **Category:** Function Design
- **Severity:** Medium
- **Rationale:** `extrair_ddd()` has an easy-to-miss failure mode — if `termo` doesn't match any row, `filter()` silently returns zero rows and `bind_rows()` drops that model's row instead of erroring.
- **Proposed fix:** Add roxygen docs; add a `stopifnot(nrow(...) == 1)` sanity check.

### Issue 9: No defensive `dir.create()` in this script
- **File:** `04_tabelas_graficos_consolidacao.R:25`
- **Category:** Reproducibility
- **Severity:** Medium
- **Proposed fix:** Add `dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)`.

### Issue 10: Header missing explicit Author / structured Outputs fields
- **File:** `04_tabelas_graficos_consolidacao.R:1-17`
- **Category:** Structure & Header
- **Severity:** Medium
- **Proposed fix:** Add Author line and enumerated Inputs/Outputs lists (8 files this script produces).

### Issue 11: `theme_minimal(base_size = 12)` below the project's projection-readability floor
- **File:** `04_tabelas_graficos_consolidacao.R:33`
- **Category:** Figures
- **Severity:** Medium
- **Rationale:** Review checklist requires `base_size >= 14`. These are book/print figures (weaker rationale than Beamer), but if reused for a future defense deck (stated possibility given the shared Okabe-Ito convention), 12pt is already too small.
- **Proposed fix:** Bump to 14, or document explicitly why 12 was chosen.

### Issue 12: `left_join()` calls with no `relationship` validation
- **File:** `04_tabelas_graficos_consolidacao.R:58,67`
- **Category:** Error Handling
- **Severity:** Medium
- **Rationale:** If a future change ever produced 2 rows for the same join key, this would silently fan out the consolidated table to duplicate rows with no warning.
- **Proposed fix:** Add `relationship = "one-to-one"` to both joins.

### Issue 13: DDD estimates/CIs rounded to 1 decimal before being reused for plotting
- **File:** `04_tabelas_graficos_consolidacao.R:100-106,230-236`
- **Category:** Numerical Discipline
- **Severity:** Low
- **Proposed fix:** Keep full-precision columns for computation/plotting; round only at display time.

### Issue 14: 24 lines exceed the 100-character convention (non-mathematical code)
- **File:** `04_tabelas_graficos_consolidacao.R` — lines 115-118,129,137,154,158,161,167,169-170,177,182,199,201,203-205,213,218,230,243,249
- **Category:** Polish
- **Severity:** Low
- **Rationale:** These are `ggplot()`/`aes()` chains, not documented math, so the length exception doesn't apply.

### Issue 15: `legend.position = "top"` deviates from the documented "bottom" convention
- **File:** `04_tabelas_graficos_consolidacao.R:38`
- **Category:** Figures
- **Severity:** Low
- **Proposed fix:** Move to `"bottom"` to match the reference theme, or comment justifying the deviation.

### Issue 16: No `bg = "transparent"` in any `ggsave()` call
- **File:** `04_tabelas_graficos_consolidacao.R:181-182,217-218,248-249`
- **Category:** Figures
- **Severity:** Low
- **Rationale:** INV-11 mandates this specifically for Beamer figures; this is a Quarto book chapter, so likely correct as-is — flagged as informational.

### Issue 17: Unused `library(patchwork)`
- **File:** `04_tabelas_graficos_consolidacao.R:23`
- **Category:** Polish
- **Severity:** Low
- **Proposed fix:** Remove, or use it for a combined-panel figure if one is planned.

### Issue 18: No numbered "0. Setup" section header
- **File:** `04_tabelas_graficos_consolidacao.R:19-41`
- **Category:** Structure & Header
- **Severity:** Low
- **Proposed fix:** Add a `# 0. SETUP` banner before the library calls.

### Issue 19: Decorative "===" banner inside a `message()` call
- **File:** `04_tabelas_graficos_consolidacao.R:251`
- **Category:** Console Output Hygiene
- **Severity:** Low
- **Proposed fix:** Drop the `===` decoration.

### Issue 20: Dangling reference to an `AGENTS.md` that doesn't exist in this repository
- **File:** `04_tabelas_graficos_consolidacao.R:4`
- **Category:** Comments
- **Severity:** Low
- **Rationale:** Confirmed via repo-wide grep that no `AGENTS.md` exists in this codebase — it lives only in the author's separate, un-migrated analysis project.
- **Proposed fix:** Point to `explorations/base-territorial-partidos/SESSION_LOG.md` instead, which does discuss this convention.

### Issue 21: `taxa_alta`/`cat_alta` column names assume a direction that isn't verified
- **File:** `04_tabelas_graficos_consolidacao.R:60-74`
- **Category:** Domain Correctness / Comments
- **Severity:** Low
- **Rationale:** `_alta` ("high") implies a verified ordering claim; happens to be safe today (all 8 cells show the marginalized group with the higher rate) but the column name doesn't guarantee it.
- **Proposed fix:** Rename to direction-neutral labels, or add a `stopifnot()` assertion checking the ordering.

### Issue 22: `out_dir` points outside `data/` and outside the Quarto project tree — final figures require a manual copy step
- **File:** `04_tabelas_graficos_consolidacao.R:25`
- **Category:** Structure / Reproducibility
- **Severity:** Low
- **Rationale:** Confirmed documented and deliberate per the sibling README ("figuras finais... foram copiadas para Figures/06-..."), and confirmed via Glob that all 3 PNGs exist at the destination today. Still a manual step that could silently go stale on re-run.
- **Proposed fix:** Automate the copy step with `file.copy()` at the end of the script.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | No | 2 |
| Console Output | No | 1 |
| Reproducibility | No | 3 |
| Functions | No | 2 |
| Domain Correctness | No | 4 |
| Figures | No | 4 |
| RDS Pattern | No | 2 |
| Comments | No | 1 |
| Error Handling | No | 2 |
| Polish | No | 2 |
| Numerical Discipline | No | 1 |
