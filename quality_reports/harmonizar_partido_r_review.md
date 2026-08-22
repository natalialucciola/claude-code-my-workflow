# R Code Review: harmonizar_partido.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent
**File reviewed:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R` (identical duplicate at `explorations/base-territorial-partidos/R/harmonizar_partido.R`)

## Summary
- **Total issues:** 10
- **Critical:** 1
- **High:** 4
- **Medium:** 3
- **Low:** 2

The 27-line function itself is small and mechanically clean (no float `==`, no loops, no `T`/`F`, no absolute paths, no console spam). The dominant problem is not inside the file — it is that the file has been "graduated" to the production pipeline folder in name only. Every script that actually needs this shared helper still `source()`s the untracked exploration sandbox copy, making the tracked `scripts/R/` copy dead code and creating a silent single-source-of-truth hazard for a function that determines party identity across the entire H1–H5 Chapter 6 pipeline.

## Issues

### Issue 1: Tracked "migrated" copy is never sourced — production scripts still reach into the exploration sandbox
- **File:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R` (orphaned); actual dependency is `explorations/base-territorial-partidos/R/harmonizar_partido.R`
- **Category:** Reproducibility / Single-Source-of-Truth
- **Severity:** Critical
- **Current:** All three "graduated" production pipeline scripts source the exploration path, not the tracked production copy: `01_overlap_partido.R:21`, `08_lideranca_partido.R:174`, `09_modelo3_lideranca.R:46` all run `source("explorations/base-territorial-partidos/R/harmonizar_partido.R")`. Meanwhile `README.md:14` lists `harmonizar_partido.R` as step 1 of the "Ordem de execução", implying the tracked copy in the same folder is the operative one. Repo-wide grep for `source(.*harmonizar_partido` finds exactly 7 call sites (3 in `scripts/R/sobreposicao_territorial_partido/`, 4 in `explorations/base-territorial-partidos/R/`) — **all seven point at the exploration-sandbox path**, none at the tracked production copy.
- **Proposed fix:** Pick one canonical file and delete the other. Given the stated migration intent, the more consistent fix is to change the three `source()` calls to `source("scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R")` and delete (or reduce to a stub) the exploration copy — unless the un-migrated exploration script `07_versao_b_universo_completo.R` (marked SUPERSEDED) still needs it for historical reproducibility, in which case keep both but add a repo-wide check confirming there is exactly one source-of-truth target.
- **Rationale:** A shared party-harmonization table is exactly the kind of dependency where silent drift is catastrophic and invisible — two copies that diverge would corrupt `partido_harm` for a subset of scripts only, with no error, no warning, and no test to catch it. This is the single-source-of-truth failure mode `CLAUDE.md` explicitly calls out for the manuscript; the same discipline needs to apply to shared analysis code.

### Issue 2: `harmonizar_partido()` has no documentation
- **File:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R:19-27`
- **Category:** Functions
- **Severity:** High
- **Rationale:** `.claude/rules/r-code-conventions.md` §2/§9 requires roxygen-style docs for functions; this is the sole exported symbol of a shared utility file sourced by 3+ pipeline scripts, so its contract (input type, NA behavior, "unmatched sigla passes through unchanged") needs to be explicit for any future editor who did not write it.
- **Proposed fix:** Add roxygen `#'` doc block: `@param sigla` character vector of raw TSE siglas, `@return` character vector same length, `NA_character_` for PHS.

### Issue 3: `partido_map` is a bare global injected into the caller's environment
- **File:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R:7-17`
- **Category:** Functions / Reproducibility
- **Severity:** High
- **Rationale:** `source()`ing this file three times across the pipeline injects `partido_map` into each caller's global environment as a side effect distinct from the function itself. If any calling script defines its own `partido_map` for another purpose, it silently overwrites or is overwritten — a namespace collision invisible until results change.
- **Proposed fix:** Scope the lookup table as a default function argument (`harmonizar_partido <- function(sigla, map = c(...))`) instead of a bare top-level assignment.

### Issue 4: PHS -> NA mapping is an unverified, uncited domain claim
- **File:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R:25`
- **Category:** Domain Correctness
- **Severity:** High
- **Current:** `harm[sigla == "PHS"] <- NA_character_`
- **Rationale:** This lookup table is foundational — it feeds `partido_harm`, which drives the H1–H5 within-party coordination analysis for the entire chapter. An uncited "special case" carved out of the otherwise-systematic `partido_map` needs a named source (TSE resolution, date) before it can be trusted. Could not verify Brazilian party-merger history against a live source in this review; flagging for the author/domain expert to confirm (PHS is commonly reported as absorbed by PODE in 2019 — if true, this line silently drops those candidates' party identity instead of recoding them).
- **Proposed fix:** Add an inline citation comment naming the TSE resolution/date confirming PHS's disposition, or correct to the actual successor party if PODE is confirmed.

### Issue 5: No completeness check against actual TSE party codes in the data
- **File:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R` (whole function)
- **Category:** Error Handling / Domain Correctness
- **Severity:** High
- **Rationale:** No assertion anywhere that `partido_map`'s 9 entries + PHS are the *complete* set of party renames/mergers between 2018 and 2022 present in the data. Any sigla not in the map falls through unchanged with no warning — a legitimate overlooked rename would quietly corrupt `taxa_sobreposicao` for that party's candidates with no error, no NA, no trace.
- **Proposed fix:** Add an optional `warning()` for siglas not in `partido_map`, the PHS case, or a documented "known-stable" allowlist.

### Issue 6: PHS special-cased outside `partido_map`, fragile to `NA` inputs
- **File:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R:19-27`
- **Category:** Functions / Numerical Discipline
- **Severity:** Medium
- **Rationale:** Two structurally different mechanisms (lookup table + hand-written subset-assignment) implement one recode operation. If `sigla` legitimately contains `NA`, `sigla == "PHS"` evaluates to `NA` rather than `FALSE`, and `harm[NA] <- NA_character_` assignment semantics are undocumented/untested here.
- **Proposed fix:** Replace with a single `dplyr::case_match()` call covering `partido_map` + `"PHS" ~ NA_character_` + `.default = sigla` — NA-safe and self-documenting in one place.

### Issue 7: No WHY-comment / citation for the specific party mergers encoded
- **File:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R:7-17`
- **Category:** Comments
- **Severity:** Medium
- **Rationale:** The header comment explains why the file exists but not why each specific mapping is correct. Every row of `partido_map` is a factual domain claim about Brazilian electoral law that a future maintainer or replication-package reviewer should be able to audit without re-deriving it from scratch.
- **Proposed fix:** Add a comment block citing the specific TSE resolution/date for each merger/renaming (DEM+PSL->UNIÃO, PPS->CIDADANIA, etc.).

### Issue 8: Federal-vs-Estadual `partido_harm` consistency is assumed, never verified
- **File:** `01_overlap_partido.R:39-57` (caller); `harmonizar_partido.R` (this file)
- **Category:** Domain Correctness
- **Severity:** Medium
- **Rationale:** Federal datasets already carry a precomputed `partido_harm` (from an external, untracked "Codigo de Apoio.R" source per this file's header comment), while Estadual datasets compute it fresh via this function — then the two are `bind_rows()`'d as if consistent. If the original external source's logic ever diverged from this copy, Federal and Estadual labels would be silently inconsistent within the same merged data frame.
- **Proposed fix:** Add a one-time cross-check (`stopifnot`) comparing precomputed vs. locally-computed `partido_harm` for parties present in both sources, for at least one election cycle.

### Issue 9: No formal header block per project convention
- **File:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R:1-5`
- **Category:** Structure & Header
- **Severity:** Low
- **Rationale:** It is listed as a formal numbered pipeline step in the README ("Ordem de execução" #1), so it should carry the same Purpose/Inputs/Outputs header discipline as the numbered scripts around it, even though it's small.
- **Proposed fix:** Add a `# ====...` banner with Purpose/Inputs/Outputs fields consistent with sibling scripts.

### Issue 10: Unnamed vector return (checklist note, not a real violation)
- **File:** `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R:26`
- **Category:** Functions
- **Severity:** Low
- **Rationale:** `unname(harm)` returns a plain character vector, not a named list/tibble — flagged for completeness against the review checklist, but this is the correct, idiomatic return type for a vectorized recoding helper used inside `mutate()`. No action needed.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | No | 1 |
| Console Output | Yes | 0 |
| Reproducibility | No | 2 (Issues 1, 3) |
| Functions | No | 3 (Issues 2, 3, 6) |
| Domain Correctness | No | 3 (Issues 4, 5, 8) |
| Figures | N/A | 0 |
| RDS Pattern | N/A | 0 |
| Comments | No | 1 |
| Error Handling | No | 1 (Issue 5) |
| Polish | Yes | 0 |
| Numerical Discipline | No | 1 (Issue 6, NA-index fragility) |

## Cross-Artifact Note

Confirmed: `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R` and `explorations/base-territorial-partidos/R/harmonizar_partido.R` are **byte-identical** (28 lines). Repo-wide grep for `source(.*harmonizar_partido` finds exactly 7 call sites: 3 in `scripts/R/sobreposicao_territorial_partido/` (`01_overlap_partido.R:21`, `08_lideranca_partido.R:174`, `09_modelo3_lideranca.R:46`); 4 in `explorations/base-territorial-partidos/R/` (`01_overlap_partido.R:21`, `07_versao_b_universo_completo.R:33`, `10_lideranca_partido.R:174`, `11_modelo3_lideranca.R:46`) — **all seven point at the exploration-sandbox path**, none at the tracked production copy. This is Issue 1 above (Critical).
