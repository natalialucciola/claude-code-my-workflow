# R Code Review: 08_lideranca_partido.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent

**Numbering check:** PASSED. `07_titulo_eleitoral_2018_2022.R`, `08_lideranca_partido.R` (this file), `09_modelo3_lideranca.R`, and `10_tabelas_graficos_modelo3.R` are internally consistent with the current 07→08→09→10 numbering. `README.md` matches. No stale filename references found within this file.

## Summary
- **Total issues:** 16
- **Critical:** 2
- **High:** 2
- **Medium:** 7
- **Low:** 5

## Issues

### Issue 1: Missing zip existence guard — silent failure on missing 209MB raw file
- **File:** `08_lideranca_partido.R:59`
- **Category:** Reproducibility
- **Severity:** Critical
- **Current:** `arquivos <- unzip(zip_path, list = TRUE)$Name` with no prior `file.exists(zip_path)` check.
- **Rationale:** `base::unzip()` does not `stop()` when the target zip is missing or corrupt — it emits a `warning()` and returns `NULL`. Downstream, `arquivos` becomes length 0, the loop never executes, `bind_rows(list())` yields an empty tibble, and `saveRDS()` still succeeds — writing an **empty** `lideranca_raw.rds`/`lideranca_candidato.rds` with no hard error. The pipeline continues and eventually breaks much further downstream (in `09_modelo3_lideranca.R`, when `feols` hits zero rows), by which point the failure looks like a modeling bug, not a missing 209MB file that lives outside git (`raw_tse_orgaos/`, gitignored).
- **Proposed fix:** Add `if (!file.exists(zip_path)) stop("Snapshot SGIP não encontrado em ", zip_path, ". Baixe de [URL] e salve em ", dirname(zip_path), ".")` before the `unzip()` call, and `if (length(arquivos) == 0L) stop(...)` after it.

### Issue 2: Inner join on título eleitoral without excluding blank/NA keys
- **File:** `08_lideranca_partido.R:197-207`
- **Category:** Domain Correctness
- **Severity:** Critical
- **Rationale:** `07_titulo_eleitoral_2018_2022.R`'s own coverage check treats `titulo_eleitoral == ""` as a real, non-trivial category of missing data on the candidate side. `NR_TITULO_ELEITORAL_MEMBRO` in the SGIP export can equally be blank for older/incomplete membership records. `dplyr::inner_join()` treats `"" == ""` as a real match (unlike `NA == NA`, which never matches). Any party × year with at least one blank-título leadership record will spuriously match every candidate of that party/year whose own título is also blank — silently fabricating `lider_partido = 1` observations that feed directly into Model 3's H4 test.
- **Proposed fix:** `filter(!is.na(titulo_eleitoral), titulo_eleitoral != "")` on both sides of each join before joining; add a post-join sanity assertion that no matched pair has an empty título.

### Issue 3: `classificar_cargo()` regex is too permissive — risks capturing non-decision-making roles
- **File:** `08_lideranca_partido.R:50-57`
- **Category:** Domain Correctness
- **Severity:** High
- **Rationale:** The header's theoretical justification for including NACIONAL-scope leadership is "poder de decisão sobre a distribuição de recursos." Brazilian party statutes commonly register titles like "PRESIDENTE DE HONRA" (honorary, no operational authority) or "PRESIDENTE EM EXERCÍCIO" (interim/delegate). The current regex would classify any of these as full "PRESIDENTE," contaminating the leadership variable with roles that don't carry the causal mechanism being tested. No audit step exists anywhere in the script printing the distinct `DS_CARGO_MEMBRO` values actually matched.
- **Proposed fix:** Add an exclusion clause for "HONRA"/"HONORARI"/interim titles; run a one-off diagnostic (`distinct(DS_CARGO_MEMBRO)` classified) to manually verify before trusting the classifier for a thesis chapter.

### Issue 4: `abrangencia_norm %in% c(...)` exact-string filter is brittle and unvalidated
- **File:** `08_lideranca_partido.R:97`
- **Category:** Domain Correctness
- **Severity:** High
- **Rationale:** `normalizar()` only upper-cases, ASCII-transliterates, and `str_squish()`s — it does not normalize spacing around punctuation. If the raw TSE label is `"REGIONAL(DF)"` (no space) rather than `"REGIONAL (DF)"`, the exact-match filter silently drops every state-directory-in-DF leadership record with zero warning. This determines the ESTADUAL/REGIONAL(DF) half of the leadership variable used in Model 3.
- **Proposed fix:** Replace the exact `%in%` match with `str_detect()`-based matching that tolerates spacing variants, after confirming actual raw values via a one-off `distinct(DS_TIPO_ABRANGENCIA)` check.

### Issue 5: No documentation on any function
- **File:** `08_lideranca_partido.R:43,50,83,157,164`
- **Category:** Functions
- **Severity:** Medium
- **Rationale:** `processar_arquivo()` in particular is non-trivial (date-overlap logic, filter chain, `unnest()`) and is exactly the kind of function the project's conventions require to carry roxygen documentation. (Sibling scripts 07/09 have the same gap — pipeline-wide pattern.)
- **Proposed fix:** Add `#'` roxygen blocks documenting `@param`/`@return` for `processar_arquivo()`, `classificar_cargo()`, `resolver_sigla_busca()`.

### Issue 6: `tidyr::unnest()` used without declaring `library(tidyr)`
- **File:** `08_lideranca_partido.R:36-38,123`
- **Category:** Reproducibility
- **Severity:** Medium
- **Rationale:** Convention requires all packages declared via `library()` at top so a missing dependency fails immediately at script start, not 120 lines into a ~209MB zip read.
- **Proposed fix:** Add `library(tidyr)` alongside the other `library()` calls; drop the `tidyr::` prefix.

### Issue 7: `source()` for `harmonizar_partido()` placed mid-script, not with other dependencies
- **File:** `08_lideranca_partido.R:174`
- **Category:** Reproducibility
- **Severity:** Medium
- **Rationale:** Functionally correct today because `resolver_sigla_busca()` is only called after line 174, but fragile to any future reordering. All external dependencies should fail fast at script start.
- **Proposed fix:** Move the `source()` call to the top of the script, alongside `library()` calls.

### Issue 8: Magic date literals hardcoded inside `processar_arquivo()`
- **File:** `08_lideranca_partido.R:108-109`
- **Category:** Functions
- **Severity:** Medium
- **Rationale:** The four hardcoded date literals (2018-01-01/12-31, 2022-01-01/12-31) are the entire election-cycle scope of the script; hardcoding them inside the function body means extending to a third cycle (e.g. 2026) requires editing function internals rather than passing an argument.
- **Proposed fix:** Parameterize as `anos_eleicao = c("2018", "2022")` with a default, deriving the date windows from it.

### Issue 9: No `dir.create()` before `saveRDS()`
- **File:** `08_lideranca_partido.R:141,227`
- **Category:** Reproducibility
- **Severity:** Medium
- **Rationale:** The script assumes `out_dir` already exists (created implicitly by earlier pipeline steps). A clean clone running this script first would fail at `saveRDS()`.
- **Proposed fix:** Add `dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)`.

### Issue 10: Console output hygiene — 13 `message()` calls plus a `print()`
- **File:** `08_lideranca_partido.R:61,126,131,137-139,179-180,222-225,229`
- **Category:** Console Output
- **Severity:** Medium
- **Rationale:** Protocol asks for one `message()` per major section maximum, with no `print()` for status/progress. The summary table (`count(escopo, cargo_lideranca)`) is exactly the kind of derived object that should be `saveRDS()`d rather than only printed and lost.
- **Proposed fix:** Save the scope-summary table as RDS; collapse status messages to one per section.

### Issue 11: Per-file parse failures logged individually but never aggregated/counted
- **File:** `08_lideranca_partido.R:83-90`
- **Category:** Error Handling
- **Severity:** Medium
- **Rationale:** `is.null(d)` covers both "genuinely no matching leadership rows" (benign) and "failed to parse" (a real data-integrity problem) with the same silent `return(NULL)` — a reader has to scroll through interleaved per-file progress messages to spot an error line.
- **Proposed fix:** Add an explicit aggregate count of failures right after the loop, before `bind_rows()`.

### Issue 12: Header missing explicit Author/Inputs/Outputs fields; no numbered top-level sections
- **File:** `08_lideranca_partido.R:1-34`
- **Category:** Structure & Header
- **Severity:** Low
- **Rationale:** Header documents purpose, source URL, and design decisions thoroughly (excellent WHY content) but has no `Author:`/`Inputs:`/`Outputs:` fields. Pipeline-wide gap, not unique to this file.
- **Proposed fix:** Add the missing header fields.

### Issue 13: Redundant regex branch in `classificar_cargo()`
- **File:** `08_lideranca_partido.R:53`
- **Category:** Polish
- **Severity:** Low
- **Rationale:** `str_detect(cargo_norm, "^PRESIDENTE$")` (exact match) is a strict subset of the second disjunct in the same `case_when()` clause — dead code.
- **Proposed fix:** Remove the redundant first disjunct.

### Issue 14: Inconsistent namespace qualification for already-loaded packages
- **File:** `08_lideranca_partido.R:157-160,167`
- **Category:** Polish
- **Severity:** Low
- **Rationale:** Some calls use `stringr::`/`dplyr::` prefixes, most don't — reads as accidental rather than deliberate.
- **Proposed fix:** Drop the prefixes for consistency (both packages already `library()`d).

### Issue 15: Bare `0` compared against `nrow()` instead of `0L`
- **File:** `08_lideranca_partido.R:90,101`
- **Category:** Numerical Discipline
- **Severity:** Low
- **Proposed fix:** Use `0L` for integer comparison consistency.

### Issue 16: Line exceeds 100 characters in non-mathematical code
- **File:** `08_lideranca_partido.R:53`
- **Category:** Polish
- **Severity:** Low
- **Rationale:** Not a mathematical formula, so the length exception doesn't apply. Resolved as a side effect of Issue 13's fix.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | Partial | 1 |
| Console Output | No | 1 |
| Reproducibility | No | 4 |
| Functions | No | 2 |
| Domain Correctness | No | 3 |
| Figures | N/A | 0 |
| RDS Pattern | Yes | 0 |
| Comments | Yes | 0 |
| Error Handling | Partial | 1 |
| Polish | No | 3 |
| Numerical Discipline | Partial | 1 |

## Notable strengths
- Comment quality is genuinely exemplary for a research pipeline: the header explains *why* leadership scope includes NACIONAL+ESTADUAL+REGIONAL(DF) but excludes MUNICIPAL, *why* the sigla-matching key uses per-cycle `SG_PARTIDO` rather than `partido_harm`, and *why* the fallback-to-harmonized-name logic is safe for renamings but not for new-registry mergers.
- `vector("list", length(arquivos))` correctly pre-allocates before the loop.
- Consistent native-pipe (`|>`) usage throughout.
- Both output RDS files satisfy the RDS pattern that downstream consumers depend on.
