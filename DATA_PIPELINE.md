# Data pipeline

## Current validated release

The June 2025 loan-level KSh register is the first validated annual extract.
Only PDF pages whose repeated heading is:

`EXTERNAL PUBLIC DEBT REGISTER AS AT END JUNE 2025 (KSHS)`

are included. In the official 61-page document, these are pages 3-29. Pages 1-2
are summary tables and pages 30-61 are the separate foreign-currency register.

## Run the 2025 extraction

From the project root:

```r
source("R/extract_register_2025.R")
```

or from a terminal:

```text
Rscript R/extract_register_2025.R
```

The driver script is deliberately linear and commented. Repeated PDF parsing,
amount conversion, coordinate selection, and validation operations live in
`R/register_functions.R`.

## Outputs

- `data/processed/register_2025_ksh_loans.csv`: candidate loan-level dataset.
- `data/validation/register_2025_ksh_extract.csv`: validation evidence.
- `data/interim/register_2025_ksh_pages_3_29.tsv`: coordinate-level PDF text.

These files are reproducible and ignored by Git. The official input PDF is also
ignored because its source URL is recorded in `config/registers.csv`.

## June 2025 validation result

- PDF pages: 61; KSh register pages: 3-29.
- Extracted records: 1,041.
- Distinct loan IDs: 1,041.
- Duplicate loan/currency keys: 0.
- Missing required fields: 0.
- Invalid currencies or dates: 0.
- Unexpected creditor or borrower categories: 0.
- Extracted June 2025 closing balance: KSh 5,488,464,583,540.
- Treasury printed closing balance: KSh 5,488,464,583,529.
- Difference: KSh 11, accepted within the documented KSh 100 line-item rounding tolerance.

The parser uses PDF word coordinates rather than simulated fixed-width text.
This prevents wrapped loan titles, creditor names, and two-line categories from
crossing into adjacent columns. Every record retains its PDF page and row number.

## June 2024 status

The Treasury register page points to its old-site host. At the time of this run,
the `www.oldsite` hostname did not resolve, the non-`www` endpoint had a broken
TLS chain and returned an HTML error when accessed with certificate checks
disabled, and the equivalent current-site path returned 404. No invalid response
was retained. The 2024 stage remains pending until a valid official PDF is
available or an authenticated archival copy is identified and checksummed.
