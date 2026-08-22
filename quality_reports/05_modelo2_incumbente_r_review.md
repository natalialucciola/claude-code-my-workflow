# R Code Review: 05_modelo2_incumbente.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent

## Summary
- **Total issues:** 13
- **Critical:** 1
- **High:** 3
- **Medium:** 6
- **Low:** 3

This script is the strongest-commented script in the pipeline (rationale comments genuinely explain WHY, not WHAT). The main problems are (1) a real cross-artifact hypothesis-numbering drift against the compiled thesis chapter, (2) console-output/RDS discipline that loses exactly the sample-size numbers the chapter cites in prose, and (3) heavy duplication across six near-identical `feols()` calls with zero functions defined.

## Issues

### Issue 1: Hypothesis numbering drift — script says H6/H7, thesis chapter says H4/H5
- **File:** `05_modelo2_incumbente.R:6,15,94,119,133,142,150,153-157,181,189,208`
- **Category:** Domain Correctness
- **Severity:** Critical
- **Rationale:** `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd` and `README.md` both correctly call the incumbent-protection test **H4** and the territorial-reach test **H5**. This script (and its consumer `06_tabelas_graficos_modelo2.R`) still internally label the exact same tests **H6/H7** throughout headers, `message()` text, and persisted artifact names (`tabela_h7_alcance_total.tex`, `grafico_h7_alcance_total.png`). This is exactly the paper↔code provenance drift `.claude/rules/cross-artifact-review.md` exists to catch: a hypothesis renumbering was applied to the manuscript prose but never propagated to the pipeline that produces its evidence.
- **Proposed fix:** Replace all H6→H4 and H7→H5 references in comments, `message()` text, and object/file names; propagate the fix to `06_tabelas_graficos_modelo2.R` and check the `.qmd`'s own `{#tbl-h7}`/`{#fig-h7}` cross-reference IDs for the same drift.

### Issue 2: Console output used as the only diagnostic channel (pervasive `message()`/`print()`)
- **File:** `05_modelo2_incumbente.R:48-49,87-89,111-113,119-120,125-127,133-134,142-143,150-151,181-182,189-190,208`
- **Category:** Console
- **Severity:** High
- **Rationale:** ~10 `message()` calls and ~5 `print()` calls in a 209-line script, well beyond "one per major section." Cell support counts and full `summary(feols(...))` output are analytically meaningful and should be first-class artifacts, not console text that vanishes on a non-interactive `Rscript` run.
- **Proposed fix:** Persist cell-support tables and model summaries via `saveRDS()`/`etable()`; collapse messages to one per section.

### Issue 3: Cell-support diagnostics computed and printed, never persisted — breaks provenance for a specific chapter claim
- **File:** `05_modelo2_incumbente.R:111-113,125-127`
- **Category:** RDS Pattern
- **Severity:** High
- **Rationale:** The chapter's Limitação 4 makes a specific numeric claim ("A restrição a candidatos não incumbentes reduz o N em cerca de 6% em relação ao Modelo 1"). That number can only have come from comparing sample sizes across scripts 03 and 05, but neither script saves the N accounting that would let `/audit-reproducibility` re-derive "~6%" from disk.
- **Proposed fix:** `saveRDS()` the cell-support tables computed at these lines.

### Issue 4: NA-drop on incumbência join not checked for balance across treatment cells
- **File:** `05_modelo2_incumbente.R:45-51`
- **Category:** Errors
- **Severity:** Medium
- **Rationale:** The join drop is only reported as one aggregate count, never broken down by `genero`/`raca2` × `cargo` × `ano`. If unmatched CPFs are disproportionately concentrated in one cell, the drop introduces differential attrition into exactly the DDD design H4 depends on for identification.
- **Proposed fix:** Compute and save an NA-by-cell breakdown before filtering.

### Issue 5: Six near-identical `feols()` calls, zero functions defined
- **File:** `05_modelo2_incumbente.R:115-118,129-132,138-141,146-149,177-180,185-188`
- **Category:** Functions
- **Severity:** High
- **Rationale:** Changing the DDD specification requires editing six separate blocks by hand — a direct maintainability/correctness risk (miss one, and the "gênero, robustez" spec silently diverges from its "raça, robustez" sibling). Same duplication pattern repeats in `03_ddd_incentivo_2022.R`.
- **Proposed fix:** Extract a shared `fit_ddd_model(data, outcome_var, group_var)` helper, ideally in a file sourced by both `03` and `05`.

### Issue 6: No post-estimation health check on any of the six fitted models
- **File:** `05_modelo2_incumbente.R:115-118,129-132,138-141,146-149,177-180,185-188`
- **Category:** Errors
- **Severity:** Medium
- **Rationale:** With `partido_harm` (~34 levels) × `SG_UF` (27 levels) fixed effects on subsets as small as "não incumbentes, mulher, Federal, 2022," some cells can be singletons that `fixest` silently drops, producing collinear/NA coefficients for the triple interaction with no programmatic check.
- **Proposed fix:** Add a `check_model_health()` helper that flags non-finite coefficients after each fit.

### Issue 7: No defensive check against join fan-out in the H5 (alcance total) join
- **File:** `05_modelo2_incumbente.R:161-172`
- **Category:** Errors
- **Severity:** Medium
- **Rationale:** `uf_por_candidato` is `distinct()`-ed assuming exactly one `SG_UF` per candidacy, but nothing verifies it — a data-quality exception would silently multiply rows in `alcance_total`, corrupting N and SEs behind the H5 estimates.
- **Proposed fix:** Add `stopifnot(nrow(alcance_total) == nrow(taxa_geral))` after the join.

### Issue 8: Few-cluster inference risk not addressed (34 `partido_harm` clusters)
- **File:** `05_modelo2_incumbente.R:115-118,129-132,177-180,185-188`
- **Category:** Domain Correctness
- **Severity:** Medium
- **Rationale:** 34 `partido_harm` clusters is below the ~40-50 rule of thumb for conventional cluster-robust asymptotics — matters directly for a result the chapter already reports as marginal (p ≈ 0.057-0.068).
- **Proposed fix:** Add a wild-cluster-bootstrap robustness check (`fwildclusterboot::boottest()`) per `.claude/rules/inference-robustness.md`.

### Issue 9: No multiple-testing correction across the DDD test family
- **File:** `05_modelo2_incumbente.R` (script-wide, part of the larger H1-H5 family)
- **Category:** Domain Correctness
- **Severity:** Medium
- **Rationale:** Across scripts 03/05/09 the chapter runs at minimum ~10 formally distinct DDD tests with no multiplicity correction, given the headline claim already rests on a marginal p ≈ 0.057.
- **Proposed fix:** Apply and report a stepdown/FDR correction across the full test family per `.claude/rules/inference-robustness.md`.

### Issue 10: Header lacks explicit Author/Inputs/Outputs fields; no numbered "0. Setup" section
- **File:** `05_modelo2_incumbente.R:1-36`
- **Category:** Structure
- **Severity:** Medium
- **Rationale:** The narrative content of the header is good, but lacks machine-findable Author/Inputs/Outputs fields.
- **Proposed fix:** Add the missing header fields and a "0. SETUP" section marker.

### Issue 11: No `dir.create()` — script isn't self-contained if run out of pipeline order
- **File:** `05_modelo2_incumbente.R:36`
- **Category:** Reproducibility
- **Severity:** Low
- **Proposed fix:** Add `dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)`.

### Issue 12: Numerical discipline — missing explicit `na.rm`, bare integer literal for a count comparison
- **File:** `05_modelo2_incumbente.R:49,72,82`
- **Category:** Numerical Discipline
- **Severity:** Low
- **Proposed fix:** Add explicit `na.rm = FALSE` and use `1L` for count-threshold comparisons.

### Issue 13: `cand_mun_incumbente` (candidate-município intermediate) never persisted
- **File:** `05_modelo2_incumbente.R:66-73`
- **Category:** RDS Pattern
- **Severity:** Low
- **Rationale:** The richest intermediate in the script, useful for a future descriptive map or robustness check, but not saved.
- **Proposed fix:** `saveRDS(cand_mun_incumbente, ...)`.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | No | 1 |
| Console Output | No | 1 |
| Reproducibility | Partial | 1 |
| Functions | No | 1 |
| Domain Correctness | No | 3 |
| Figures | N/A | 0 |
| RDS Pattern | No | 2 |
| Comments | Yes | 0 |
| Error Handling | No | 3 |
| Polish | Yes | 0 |
| Numerical Discipline | Partial | 1 |
