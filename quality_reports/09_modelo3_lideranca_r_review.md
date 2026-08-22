# R Code Review: 09_modelo3_lideranca.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent

**Headline finding first:** the PMB/PMN handling described in the header is **correctly implemented** (confirmed at lines 76-80). The 07/08/09/10 renumbering is **internally self-consistent within this script**. The problems are elsewhere: a genuinely serious reproducibility/provenance issue where this "migrated" script still depends entirely on the unmigrated `explorations/` sandbox — including a helper file that already has a proper migrated copy sitting unused right next to this script — and stale numbering references in the *sibling* files `08_lideranca_partido.R` and `10_tabelas_graficos_modelo3.R`.

## Summary
- **Total issues:** 12 (+ 1 informational note)
- **Critical:** 1
- **High:** 3
- **Medium:** 5
- **Low:** 3

## Issues

### Issue 1: Migrated script isn't actually migrated — reads/writes the same sandbox directory as a stale duplicate pipeline, ignoring the already-migrated local helper
- **File:** `09_modelo3_lideranca.R:40,46`
- **Category:** Reproducibility
- **Severity:** Critical
- **Current:** `out_dir <- "explorations/base-territorial-partidos/output"` and `source("explorations/base-territorial-partidos/R/harmonizar_partido.R")`.
- **Rationale:** An identical, already-migrated copy of `harmonizar_partido.R` exists at `scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R` (byte-identical, diff-verified) — yet this script sources the sandbox copy instead, almost certainly a copy-paste artifact from the renumbering. More seriously: `out_dir` is the same directory used by the pre-renumbering duplicate pipeline still sitting in `explorations/base-territorial-partidos/R/` (Issue 2) — both pipelines write to identically-named `.rds`/`.tex` files in that one folder. There is currently no way to know, from the file system alone, which of the two implementations last produced `ddd_modelo3_genero_lideranca.rds` — the exact artifact Chapter 6 cites as its headline causal test.
- **Proposed fix:** `source("scripts/R/sobreposicao_territorial_partido/harmonizar_partido.R")`; migrate `out_dir` per the project's data-migration policy, or at minimum ensure no two pipelines write to the same folder concurrently.

### Issue 2: Stale duplicate pipeline in `explorations/` still exists with pre-renumbering internal references, sharing the migrated script's output directory
- **File:** `explorations/base-territorial-partidos/R/11_modelo3_lideranca.R:6,17,31` (and siblings `09_titulo_eleitoral_2018_2022.R`, `10_lideranca_partido.R`, `12_tabelas_graficos_modelo3.R`)
- **Category:** Structure / Reproducibility
- **Severity:** High
- **Rationale:** The exploration copy is internally consistent with itself (old numbering: 09=título, 10=liderança, 11=modelo3, 12=tabelas) but is now wrong relative to the current canonical numbering (07/08/09/10) used in `scripts/R/`. Left in place, a future contributor running the wrong copy would silently reproduce Chapter 6's headline model from the un-migrated, no-longer-maintained branch.
- **Proposed fix:** Delete the exploration-folder copies now that `scripts/R/` is canonical, or explicitly mark them deprecated and move to `ARCHIVE/`.

### Issue 3: Sibling script `10_tabelas_graficos_modelo3.R` still references pre-renumbering sibling filenames
- **File:** `10_tabelas_graficos_modelo3.R:8`
- **Category:** Structure / Comments
- **Severity:** High
- **Current:** `# Pré-requisito: rodar R/01, R/03, R/05, R/09, R/10 e R/11 antes.`
- **Rationale:** Under current numbering, `09` is this script itself and `10` is the table script referencing "R/09, R/10 e R/11" — numbers no longer point at the described scripts (título eleitoral = 07, liderança = 08). Also flag the same stale cross-reference in `08_lideranca_partido.R:213` ("o script 11" → should read "o script 09").
- **Proposed fix:** Correct to `R/01, R/03, R/05, R/07, R/08 e R/09`.

### Issue 4: Pervasive `message()`/`print()` diagnostic dumps — violates console-output hygiene
- **File:** `09_modelo3_lideranca.R:83-84,95-96,132-134,156-158,164-165,170-172,178-179,187-188,195-196,215-223`
- **Category:** Console Output
- **Severity:** High
- **Rationale:** Printing four full `feols` summaries plus multiple `count()`/`summarise()` tables to console is diagnostic-script behavior, not production-pipeline behavior — masks the real verification signal in a wall of text.
- **Proposed fix:** Keep one `message()` per major section; move regression output to `etable()`-generated artifacts instead of console.

### Issue 5: Sigla-resolution logic duplicated verbatim between `08_lideranca_partido.R` and this script
- **File:** `09_modelo3_lideranca.R:48-64`
- **Category:** Functions (DRY)
- **Severity:** High
- **Rationale:** Two independent computations of "which candidates have no resolvable TSE org record" (i.e., who becomes `NA` rather than `0`) is exactly the kind of drift risk the PMB/PMN design decision depends on staying correct. If `08`'s fallback logic is tweaked later without updating `09`, `lider_partido` values could silently diverge between the classifying script and the consuming script.
- **Proposed fix:** Extract `normalizar_sigla()`/`resolver_sigla_busca()` into a shared sourced file, or have `08` save `titulo_cand` with `sigla_busca` already resolved and have `09` read that instead of recomputing.

### Issue 6: No runtime assertion that PMB/PMN sanity check still holds
- **File:** `09_modelo3_lideranca.R:96`
- **Category:** Domain Correctness / Error Handling
- **Severity:** Medium
- **Rationale:** The PMB/PMN claim is asserted as a one-time manual "checagem de sanidade" from 2026-08-16, but nothing re-verifies it on subsequent runs (e.g., after the TSE snapshot is re-downloaded). If a future re-run adds a third unresolvable party, it would silently fall into the same NA-excluded bucket with no signal the assumption changed.
- **Proposed fix:** Add a `warning()` if the set of parties with `is.na(lider_partido)` ever differs from `c("PMB", "PMN")`.

### Issue 7: No multiplicity/inference-robustness treatment across the Model 1/2/3 × gender/race × main/robustness family
- **File:** `09_modelo3_lideranca.R:160-196`, `10_tabelas_graficos_modelo3.R:33-35`
- **Category:** Domain Correctness (Inference)
- **Severity:** Medium
- **Rationale:** `.claude/rules/inference-robustness.md`: "never pick the family that makes the result survive." A specification/model multiverse reported with individual significance stars is precisely the flagged pattern. The script's own comment ("decisão de como/se isso entra no capítulo fica para depois") shows this is genuinely still open.
- **Proposed fix:** Either apply a stepdown correction (Romano-Wolf via `wildrwolf`) across the 6-8 triple-interaction p-values, or explicitly document why Models 1/2/3 are robustness triangulation of a single estimand rather than a testing family.

### Issue 8: No accounting for singleton/dropped fixed-effect groups in `feols()`
- **File:** `09_modelo3_lideranca.R:160-163,174-177,183-186,191-194`
- **Category:** Error Handling / Domain Correctness
- **Severity:** Medium
- **Rationale:** `partido_harm × SG_UF` FE crossed with subgroup splits are a plausible source of singleton FE groups that `fixest` drops silently. Given this is "the chapter's most direct causal test," the effective N used for the headline coefficient should be logged and saved.
- **Proposed fix:** `message("N efetivo (feols) = ", nobs(modelo3_genero))` and save alongside the model.

### Issue 9: Missing `dir.create()` guard for `out_dir`
- **File:** `09_modelo3_lideranca.R:40`
- **Category:** Reproducibility
- **Severity:** Medium
- **Proposed fix:** Add `dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)`.

### Issue 10: `extrair_triplo()` returns an unnamed matrix slice, undocumented, magic regex
- **File:** `09_modelo3_lideranca.R:209-213`
- **Category:** Functions
- **Severity:** Medium
- **Proposed fix:** Return a named tibble (`estimate`, `std_error`, `p_value`) instead of a bare matrix slice; add roxygen doc; parameterize the regex.

### Issue 11: `resolver_sigla_busca()`/`normalizar_sigla()` undocumented; depends on free global variable
- **File:** `09_modelo3_lideranca.R:48-64`
- **Category:** Functions
- **Severity:** Low
- **Proposed fix:** Pass `siglas_disponiveis_norm` as an explicit parameter instead of relying on script-level state; add roxygen doc.

### Issue 12: 9 lines exceed the 100-character guideline (non-mathematical code)
- **File:** `09_modelo3_lideranca.R:49,54,132,217-219,221-223`
- **Category:** Polish
- **Severity:** Low
- **Rationale:** None qualify for the documented-math exception; lines 217-223 will shrink substantially once Issue 4 is fixed.

## Informational Note (not a defect)
`taxa_lideranca` and the four `ddd_modelo3_*` model objects are all correctly saved via `saveRDS()`. The two robustness objects (`ddd_modelo3_{genero,raca}_lideranca_completa.rds`) are not yet read anywhere in `10_tabelas_graficos_modelo3.R` — consistent with the script's own admission that reporting strategy is undecided. Not a bug, worth tracking so it doesn't become orphaned.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | Partial | 1 |
| Console Output | No | 1 |
| Reproducibility | No | 3 |
| Functions | Partial | 3 |
| Domain Correctness | Partial | 3 |
| Figures | N/A | 0 |
| RDS Pattern | Yes | 0 |
| Comments | Yes | 0 |
| Error Handling | Partial | 2 |
| Polish | Partial | 1 |
| Numerical Discipline | Yes | 0 |
