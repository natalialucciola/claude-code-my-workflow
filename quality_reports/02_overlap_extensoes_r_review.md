# R Code Review: 02_overlap_extensoes.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent
**File:** `scripts/R/sobreposicao_territorial_partido/02_overlap_extensoes.R`

## Summary
- **Total issues:** 13
- **Critical:** 1
- **High:** 4
- **Medium:** 4
- **Low:** 4

## Issues

### Issue 1: Unvalidated joins underlying the incumbency proxy — silent data loss possible on a load-bearing variable
- **File:** `02_overlap_extensoes.R:207-284`
- **Category:** Domain Correctness / Error Handling
- **Severity:** Critical
- **Rationale:** `CLAUDE.md` identifies incumbency ("proxy: incumbência") as the central mechanism of Chapter 6, and this table's incumbency flag is consumed by causal specifications further down the pipeline. The two joins that build it (`sq_candidato → cpfCand`, then `cpfCand %in% eleito_*`) have zero integrity checks: no verification that `sq_candidato` keys are unique in the CPF lookup tables, no reporting of match rate. `filter(!is.na(incumbente))` at line 284 silently drops any candidate whose join failed, with no count printed — a partial join failure would bias the incumbency table without any visible trace.
- **Proposed fix:** After each cpfCand join, count and `message()` unmatched rows; before the final `filter(!is.na(incumbente))`, count and report how many candidates are excluded from Table D.

### Issue 2: Console output hygiene violated throughout — 15 `message()` + 9 `print()` calls
- **File:** `02_overlap_extensoes.R` (lines 54, 56, 60, 72, 85, 87, 113, 115, 127, 129, 154-157, 181-182, 197-198, 217, 230, 243, 256, 292-293, 317)
- **Category:** Console Output
- **Severity:** High
- **Rationale:** Every computed table in this script is already saved to RDS/CSV for downstream Quarto rendering — the `print()` calls are pure duplication. Since `02` has graduated into `scripts/R/` as production pipeline code, it should meet the production bar (one `message()` per major section, zero `print()`), not the exploratory one.
- **Proposed fix:** Drop all `print()` calls; collapse `message()` to one per section (B/C/D) summarizing row counts and output paths.

### Issue 3: No multiple-testing correction across repeated subgroup t-tests
- **File:** `02_overlap_extensoes.R:132-157`
- **Category:** Domain Correctness
- **Severity:** High
- **Rationale:** This script runs 4 t-tests (gender/race × capital/não-capital) on top of the 4 already run upstream in `01_overlap_partido.R` (gender/race × cargo × ano) — 8+ hypothesis tests with zero correction. `.claude/rules/inference-robustness.md` requires deciding and reporting a correction family for exactly this situation.
- **Proposed fix:** Pool p-values from this family with the upstream ones and apply a stated correction (e.g., Holm-Bonferroni), reporting both unadjusted and adjusted.

### Issue 4: No functions — three distinct blocks of duplicated logic
- **File:** `02_overlap_extensoes.R:207-256, 103-129, 185-198, 132-152`
- **Category:** Function Design
- **Severity:** High
- **Rationale:** This script has zero functions despite ~150 lines being three repeated patterns (CPF-based eleito extraction ×4, gap-table computation ×3, t-test extraction ×2). Beyond DRY, this creates invisible coupling: `incumbencia_map` silently depends on objects defined earlier with no explicit interface — reordering sections would break it with no error until a downstream `NULL`/missing-object failure.
- **Proposed fix:** Extract `get_eleitos_cpf(candidatos_path, eleitos_path)`, `compute_gap_table(...)`, and `run_group_ttest(...)` helpers.

### Issue 5: Reusable incumbency map computed but never persisted — forces duplicate reimplementation in `03_ddd_incentivo_2022.R`
- **File:** `02_overlap_extensoes.R:265-281`
- **Category:** RDS Data Pattern
- **Severity:** High
- **Rationale:** `03_ddd_incentivo_2022.R:153-184` independently rebuilds the exact same CPF-based incumbency logic from scratch, but encodes `incumbente` as `as.integer(...)` there vs. logical `TRUE/FALSE` here — a type inconsistency between two scripts computing the same variable. A future edit to one definition won't propagate to the other, and nothing would flag the drift.
- **Proposed fix:** `saveRDS(incumbencia_map, file.path(out_dir, "incumbencia_map_candidato.rds"))` here; have `03_ddd_incentivo_2022.R` read it instead of recomputing.

### Issue 6: `mean()` on logical vectors without explicit `na.rm`
- **File:** `02_overlap_extensoes.R:49, 74, 79, 174, 188, 286`
- **Category:** Numerical Discipline
- **Severity:** Medium
- **Rationale:** The project's numerical discipline standard requires explicit `na.rm` on every `mean()`/`sum()` call. The author *does* do this correctly elsewhere in the same script (lines 106, 120 use `na.rm = TRUE`) — the inconsistency itself signals `na.rm` isn't a deliberate per-case decision, which is the failure mode the rule exists to prevent.
- **Proposed fix:** Add explicit `na.rm = FALSE` (documenting the NA-free-by-construction assumption) at all flagged call sites.

### Issue 7: Missing defensive `dir.create()` for `out_dir`
- **File:** `02_overlap_extensoes.R:23`
- **Category:** Reproducibility
- **Severity:** Medium
- **Rationale:** `01_overlap_partido.R:29` correctly calls `dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)`; `02` assumes `01` already ran, which is documented, but the one-line idempotent safeguard costs nothing and protects against future reordering or partial re-runs.
- **Proposed fix:** Add the same `dir.create()` call.

### Issue 8: Header comments reference stale pre-migration paths
- **File:** `02_overlap_extensoes.R:11, 17`
- **Category:** Structure & Header / Comments
- **Severity:** Medium
- **Rationale:** Per the pipeline README, both `01` and `02` were "graduated" from `explorations/base-territorial-partidos/R/` on 2026-08-15, but header comments weren't updated: `R/01_overlap_partido.R` no longer exists at that relative path, and the referenced `scripts/08_baixar_candidatos_federal_2014.R` was never migrated (it lives under `explorations/base-territorial-partidos/scripts/`). A contributor following these instructions literally would fail to locate the referenced files.
- **Proposed fix:** Update both comments to the current, correct relative paths.

### Issue 9: Header lacks author/inputs/outputs metadata; sections unnumbered
- **File:** `02_overlap_extensoes.R:1-19`
- **Category:** Structure & Header
- **Severity:** Medium
- **Rationale:** Matches project's own header convention gap — missing author/inputs/outputs fields makes the script non-self-documenting for anyone opening it without the README.
- **Proposed fix:** Add Title/Author/Purpose/Inputs/Outputs/Requires fields to the header banner.

### Issue 10: `teste_capital_genero`/`teste_capital_raca` saved as RDS but not CSV, unlike every other table
- **File:** `02_overlap_extensoes.R:299-315`
- **Category:** RDS Data Pattern / Polish
- **Severity:** Low
- **Rationale:** Every other computed table gets both RDS (for Quarto) and CSV (for spreadsheet-friendly review/appendix export) — the two p-value tables are the sole exception with no stated reason.
- **Proposed fix:** Add `write_csv()` calls for both tables.

### Issue 11: Base-R bracket subsetting mixed into an otherwise tidyverse pipeline
- **File:** `02_overlap_extensoes.R:58-59`
- **Category:** Polish / Tidyverse Idioms
- **Severity:** Low
- **Rationale:** `mun_partido_cap$COD_MUN_TSE[mun_partido_cap$capital_flag]` is the only spot using `$` + `[...]` base-R subsetting in an otherwise consistent `|>` + dplyr pipeline.
- **Proposed fix:** Rewrite as `filter() |> pull() |> n_distinct()`.

### Issue 12: Duplicated literal factor-level vector
- **File:** `02_overlap_extensoes.R:179, 195`
- **Category:** Comments / Function Design (magic values)
- **Severity:** Low
- **Rationale:** A copy-pasted `c("Eleito", "Competitivo, não eleito", "Não competitivo")` level vector is a latent bug: if category labels are ever tweaked in the `case_when()` but the level vector is only updated at one of its two use sites, sort order silently breaks at the other.
- **Proposed fix:** Define `niveis_resultado` once, reuse at both `arrange()` calls.

### Issue 13: Two lines exceed the 100-character line-length convention
- **File:** `02_overlap_extensoes.R:261, 292`
- **Category:** Polish
- **Severity:** Low
- **Rationale:** Neither line is a mathematical-formula exception (the only carve-out in the conventions doc); both are trivially wrappable.
- **Proposed fix:** Wrap onto two lines each.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | No | 2 |
| Console Output | No | 1 |
| Reproducibility | No | 1 |
| Functions | No | 1 |
| Domain Correctness | No | 2 |
| Figures | N/A | 0 |
| RDS Pattern | No | 2 |
| Comments | No | 1 |
| Error Handling | No | 1 (cross-listed with Issue 1) |
| Polish | No | 2 |
| Numerical Discipline | No | 1 |
