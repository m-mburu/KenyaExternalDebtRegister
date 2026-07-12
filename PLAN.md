# Kenya External Debt Register refresh plan

Last updated: 2026-07-12

## Objective

Refresh the project from the June 2023 register to the latest available National Treasury register (June 2025), while preserving annual snapshots and making extraction, validation, analysis, and publication reproducible.

## Principles

- Preserve annual source documents and snapshots; never overwrite prior years.
- Keep commitments, drawdowns, repayments, and outstanding stock distinct.
- Use Treasury-reported KSh closing balances for debt-stock analysis.
- Use non-overlapping date intervals for derived presidential attribution.
- Count distinct loan IDs as loans; describe currency/tranche rows as records.
- Fail loudly when a PDF layout changes or totals do not reconcile.

## Phase 1 -- pipeline foundation (in progress)

- [x] Add ignore rules for environments, downloaded PDFs, intermediates, diagnostics, and rebuildable outputs.
- [x] Add a versioned source catalogue with URLs and expected metadata.
- [x] Add a year-driven extractor rather than hard-coded pages and columns.
- [x] Add initial layout and extraction validation.
- [x] Download and checksum the June 2025 PDF into `data/raw/`.
- [ ] Obtain a valid June 2024 PDF; the Treasury old-site source is currently unavailable.
- [x] Extract KSh register pages 3-29 for 2025 and reconcile to the Treasury total.
- [ ] Tune and verify extraction against the 2024 layout after obtaining its PDF.

Deliverable: a normalized CSV and validation report per reporting year.

## Phase 2 -- annual panel and data quality

- [ ] Normalize loan IDs, creditors, categories, currencies, dates, and amounts.
- [ ] Retain source URL, retrieval date, report year, page, table, and row.
- [ ] Deduplicate without collapsing valid currency components or tranches.
- [ ] Build `loan_panel.csv` by matching stable IDs across annual reports.
- [ ] Check duplicate keys, dates, currencies, missing fields, and report totals.
- [ ] Investigate unmatched and materially changed records explicitly.

## Phase 3 -- analytical corrections

- [ ] Use distinct-loan counts and disclose loan-currency record counts.
- [ ] Replace overlapping presidential terms with half-open date intervals.
- [ ] Rename "amount borrowed" to "commitments signed" where appropriate.
- [ ] Replace the indexed cumulative chart with calendar/fiscal-year measures.
- [ ] Use official KSh balances for stock; label historical USD commitments.
- [ ] Add maturity, concentration, currency, stock-flow, and change analysis.

## Phase 4 -- reproducible publication

- [ ] Lock R and Python dependencies and add automated tests.
- [ ] Add a single documented build command.
- [ ] Rewrite `README.Rmd` with methodology, indicators, findings, limitations, a data dictionary, source links, and an "as of" date.
- [ ] Render and verify `README.md` in a clean environment.
- [ ] Optionally add CI for validation and rendering.

## Phase 5 -- GitHub Pages data story

- [ ] Create a self-contained visualization site in the blog repository at `kenyaExternalRegister/`, following the deployment pattern used by `ineqTrees/`.
- [ ] Publish `kenyaExternalRegister/index.html` at `https://m-mburu.github.io/kenyaExternalRegister/`.
- [ ] Export publication-ready chart data from this repository so the blog does not duplicate extraction or cleaning logic.
- [ ] Build responsive, accessible graphs with clear titles, units, reporting dates, source notes, tooltips, and mobile layouts.
- [ ] Include headline indicators and charts for debt stock and annual change, creditor composition, currency exposure, commitments, drawdowns, repayments, maturity profile, and presidential-period comparisons with appropriate caveats.
- [ ] Add methodology, limitations, the National Treasury source link, and links to the analysis repository and downloadable data.
- [ ] Add a card or post on the main blog linking to the visualization page.
- [ ] Test all asset paths under `/kenyaExternalRegister/`, including a clean GitHub Pages build.

Deliverable: an interactive, reproducible data story integrated into `m-mburu.github.io` and served from `/kenyaExternalRegister/`.

## Definition of done

- The 2023-2025 datasets rebuild from documented official sources.
- Every output row has report-year and source provenance.
- Report totals reconcile or discrepancies are documented.
- Loan counts use distinct IDs and presidential periods do not overlap.
- Stock, commitments, drawdowns, and repayments are never conflated.
- The README states the reporting date, methodology, and limitations.
- The graphs are published at `https://m-mburu.github.io/kenyaExternalRegister/`, work on desktop and mobile, and link to reproducible source data.

## Immediate next actions

1. Run `python Python/extract_register.py --year 2025 --download`.
2. Review its validation report and extracted raw-cell records.
3. Tune the 2025 layout adapter, then repeat for 2024.
4. Build the annual panel only after both extracts validate.
