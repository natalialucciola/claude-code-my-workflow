# R Code Review: 07_titulo_eleitoral_2018_2022.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent
**File:** `scripts/R/sobreposicao_territorial_partido/07_titulo_eleitoral_2018_2022.R`

## Summary
- **Total issues:** 15
- **Critical:** 2
- **High:** 3
- **Medium:** 5
- **Low:** 5

**Numbering check:** The script's own header and both downstream siblings — `08_lideranca_partido.R` (line 32) and `09_modelo3_lideranca.R` (lines 6, 18, 31) — all correctly reference this script as `07_` and its consumer as `08_lideranca_partido.R`. No stale references to the old `09_` filename were found. Numbering is internally consistent across the pipeline.

## Issues

### Issue 1: Header claims "no prerequisite" but the script silently depends on `01_overlap_partido.R`
- **File:** `07_titulo_eleitoral_2018_2022.R:14, 58`
- **Category:** Reproducibility
- **Severity:** Critical
- **Current:** `# Pré-requisito: nenhum (não depende de outros scripts desta pasta).` then later `taxa_sobreposicao <- readRDS(file.path(out_dir, "taxa_sobreposicao_candidato.rds"))`.
- **Rationale:** `taxa_sobreposicao_candidato.rds` is produced only by `01_overlap_partido.R`. A user who runs `07_...R` standalone, following the header's explicit "no prerequisite" claim, hits an unhandled `readRDS()` file-not-found error. Documentation-correctness bug with a direct reproducibility consequence.
- **Proposed fix:** Correct the header to distinguish "part 1 (download): no prerequisite" from "part 2 (coverage check): requires `01_overlap_partido.R`", or gate the coverage section with an `file.exists()` check that warns and skips gracefully.

### Issue 2: `saveRDS()` called without `dir.create()` — script cannot run cleanly on a fresh clone
- **File:** `07_titulo_eleitoral_2018_2022.R:21, 54`
- **Category:** Reproducibility
- **Severity:** Critical
- **Rationale:** Sibling script `01_overlap_partido.R` calls `dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)` before its own `saveRDS()`; `07_...R` omits it. In practice `out_dir` already exists because `01`-`06` ran first, masking the bug — but the header (Issue 1) explicitly advertises this script as runnable with no prerequisite. On a genuinely fresh clone, `saveRDS()` fails.
- **Proposed fix:** Add `dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)` right after `out_dir` is defined.

### Issue 3: `baixar_titulo()` has no guard against a silently empty/zero-row result
- **File:** `07_titulo_eleitoral_2018_2022.R:23-36`
- **Category:** Error Handling
- **Severity:** High
- **Rationale:** This function's entire purpose is producing the linking key consumed by `08_lideranca_partido.R` and `09_modelo3_lideranca.R`. If TSE/`electionsBR` renames `DS_CARGO` values or the column layout shifts, `filter()` would silently return 0 rows and `bind_rows()` would proceed with a partial/empty key — corrupting Model 3's sample with no error anywhere in the pipeline.
- **Proposed fix:** Add `if (nrow(resultado) == 0L) stop(...)` inside `baixar_titulo()` after the filter/transmute.

### Issue 4: Duplicate join keys are reported to the console but never asserted/blocked
- **File:** `07_titulo_eleitoral_2018_2022.R:51-52`
- **Category:** Domain Correctness
- **Severity:** High
- **Rationale:** `08_lideranca_partido.R` and `09_modelo3_lideranca.R` both join on `(sq_candidato, cargo, ANO_ELEICAO)` assuming it is a unique key. A duplicate would silently multiply rows in every downstream table feeding Model 3's DDD regressions. `message()` alone is insufficient in a non-interactive `Rscript` run; a hard `stop()` is required before `saveRDS()`.
- **Proposed fix:** Turn the duplicate-count `message()` into a `stop()` when `n_dup > 0`.

### Issue 5: No error handling around the `elections_tse()` network calls
- **File:** `07_titulo_eleitoral_2018_2022.R:25`
- **Category:** Error Handling
- **Severity:** Medium
- **Rationale:** This script makes four live downloads of the full national candidate file from TSE's servers with zero error handling, unlike sibling `08_lideranca_partido.R` (which wraps its `read_delim()` in `tryCatch`). A transient TSE outage mid-download produces an opaque stack trace instead of an actionable message identifying which `(ano, cargo)` combination failed.
- **Proposed fix:** Wrap the `elections_tse()` call in `tryCatch()` with an informative `stop()` message naming the failing year/cargo.

### Issue 6: Unvalidated `as.character()` coercion risks silently corrupting the linking key
- **File:** `07_titulo_eleitoral_2018_2022.R:30-31`
- **Category:** Domain Correctness
- **Severity:** High
- **Rationale:** If `electionsBR` returns `NR_TITULO_ELEITORAL_CANDIDATO` (or `SQ_CANDIDATO`) as numeric/double rather than character, `as.character()` on a double can introduce scientific notation or drop leading structure. Since this becomes the join key against `08_lideranca_partido.R`'s character-typed column, any silent format mismatch would degrade the match rate without an obvious error — indistinguishable from a genuine null result in Model 3.
- **Proposed fix:** Add a regex format assertion (`^[0-9]{8,12}$`) on `titulo_eleitoral` after coercion, `stop()` if violated.

### Issue 7: Console output hygiene — nine `message()` calls plus a `print()`
- **File:** `07_titulo_eleitoral_2018_2022.R:24, 47-52, 70-84, 86`
- **Category:** Console Output
- **Severity:** Medium
- **Rationale:** Per project convention, `message()` should be used sparingly (one per major section) and `print()` should not be used for status output. This script uses `message()` roughly nine times and one `print()` for what is effectively a QA report.
- **Proposed fix:** Persist the coverage summary as RDS (see Issue 10) and collapse status messages to one per phase.

### Issue 8: No caching of the four raw `elections_tse()` downloads
- **File:** `07_titulo_eleitoral_2018_2022.R:38-41`
- **Category:** Reproducibility
- **Severity:** Medium
- **Rationale:** `elections_tse(type = "candidate")` downloads the full national candidate file for a given year — a non-trivial, multi-minute network operation, done here four times (Federal and Estadual for the same year are fetched via two separate calls, doubling network cost per year). `08_lideranca_partido.R` uses a cached local snapshot specifically to avoid this pattern; `07` does not apply the same discipline to itself.
- **Proposed fix:** Cache each raw download to `out_dir` and skip re-download if the cache file already exists.

### Issue 9: `baixar_titulo()` lacks roxygen-style documentation
- **File:** `07_titulo_eleitoral_2018_2022.R:23`
- **Category:** Functions
- **Severity:** Medium
- **Rationale:** Per `r-code-conventions.md` §2, every non-trivial function needs roxygen-style docs. This function performs live network I/O and a schema-dependent filter/transmute — exactly the kind of function whose contract should be documented.
- **Proposed fix:** Add `#' @param`/`@return` roxygen block.

### Issue 10: Coverage/QA summary table computed but never persisted
- **File:** `07_titulo_eleitoral_2018_2022.R:76-84`
- **Category:** RDS Pattern
- **Severity:** Medium
- **Rationale:** The coverage-by-cargo-x-ano table is only `print()`'d, never saved. This is the QA evidence for how much of the Model 3 sample has a resolvable título eleitoral — worth keeping on disk, especially since the chapter's methods section may want to cite the match rate.
- **Proposed fix:** `saveRDS()` the coverage summary to `out_dir`.

### Issue 11: No numbered top-level sections, unlike sibling scripts
- **File:** `07_titulo_eleitoral_2018_2022.R:17-87`
- **Category:** Structure
- **Severity:** Low
- **Rationale:** Sibling scripts (`01_overlap_partido.R`, `05_modelo2_incumbente.R`, `09_modelo3_lideranca.R`) all use numbered `# N. SECTION NAME` headers; `07` breaks that convention with a single unnumbered divider.
- **Proposed fix:** Add `# 1. DOWNLOAD` / `# 2. CHECAGEM DE COBERTURA` section banners.

### Issue 12: Repetitive four-call pattern could be collapsed (DRY)
- **File:** `07_titulo_eleitoral_2018_2022.R:38-41`
- **Category:** Functions / Polish
- **Severity:** Low
- **Rationale:** Four near-identical `baixar_titulo()` calls — collapsing to a lookup table + `pmap()` makes it trivially easy to add a third election year later.
- **Proposed fix:** Use a `tibble::tribble()` of (ano, cargo_desejado, cargo_label) combinations with `purrr::pmap()`.

### Issue 13: Bare numeric year literals passed where integers are conceptually intended
- **File:** `07_titulo_eleitoral_2018_2022.R:38-41`
- **Category:** Numerical Discipline / Polish
- **Severity:** Low
- **Rationale:** Project convention favors `L`-suffixed integer literals for conceptually integer values. Minor consistency nit only.
- **Proposed fix:** `2018L` instead of `2018`.

### Issue 14: Mixed naming convention within a single `transmute()`
- **File:** `07_titulo_eleitoral_2018_2022.R:29-35`
- **Category:** Polish
- **Severity:** Low
- **Rationale:** `sq_candidato`/`titulo_eleitoral`/`cargo` are `snake_case`, while `SG_UF`/`SG_PARTIDO`/`ANO_ELEICAO` retain raw TSE `UPPER_SNAKE_CASE`. Matches existing pipeline-wide convention, not a regression introduced by this script — noted for completeness only.

### Issue 15: Base-R subsetting instead of `dplyr::select()`
- **File:** `07_titulo_eleitoral_2018_2022.R:52`
- **Category:** Polish
- **Severity:** Low
- **Rationale:** `titulo_eleitoral_candidato[, c("sq_candidato", "cargo", "ANO_ELEICAO")]` reverts to base-R `[` subsetting in an otherwise tidyverse pipeline. Purely cosmetic.
- **Proposed fix:** `dplyr::select(titulo_eleitoral_candidato, sq_candidato, cargo, ANO_ELEICAO)`.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | No | 1 |
| Console Output | No | 1 |
| Reproducibility | No | 3 |
| Functions | No | 2 |
| Domain Correctness | No | 2 |
| Figures | N/A | 0 |
| RDS Pattern | No | 1 |
| Comments | Yes | 0 |
| Error Handling | No | 2 |
| Polish | No | 2 |
| Numerical Discipline | No | 1 |

**Note on Comments quality:** the header's WHY-explanations are genuinely strong (clear rationale for re-downloading rather than reprocessing, explicit statement of what's confirmed about the raw schema) — the sole documentation defect is the factually incorrect "Pré-requisito: nenhum" claim, filed under Reproducibility (Issue 1) rather than double-counted here.
