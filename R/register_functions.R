# Reusable functions for extracting Kenya external debt registers --------

run_pdftotext <- function(pdf_path, text_path, first_page, last_page) {
    executable <- Sys.which("pdftotext")
    if (executable == "") stop("pdftotext was not found on PATH.")

    dir.create(dirname(text_path), recursive = TRUE, showWarnings = FALSE)
    status <- system2(executable, c(
        "-layout", "-f", first_page, "-l",
        last_page, pdf_path, text_path
    ))
    if (status != 0 || !file.exists(text_path)) {
        stop("PDF text extraction failed.")
    }
    invisible(text_path)
}

collapse_field <- function(lines, start, end) {
    values <- trimws(substr(lines, start, end))
    values <- values[values != ""]
    paste(values, collapse = " ")
}

parse_amount <- function(value) {
    value <- trimws(value)
    value[value %in% c("", "-")] <- NA_character_
    negative <- grepl("^\\(.*\\)$|^-", value)
    value <- gsub("[(),[:space:]-]", "", value)
    amount <- suppressWarnings(as.numeric(value))
    amount[negative & !is.na(amount)] <- -amount[negative & !is.na(amount)]
    amount
}

split_loan_blocks <- function(lines) {
    starts <- grep("^[0-9]{7,13}[[:space:]]", lines)
    if (length(starts) == 0) {
        stop("No loan rows were found in the register text.")
    }
    ends <- c(starts[-1] - 1L, length(lines))
    Map(function(first, last) lines[first:last], starts, ends)
}

remove_page_furniture <- function(lines) {
    is_furniture <- grepl(
        paste0(
            "TNT|Loan ID|THE NATIONAL TREASURY|PUBLIC DEBT MANAGEMENT|",
            "EXTERNAL PUBLIC DEBT REGISTER|Page [0-9]+ of"
        ),
        lines
    )
    lines[!is_furniture]
}

parse_numeric_fields <- function(line) {
    date_positions <- gregexpr("[0-9]{2}/[0-9]{2}/[0-9]{4}", line)[[1]]
    if (length(date_positions) < 2 || date_positions[1] < 0) {
        return(list(
            values = rep(NA_character_, 10),
            agreement_start = NA_integer_
        ))
    }

    tokens <- strsplit(
        trimws(substr(line, date_positions[1], nchar(line))),
        "[[:space:]]+"
    )[[1]]
    if (length(tokens) < 10) {
        return(list(
            values = rep(NA_character_, 10),
            agreement_start = date_positions[1]
        ))
    }

    movements <- tokens[-(1:4)]
    if (length(movements) == 7 && movements[2] == "-" &&
        grepl("^[0-9,]+$", movements[3])) {
        movements <- c(movements[1], paste0("-", movements[3]), movements[4:7])
    }
    if (length(movements) != 6) {
        return(list(
            values = rep(NA_character_, 10),
            agreement_start = date_positions[1]
        ))
    }

    list(
        values = c(tokens[1:4], movements),
        agreement_start = date_positions[1]
    )
}

parse_2025_ksh_block <- function(lines, source_row) {
    lines <- remove_page_furniture(lines)
    numeric <- parse_numeric_fields(lines[1])
    values <- numeric$values

    # Page scaling can shift columns. Agreement date normally starts at 165;
    # use its observed position to shift the preceding descriptive boundaries.
    shift <- if (is.na(numeric$agreement_start)) 0L else numeric$agreement_start - 165L

    data.frame(
        loan_id = trimws(substr(lines[1], 1, 16)),
        loan_title = collapse_field(lines, 17, 70 + shift),
        creditor_name = collapse_field(lines, 71 + shift, 113 + shift),
        creditor_category = collapse_field(lines, 114 + shift, 128 + shift),
        borrower_category = collapse_field(lines, 129 + shift, 142 + shift),
        borrower_name = collapse_field(lines, 143 + shift, 164 + shift),
        agreement_date = values[1],
        maturity_date = values[2],
        loan_amount_fx = parse_amount(values[3]),
        currency = values[4],
        outstanding_june_2024_ksh = parse_amount(values[5]),
        prior_period_adjustment_ksh = parse_amount(values[6]),
        principal_repaid_ksh = parse_amount(values[7]),
        drawdowns_ksh = parse_amount(values[8]),
        drawdown_reversals_ksh = parse_amount(values[9]),
        outstanding_june_2025_ksh = parse_amount(values[10]),
        source_row = source_row,
        stringsAsFactors = FALSE
    )
}

extract_2025_ksh_register <- function(text_path, source_url) {
    lines <- readLines(text_path, warn = FALSE, encoding = "UTF-8")
    blocks <- split_loan_blocks(lines)
    loans <- do.call(rbind, Map(parse_2025_ksh_block, blocks,
                                seq_along(blocks)))

    loans$agreement_date <- as.Date(loans$agreement_date, "%d/%m/%Y")
    loans$maturity_date <- as.Date(loans$maturity_date, "%d/%m/%Y")
    loans$report_year <- 2025L
    loans$as_of_date <- as.Date("2025-06-30")
    loans$source_url <- source_url
    loans$source_section <- "KSHS"
    loans$source_pages <- "3-29"
    loans
}

validate_2025_ksh_extract <- function(loans, official_closing_total_ksh,
                                      reconciliation_tolerance_ksh = 100) {
    required_character <- c(
        "loan_id", "loan_title", "creditor_name",
        "creditor_category", "borrower_name", "currency"
    )
    missing_character <- rowSums(sapply(
        loans[required_character], function(x) is.na(x) | trimws(x) == ""
    ))

    extracted_total <- sum(loans$outstanding_june_2025_ksh, na.rm = TRUE)
    list(
        report_year = 2025L,
        source_section = "KSHS pages 3-29",
        extracted_records = nrow(loans),
        distinct_loan_ids = length(unique(loans$loan_id)),
        duplicate_loan_currency_keys = sum(duplicated(loans[c("loan_id", "currency")])),
        records_missing_required_fields = sum(missing_character > 0 |
            is.na(loans$agreement_date) | is.na(loans$maturity_date)),
        invalid_currency_codes = sum(is.na(loans$currency) |
            !grepl("^[A-Z]{3}$", loans$currency)),
        invalid_agreement_dates = sum(is.na(loans$agreement_date)),
        invalid_maturity_dates = sum(is.na(loans$maturity_date)),
        unexpected_creditor_categories = sum(!loans$creditor_category %in% c(
            "Multilateral", "Bilateral", "Commercial Bank", "Buyers Credit",
            "Suppliers Credits", "Export Credit", "Financial Institution"
        )),
        unexpected_borrower_categories = sum(!loans$borrower_category %in% c(
            "Central Government", "Public Corporation"
        )),
        extracted_closing_total_ksh = extracted_total,
        official_closing_total_ksh = official_closing_total_ksh,
        closing_total_difference_ksh = extracted_total - official_closing_total_ksh,
        reconciliation_tolerance_ksh = reconciliation_tolerance_ksh,
        closing_total_reconciles = abs(extracted_total - official_closing_total_ksh) <=
            reconciliation_tolerance_ksh
    )
}

write_validation_report <- function(validation, path) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    writeLines(c("metric,value", paste(names(validation), unlist(validation), sep = ",")),
        path,
        useBytes = TRUE
    )
}

run_pdftotext_tsv <- function(pdf_path, tsv_path, first_page, last_page) {
    executable <- Sys.which("pdftotext")
    if (executable == "") stop("pdftotext was not found on PATH.")
    dir.create(dirname(tsv_path), recursive = TRUE, showWarnings = FALSE)
    status <- system2(executable, c(
        "-tsv", "-f", first_page, "-l", last_page,
        pdf_path, tsv_path
    ))
    if (status != 0 || !file.exists(tsv_path)) stop("PDF TSV extraction failed.")
    invisible(tsv_path)
}

words_in_band <- function(words, left, right) {
    selected <- words[words$left >= left & words$left < right & !is.na(words$text), ]
    if (nrow(selected) == 0) {
        return("")
    }
    selected <- selected[order(selected$top, selected$left), ]
    paste(selected$text, collapse = " ")
}

parse_2025_ksh_coordinates <- function(tsv_path, source_url) {
    words <- read.delim(tsv_path,
        quote = "", fill = TRUE,
        stringsAsFactors = FALSE, encoding = "UTF-8"
    )
    words <- words[words$level == 5 & !is.na(words$text), ]
    pages <- split(words, words$page_num)
    records <- list()

    for (page in pages) {
        body <- page[page$top >= 60 & page$top < 570, ]
        anchors <- body[body$left < 48 & grepl("^[0-9]{7,13}$", body$text), ]
        anchors <- anchors[order(anchors$top), ]
        if (nrow(anchors) == 0) next

        total_rows <- body$top[body$text == "TOTALS"]
        page_end <- if (length(total_rows)) min(total_rows) else 570
        midpoints <- (anchors$top[-nrow(anchors)] + anchors$top[-1]) / 2
        row_starts <- c(60, midpoints)
        row_ends <- c(midpoints, page_end)
        for (i in seq_len(nrow(anchors))) {
            row_words <- body[body$top >= row_starts[i] & body$top < row_ends[i], ]
            records[[length(records) + 1L]] <- data.frame(
                loan_id = anchors$text[i],
                loan_title = words_in_band(row_words, 48, 183),
                creditor_name = words_in_band(row_words, 183, 275),
                creditor_category = words_in_band(row_words, 275, 310),
                borrower_category = words_in_band(row_words, 310, 346),
                borrower_name = words_in_band(row_words, 346, 397),
                agreement_date = words_in_band(row_words, 397, 437),
                maturity_date = words_in_band(row_words, 437, 480),
                loan_amount_fx = parse_amount(words_in_band(row_words, 480, 517)),
                currency = words_in_band(row_words, 517, 555),
                outstanding_june_2024_ksh = parse_amount(words_in_band(row_words, 555, 608)),
                prior_period_adjustment_ksh = parse_amount(words_in_band(row_words, 608, 650)),
                principal_repaid_ksh = parse_amount(words_in_band(row_words, 650, 702)),
                drawdowns_ksh = parse_amount(words_in_band(row_words, 702, 742)),
                drawdown_reversals_ksh = parse_amount(words_in_band(row_words, 742, 772)),
                outstanding_june_2025_ksh = parse_amount(words_in_band(row_words, 772, Inf)),
                source_page = anchors$page_num[i],
                source_row_on_page = i,
                stringsAsFactors = FALSE
            )
        }
    }

    loans <- do.call(rbind, records)
    loans$agreement_date <- as.Date(loans$agreement_date, "%d/%m/%Y")
    loans$maturity_date <- as.Date(loans$maturity_date, "%d/%m/%Y")
    loans$report_year <- 2025L
    loans$as_of_date <- as.Date("2025-06-30")
    loans$source_url <- source_url
    loans$source_section <- "KSHS"
    loans
}