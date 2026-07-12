# Extract and validate the June 2025 KSh external debt register ----------------

library(data.table)
source("R/register_functions.R")

# 1. Declare the official source and local pipeline paths.
source_url <- paste0(
    "https://www.treasury.go.ke/sites/default/files/debt/",
    "External%20Public%20Debt%20Register%20as%20at%20End%20June%202025.pdf"
)
pdf_path <- "data/raw/register_2025.pdf"
tsv_path <- "data/interim/register_2025_ksh_pages_3_29.tsv"
output_path <- "data/processed/register_2025_ksh_loans.csv"
validation_path <- "data/validation/register_2025_ksh_extract.csv"

# The official closing total printed on page 29 of the KSh register.
official_closing_total_ksh <- 5488464583529

if (!file.exists(pdf_path)) stop("The official 2025 PDF is missing: ", pdf_path)

# 2. Extract only pages carrying the loan-level register heading ending (KSHS).
#    Pages 1-2 are summaries; pages 30-61 are the separate FX register.
run_pdftotext_tsv(pdf_path, tsv_path, first_page = 3, last_page = 29)

# 3. Parse words by their PDF column coordinates and attach page provenance.
loans_2025 <- parse_2025_ksh_coordinates(tsv_path, source_url)

# 4. Validate structure and reconcile the closing balance to Treasury's total.
validation <- validate_2025_ksh_extract(loans_2025, official_closing_total_ksh)

# 5. Preserve both the candidate dataset and its validation evidence.
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
fwrite(loans_2025, output_path, na = "")
write_validation_report(validation, validation_path)
print(validation)

blocking_failures <- validation$records_missing_required_fields +
    validation$invalid_currency_codes +
    validation$invalid_agreement_dates +
    validation$invalid_maturity_dates +
    validation$unexpected_creditor_categories +
    validation$unexpected_borrower_categories +
    as.integer(!validation$closing_total_reconciles)

if (blocking_failures > 0) {
    stop("The 2025 KSh extract has ", blocking_failures,
         " blocking validation failures; it was not promoted to the panel.")
}
