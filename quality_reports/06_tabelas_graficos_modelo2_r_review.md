# R Code Review: 06_tabelas_graficos_modelo2.R

**Date:** 2026-08-19
**Reviewer:** r-reviewer agent

## Summary
- **Total issues:** 14
- **Critical:** 2 (cross-artifact / provenance)
- **High:** 3
- **Medium:** 4
- **Low:** 5

The script is functionally clean (no float `==`, correct scale-parameter logic, consistent Okabe-Ito palette, consistent `|>` use). The two Critical findings are cross-artifact issues, not local bugs: Section 1-2 of the script produces outputs the manuscript no longer cites (superseded by the Modelo 3 pipeline), and the script still carries a stale hypothesis-numbering scheme (H6/H7) that was renumbered to H4/H5 in the manuscript — baked directly into exported CSV data values, not just comments.

## Issues

### Issue 1: Section 1-2 outputs are orphaned — superseded by the Modelo 3 pipeline but not marked as such
- **File:** `06_tabelas_graficos_modelo2.R:52-116`
- **Category:** Domain Correctness / Cross-Artifact
- **Severity:** Critical
- **Rationale:** Confirmed via grep that `06-sobreposicao-territorial-partido.qmd` never references `tabela_comparativa_modelo1_modelo2.{tex,csv}` or `grafico_comparativo_modelo1_modelo2.{pdf,png}`. The chapter's comparison table/figure comes from `10_tabelas_graficos_modelo3.R`'s three-model outputs instead. A reader opening this script reasonably assumes its outputs feed the chapter; they don't.
- **Proposed fix:** Mark Section 1-2 SUPERSEDED (following the project's own convention for `07_versao_b_universo_completo.R`), or delete the section entirely since script 10 recomputes the same rows as part of its 3-model table.

### Issue 2: Stale hypothesis numbering (H6/H7) baked into exported CSV data, contradicting the manuscript's H4/H5
- **File:** `06_tabelas_graficos_modelo2.R:126-127,138,142,154,156,161-162,164`
- **Category:** Domain Correctness / Cross-Artifact
- **Severity:** Critical
- **Rationale:** Grepped the chapter `.qmd` for H6/H7 — zero matches; the chapter consistently calls this hypothesis H5. `"Alcance total (H7)"` is a literal data value written to `tabela_h7_alcance_total.csv`, a persisted artifact — anyone regenerating the table from that CSV would introduce a hypothesis-number contradiction directly into the manuscript.
- **Proposed fix:** Replace H7→H5 (or drop hypothesis numbers from labels entirely, following `10_tabelas_graficos_modelo3.R`'s pattern); rename artifact filenames (`tabela_h7_*`→`tabela_alcance_*`) to match; fix the same stale numbering upstream in `05_modelo2_incumbente.R`.

### Issue 3: `print()` used for non-debugging status output
- **File:** `06_tabelas_graficos_modelo2.R:85,145`
- **Category:** Console Output
- **Severity:** High
- **Proposed fix:** Drop both `print()` calls — tables are already persisted via `save_kable`/`write_csv`.

### Issue 4: No `saveRDS()` for either computed table — breaks the project's RDS provenance pattern
- **File:** `06_tabelas_graficos_modelo2.R:61-82,125-144`
- **Category:** RDS Data Pattern
- **Severity:** High
- **Rationale:** `06-sobreposicao-territorial-partido.qmd` hand-types the comparison numbers as a literal markdown table rather than reading any RDS/CSV from this script — exactly the manual-transcription failure mode the RDS pattern exists to prevent.
- **Proposed fix:** `saveRDS()` both `tab_comparativa` and `tab_alcance`.

### Issue 5: `extrair_ddd()` has no guard against a missing/renamed interaction term — silent 0-row failure
- **File:** `06_tabelas_graficos_modelo2.R:37-50`
- **Category:** Error Handling
- **Severity:** High
- **Rationale:** `filter(term == termo)` on a hardcoded string breaks silently if an upstream script changes a variable name or `fixest` reorders interaction terms. A 0-row result flows straight through `bind_rows()` into the final table with no error — one fewer row than expected, likely only caught by a human counting rows.
- **Proposed fix:** Add `stopifnot(nrow(resultado) == 1L)` inside `extrair_ddd()` with an informative error naming the missing term.

### Issue 6: `sig_star()` and `extrair_ddd()` duplicated (and diverging) between `04_...R` and `06_...R`
- **File:** `06_tabelas_graficos_modelo2.R:33-50` vs. `04_tabelas_graficos_consolidacao.R:52-54,97-107`
- **Category:** Function Design
- **Severity:** Medium
- **Rationale:** `extrair_ddd()` exists in both files with different signatures; `04`'s version already lacks a comment on the `scale` parameter that `06`'s version has — drift has already happened.
- **Proposed fix:** Extract both functions into a shared sourced helper file, following the project's `harmonizar_partido.R` precedent.

### Issue 7: Column names `estimate_pp`/`conf.low_pp`/`conf.high_pp` are misleading when `scale = 1`
- **File:** `06_tabelas_graficos_modelo2.R:43-49,126-127`
- **Category:** Domain Correctness
- **Severity:** Medium
- **Rationale:** For `tab_alcance`, `estimate_pp` literally holds a coefficient in "number of municipalities," not percentage points.
- **Proposed fix:** Rename to unit-agnostic `estimate`/`conf.low`/`conf.high`.

### Issue 8: No `dir.create()` for `out_dir` in this script
- **File:** `06_tabelas_graficos_modelo2.R:16`
- **Category:** Reproducibility
- **Severity:** Medium
- **Proposed fix:** Add `dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)`.

### Issue 9: Inconsistent group ordering between the two companion coefficient plots
- **File:** `06_tabelas_graficos_modelo2.R:91-95` vs. `147`
- **Category:** Figures
- **Severity:** Medium
- **Rationale:** `g_comparativo` deliberately orders "Negra" before "Mulher"; `g_alcance` leaves `grupo` unfactored, so its y-axis order falls out of default sort — two companion figures should order groups identically.
- **Proposed fix:** Apply the same `factor(grupo, levels = c("Negra", "Mulher"))` releveling to `tab_alcance` before plotting.

### Issue 10: Header lacks explicit Title/Author/Purpose/Inputs/Outputs fields; no "0. Setup" section marker
- **File:** `06_tabelas_graficos_modelo2.R:1-50`
- **Category:** Structure & Header
- **Severity:** Low
- **Proposed fix:** Add the standard header fields (pipeline-wide gap, also present in 04/05).

### Issue 11: Unused palette variables `cor_masculino`, `cor_branca`
- **File:** `06_tabelas_graficos_modelo2.R:19,21`
- **Category:** Polish
- **Severity:** Low
- **Proposed fix:** Drop or add a comment noting only focal-group colors are used in this script.

### Issue 12: Lines exceeding 100 characters without a mathematical-formula exception
- **File:** `06_tabelas_graficos_modelo2.R:62-65,76,97,110,115-116,126-127,151,162`
- **Category:** Polish
- **Severity:** Low
- **Proposed fix:** Wrap long string literals/captions.

### Issue 13: "x" used as a multiplication glyph instead of "×", inconsistent with the manuscript
- **File:** `06_tabelas_graficos_modelo2.R:76,107,110,138,154`
- **Category:** Polish
- **Severity:** Low
- **Rationale:** The manuscript consistently typesets "Federal × 2022 × Grupo" with the Unicode multiplication sign; figures from this script use a literal "x."
- **Proposed fix:** Use `×` in axis labels/captions.

### Issue 14: `base_size = 12`, legend `"top"`, no `bg = "transparent"` — worth an explicit decision, not a silent default
- **File:** `06_tabelas_graficos_modelo2.R:23-31,115-116,161-162`
- **Category:** Figures
- **Severity:** Low (informational)
- **Rationale:** This is a book-context figure (not Beamer), so the deviation from `r-code-conventions.md`'s Beamer-oriented defaults is defensible — worth stating the rationale explicitly in a header comment so a reviewer applying the generic rule literally doesn't flag it as a hard violation.

## Checklist Summary
| Category | Pass | Issues |
|----------|------|--------|
| Structure & Header | No | 1 |
| Console Output | No | 1 |
| Reproducibility | No | 1 |
| Functions | No | 1 |
| Domain Correctness | No | 3 |
| Figures | No | 2 |
| RDS Pattern | No | 1 |
| Comments | Yes | 0 |
| Error Handling | No | 1 |
| Polish | No | 3 |
| Numerical Discipline | Yes | 0 |
