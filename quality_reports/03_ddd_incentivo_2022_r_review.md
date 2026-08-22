# R Code Review: 03_ddd_incentivo_2022.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent
**File reviewed:** `scripts/R/sobreposicao_territorial_partido/03_ddd_incentivo_2022.R`

## Summary
- **Total issues:** 17
- **Critical:** 3
- **High:** 4
- **Medium:** 6
- **Low:** 4

This script fits the thesis's central causal specification for Chapter 6 (the triple-DiD test of EC 111/2021's effect on territorial overlap). The methodological reasoning in the header comments (bad-control logic for incumbência, honest acknowledgment of the 2-period pre-trends limitation) is genuinely strong and above-average for this kind of script. The issues below are concentrated in (a) inference robustness for the headline coefficient, which is not optional given this is the chapter's core causal claim, and (b) console-output / RDS-persistence hygiene.

## Issues

### Issue 1: No few-cluster robustness check on the headline triple-interaction coefficient
- **File:** `03_ddd_incentivo_2022.R:66-70, 88-92`
- **Category:** Domain Correctness / Inference Robustness
- **Severity:** Critical
- **Rationale:** `.claude/rules/inference-robustness.md` names exactly this scenario — "wild-cluster bootstrap with few clusters" — as a hard requirement. Two-way cluster-robust SEs with ~27 UFs and 34 harmonized parties (per the chapter's own numbers) are below or near the ~40-cluster rule-of-thumb threshold where asymptotic CRVE inference over-rejects. Since the triple interaction `federal:ano2022:mulher`/`federal:ano2022:negra` is the single number the chapter's causal claim rests on, its significance must survive a small-cluster-robust check before being reported as evidence for or against the EC 111 mechanism.
- **Proposed fix:** Run `fwildclusterboot::boottest()` on the triple-interaction coefficient for both the gênero and raça models, save alongside the raw `feols` objects.

### Issue 2: No stated testing family or multiple-testing correction across the six regressions
- **File:** `03_ddd_incentivo_2022.R:66-219` (whole script)
- **Category:** Domain Correctness / Inference Robustness
- **Severity:** Critical
- **Rationale:** Six models are fit (gênero/raça × main/resultado/incumbência), each producing a triple-interaction p-value, with no discussion of the testing family or correction. `.claude/rules/inference-robustness.md`: "Pre-register the family and the correction... Report both unadjusted and adjusted; never pick the family that makes the result survive." Six regressions targeting two estimands with a shared substantive claim is exactly the family this rule is written for — especially given the chapter's own characterization of the causal evidence as "at most marginal for gender, null for race."
- **Proposed fix:** Bind the six triple-interaction coefficients into one table with `spec` labels, apply `p.adjust(method = "holm")`, save and report both columns.

### Issue 3: Missing `dir.create()` before first write to `out_dir`
- **File:** `03_ddd_incentivo_2022.R:30, 225-236`
- **Category:** Reproducibility
- **Severity:** Critical
- **Rationale:** If `out_dir` doesn't yet exist (a fresh clone that has never run any script in this pipeline), every `saveRDS()`/`etable()` call in Section 6 fails. This script inherits an implicit dependency on upstream scripts having already created the directory, without stating or defending against it.
- **Proposed fix:** Add `dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)` right after `out_dir` is defined.

### Issue 4: Pervasive `print()`/status `message()` output throughout
- **File:** `03_ddd_incentivo_2022.R:50, 58-64, 72-73, 81-86, 94-95, 121-122, 134-135, 173-176, 186-190, 197-198, 206-207, 218-219`
- **Category:** Console Output Hygiene
- **Severity:** High
- **Rationale:** Ten `print()` calls and roughly fifteen `message()` calls mean every diagnostic (cell counts, coverage %, full regression summaries) is computed, displayed once, and discarded — unusable for the thesis unless the script is re-run interactively.
- **Proposed fix:** Replace diagnostic `print()` blocks with saved objects (see Issue 5); reduce to one `message()` per major section.

### Issue 5: Diagnostic support/coverage tables computed but never persisted
- **File:** `03_ddd_incentivo_2022.R:62-64, 84-86, 186-190`
- **Category:** RDS Data Pattern
- **Severity:** High
- **Rationale:** These "check support before trusting the DDD estimate" tables are exactly the kind of methodological evidence a dissertation committee or referee would ask to see (cell balance is a standard DDD sanity check). If Chapter 6 prose ever needs to state "the smallest cell has N candidates," that number currently only exists in a console that closed after the script last ran.
- **Proposed fix:** `saveRDS()` the cell-support and incumbência-coverage tables.

### Issue 6: Heavy code duplication with no extraction into helper functions
- **File:** `03_ddd_incentivo_2022.R:66-95 (model fitting), 153-171 (eleito construction)`
- **Category:** Function Design
- **Severity:** High
- **Rationale:** Six near-identical `feols()` calls, and four near-identical CPF-extraction blocks. A change to the clustering scheme or FE structure (live possibility given Issue 1) has to be applied identically in six places by hand — a classic source of silent divergence between gênero and raça specifications.
- **Proposed fix:** Extract `fit_ddd_overlap(data, group_var, extra_controls = NULL)` and `get_eleitos_cpf(path_resultado, path_cand)` helpers.

### Issue 7: `resultado` is a same-period post-treatment control, but the comment under-documents why
- **File:** `03_ddd_incentivo_2022.R:97-100`
- **Category:** Domain Correctness / Comment Quality
- **Severity:** High
- **Rationale:** The script correctly uses bad-control logic to justify excluding incumbência/resultado from the main spec (lines 13-18), but when `resultado` reappears as a control in Section 4, the comment only says "not the causal spec" without restating the same reasoning. Comprehension gap for anyone reading Section 4 in isolation.
- **Proposed fix:** Expand the Section 4 comment to explicitly restate the bad-control logic (resultado measured in the same election-year as the outcome).

### Issue 8: `out_dir` points at the pre-migration `explorations/` tree, not a canonical `scripts/R/` location
- **File:** `03_ddd_incentivo_2022.R:30`
- **Category:** Reproducibility / RDS Data Pattern
- **Severity:** Medium
- **Rationale:** Verified this is not unique to this script — `04_tabelas_graficos_consolidacao.R` uses the identical `out_dir`, and the exploration-folder twin (`explorations/base-territorial-partidos/R/03_ddd_incentivo_2022.R`) is byte-identical in header/out_dir — a systemic drift risk if either copy is edited without the other, mirroring the `harmonizar_partido.R` single-source-of-truth issue found elsewhere in this pipeline.
- **Proposed fix:** No single-script fix without a pipeline-wide migration decision; flagging for visibility alongside the same issue in `harmonizar_partido.R`.

### Issue 9: Stale relative-path reference in comment (Section 5 header)
- **File:** `03_ddd_incentivo_2022.R:140-141`
- **Category:** Comment Quality
- **Severity:** Medium
- **Rationale:** Comment references `scripts/08_baixar_candidatos_federal_2014.R`, but the file only exists at `explorations/base-territorial-partidos/scripts/08_baixar_candidatos_federal_2014.R`. A future reader following this comment to understand data provenance will fail to find the file.
- **Proposed fix:** Correct the path in the comment.

### Issue 10: Header lacks explicit `Outputs:` list and author attribution
- **File:** `03_ddd_incentivo_2022.R:1-25`
- **Category:** Structure & Header
- **Severity:** Medium
- **Rationale:** Header states purpose, specification, and known limitations well, but never enumerates what the script produces, and has no author/date field. Script 04 consumes six of this script's outputs by hardcoded filename — an explicit outputs list is what lets a reader verify the contract without reading to line 231.
- **Proposed fix:** Add `Autor:`/`Outputs:` fields listing the six `.rds` files and the `.tex` table.

### Issue 11: No leave-one-out / alternate-clustering robustness sweep despite this being the chapter's central causal test
- **File:** `03_ddd_incentivo_2022.R:66-219`
- **Category:** Domain Correctness / Inference Robustness
- **Severity:** Medium
- **Rationale:** The script varies the *covariate* specification (3 variants × 2 groups) well but never varies the *inference* specification — the half of the robustness battery most load-bearing for a causal claim already characterized as "marginal."
- **Proposed fix:** Add single-way clustering (SG_UF only, partido_harm only) as a robustness check on the headline coefficient.

### Issue 12: No explicit NA/Inf audit on `taxa_sobreposicao` before model fitting
- **File:** `03_ddd_incentivo_2022.R:36-50, 66-70`
- **Category:** Error Handling
- **Severity:** Medium
- **Rationale:** `taxa_sobreposicao` is a ratio computed upstream; division-by-zero/undefined-overlap cases for single-municipality candidates are a plausible source of `NA`/`Inf` that would silently shrink the estimation sample (via `feols()`'s silent row-dropping) with no auditable trail in this script.
- **Proposed fix:** Count and `message()` NA/Inf rows in `ddd_base` before fitting; add a trip-wire `stopifnot()` on the exclusion share.

### Issue 13: No tidy/broom summary saved alongside raw `feols` objects
- **File:** `03_ddd_incentivo_2022.R:225-236`
- **Category:** RDS Data Pattern
- **Severity:** Medium
- **Rationale:** Saving only the raw `fixest` object forces any downstream Quarto chunk to load `fixest` and know its accessor API just to print one coefficient inline.
- **Proposed fix:** Also `saveRDS(broom::tidy(modelo, conf.int = TRUE), ...)` for each model.

### Issue 14: `mean(incumbente)` without explicit `na.rm`
- **File:** `03_ddd_incentivo_2022.R:188`
- **Category:** Numerical Discipline
- **Severity:** Low
- **Rationale:** `incumbente` is deterministically 0/1 by construction (never `NA` in practice), so currently harmless — but a silent landmine if the construction logic ever changes.
- **Proposed fix:** Add explicit `na.rm = TRUE`.

### Issue 15: Lines exceed 100 characters with no mathematical-formula exception
- **File:** `03_ddd_incentivo_2022.R:179-182`
- **Category:** Polish
- **Severity:** Low
- **Rationale:** `bind_rows()`/`mutate()` calls, not formulas, so the line-length exception doesn't apply. Also a stray double-space before `ANO_ELEICAO` on one line.
- **Proposed fix:** Wrap onto multiple lines; fix spacing.

### Issue 16: No numbered "0. Setup" section for `library()`/`out_dir`
- **File:** `03_ddd_incentivo_2022.R:27-30`
- **Category:** Structure & Header
- **Severity:** Low
- **Rationale:** Cosmetic — script is otherwise disciplined about numbered sections; setup is the one piece left unlabeled.
- **Proposed fix:** Add a `# 0. SETUP` banner.

### Issue 17: No explicit check for `feols` convergence/collinearity warnings
- **File:** `03_ddd_incentivo_2022.R:66-219`
- **Category:** Error Handling
- **Severity:** Low
- **Rationale:** Any collinearity warning (e.g., a rare cargo×ano×group cell perfectly absorbed by fixed effects) would print to console and be easy to miss among other output noise — exactly the condition the script's own "Suporte por célula" checks suggest is plausible (sparse cells).
- **Proposed fix:** Check `modelo$collin.var` after each fit and `warning()` if non-empty.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | No | 2 |
| Console Output | No | 1 |
| Reproducibility | No | 2 |
| Functions | No | 1 |
| Domain Correctness | No | 4 |
| Figures | N/A | 0 |
| RDS Pattern | No | 2 |
| Comments | No | 1 (overlaps with Issue 7) |
| Error Handling | No | 2 |
| Polish | No | 1 |
| Numerical Discipline | No | 1 |

**Overall assessment:** the strongest part of this script is its methodological self-awareness — the bad-control reasoning for incumbência (correctly lagged to the prior election) and the honest 2-period pre-trends caveat are the kind of rigor referees look for. The weakest part is that this rigor doesn't yet extend to the *inference* side (Issues 1, 2, 11) — for a chapter whose causal evidence is already characterized as "at most marginal," a wild-cluster-bootstrap check and a stated multiple-testing family are the two things most likely to change what can be claimed, not just how it's phrased. The console-output/RDS-persistence issues (4, 5, 13) are lower-stakes but would make Chapter 6's tables reproducible from disk rather than requiring an interactive re-run.
