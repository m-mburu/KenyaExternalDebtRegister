
library(tidyverse)
library(data.table)

public_debt <- fread("data/raw/public_debt.csv")

creditor_name_unique <- c(public_debt[!creditor_name %in% c("",  "DEV." , "Due 2024") , unique(creditor_name)], "KUWAIT FUND FOR ARAB ECONOMIC") %>%
    paste0(collapse = "|")
# the negtaive of this pattern



public_debt[, creditor_name := ifelse(
    grepl(creditor_name_unique, loan_title) & !grepl(creditor_name_unique, creditor_name),
    str_extract(loan_title, creditor_name_unique),
    creditor_name
)]
loan_title2 <- public_debt$loan_title

# extract kuwait fund for arab economic development
x = ifelse(grepl("KUWAIT FUND FOR ARAB ECONOMIC", loan_title2) , 
       str_extract(loan_title2, "KUWAIT FUND FOR ARAB ECONOMIC"), NA) 
x[!is.na(x)]
#grepl("KUWAIT FUND FOR ARAB ECONOMIC", loan_title2)]

# get columns ending with _date
date_cols <- grep("_date$", names(public_debt), value = TRUE)

public_debt[, (date_cols) := lapply(.SD, as.Date, format = "%d/%m/%Y"), .SDcols = date_cols]

public_debt[grepl("Citigroup Global Markets Deutschland AG ", creditor_category), creditor_name := "Citigroup Global Markets Deutschland AG"]
public_debt[grepl("Citigroup Global Markets Deutschland AG ", creditor_category), creditor_category := gsub("Citigroup Global Markets Deutschland AG ", "", creditor_category)]


nms_char <- public_debt[, .SD, .SDcols = is.character] |> names()
# str_trim
public_debt[, (nms_char) := lapply(.SD, str_trim), .SDcols = nms_char]


kenya_presidents <- data.frame(
    president = c("William Ruto", "Uhuru Kenyatta", "Mwai Kibaki", "Daniel arap Moi", "Jomo Kenyatta"),
    start_date = as.Date(c("2022-09-13","2013-04-09", "2002-12-30", "1978-08-22", "1963-12-12")),
    end_date = as.Date(c(Sys.Date(), "2022-09-13", "2013-04-09", "2002-12-30", "1978-08-22"))
)
# 2013-04-09 - 2002-12-30

# create a new column to store the president in power at the time of the loan
public_debt[, president := NA_character_]

## use between to check if the agreement date is between the start and end date of the president

for (i in seq_len(nrow(kenya_presidents))) {
    public_debt[between(agreement_date,kenya_presidents$start_date[i], kenya_presidents$end_date[i] ), president := kenya_presidents$president[i]]
}


public_debt[, duration_payment_yrs:= as.numeric(difftime(maturity_date, agreement_date, units = "days")/365.25)]

setorder(public_debt, agreement_date)



money_cols <- c("org_financed_amount", "revised_financed_amount", "amount_outstanding_as_at_30_06_2022_fx", 
                "principal_repaid_in_2022_23_fy_fx", "draw_downs_during_2023_24fy_fx", 
                "principal_refinanced_in_2022_23fy_fx", "restructured_debt_in_2022_23fy_fx", 
                "amount_outstanding_as_at_30_06_2023_fx")

options(scipen = 999)
rm_spaces_commas <- function(x) { 
    x = gsub("\\s{1,}|,", "", x)
    as.numeric(x)
}


public_debt[, (money_cols) := lapply(.SD, rm_spaces_commas), .SDcols = money_cols]


### SDR is a special drawing rights
#install.packages("readODS")
xdr_curr_df <- readODS::read_ods ("data/raw/SDRV.ods", skip = 2) |>
    janitor::clean_names() |>
    setDT()
#02-Jan-1981
xdr_curr_df[, report_date := zoo::na.locf(report_date, na.rm = F)]
xdr_curr_df[, agreement_date := as.Date(report_date, format = "%d-%b-%Y")]
# u_s_dollar_equivalent
xdr_curr_df <- xdr_curr_df[exchange_rate == "U.S.$1.00 = SDR"]
xdr_curr_df[, currency := "XDR"]

xdr_curr_df <- xdr_curr_df[, .(agreement_date, currency,Exchange_Rate = as.numeric(u_s_dollar_equivalent))]
historical_exchange_rates <- fread("data/raw/historical_exchange_rates.csv")

historical_exchange_rates[, agreement_date := as.Date(paste0(Day_Number,"-", Month_Year), format = "%d-%b - %Y")]
historical_exchange_rates[, currency := str_trim(gsub("USD to ", "", Currency_Pair))]

historical_exchange_rates <- rbind(historical_exchange_rates, xdr_curr_df, fill = T)
curr = c("JPK",  "CHF", "SEK", "INR", "GBP", "CAD", "DKK", "EUR", 
                        "XDR", "SAR", "CNY", "KRW", "AUA", "KWD", "AED")

currency = c("JPY",  "CHF", "SEK", "INR", "GBP", "CAD", "DKK", "EUR", 
                        "XDR", "SAR", "CNY", "KRW", "AUD", "KWD", "AED")
curr_dt = data.table(curr = curr, currency = currency)

historical_exchange_rates_curr <- merge(historical_exchange_rates, curr_dt, by = "currency", all.x =T)
## zoo::na.locf to fill in the missing exchange rates by currency,year, month, week
#create year month week columns
historical_exchange_rates_curr[, year := year(agreement_date)]
historical_exchange_rates_curr[, month := month(agreement_date)]
historical_exchange_rates_curr[, week := week(agreement_date)]

historical_exchange_rates_curr[, Exchange_Rate := zoo::na.locf(Exchange_Rate, na.rm = F), by = c("currency", "year", "month", "week")]
historical_exchange_rates_curr[, Exchange_Rate := zoo::na.locf(Exchange_Rate, na.rm = F), by = c("currency", "year", "month")]
## fill the reminder with the mean of the group if missing
historical_exchange_rates_curr[, Exchange_Rate := ifelse(is.na(Exchange_Rate), mean(Exchange_Rate, na.rm = T), Exchange_Rate), by = c("currency", "year","month", "week")]
historical_exchange_rates_curr[, Exchange_Rate := ifelse(is.na(Exchange_Rate), mean(Exchange_Rate, na.rm = T), Exchange_Rate), by = c("currency", "year","month")]
inflation_data_usd <- fread("data/raw/inflation_data_usd.csv") %>%
    janitor::clean_names() 

## merge by year
historical_exchange_rates_curr <- merge(historical_exchange_rates_curr, inflation_data_usd, by = "year", all.x = T)

hist_prices <- historical_exchange_rates_curr[!is.na(Exchange_Rate), .(curr, agreement_date, Exchange_Rate, amount, inflation_rate)] |>
    distinct(curr, agreement_date, Exchange_Rate, .keep_all = T)


public_debt_curr <- merge(public_debt, hist_prices ,
                          by =c("agreement_date", "curr"), all.x = TRUE, sort = F)

public_debt_curr[curr == "USD", Exchange_Rate := 1]

public_debt_curr[, financed_amount := ifelse(is.na(revised_financed_amount), org_financed_amount, revised_financed_amount)]
public_debt_curr[, financed_amount_usd := financed_amount/Exchange_Rate]
## financed_amount IN 2024 USD
public_debt_curr[, financed_amount_2024_usd := financed_amount_usd * amount]
public_debt_curr_miss <- public_debt_curr[is.na(Exchange_Rate)]
public_debt_curr_miss[, day := format(agreement_date, "%A")]
fwrite(public_debt_curr, "data/kenya_public_debt.csv")





stop("check")

###########################



public_debt[, summary(duration_payment_yrs), by = president]

public_debt[, summary(duration_payment_yrs), by = creditor_category]

nms <- names(public_debt)[9:17]
amount = public_debt[, .(amount_outstanding = sum(revised_financed_amount, na.rm = TRUE)), 
            by = .(president, curr)]

p = ggplot(amount, aes(x = reorder(president, -amount_outstanding), y = amount_outstanding, fill = curr)) +
    geom_col() +
    coord_flip() +
    labs(title = "Amount outstanding by president", x = "President", y = "Amount outstanding") +
    theme_minimal()


plotly::ggplotly(p)


## presidents and currency

amount = public_debt[, .(amount_outstanding =.N), 
            by = .(president, curr)]


p = ggplot(amount, aes(x = reorder(president, -amount_outstanding), y = amount_outstanding, fill = curr)) +
    geom_col() +
    coord_flip() +
    scale_fill_brewer(palette = "Set3") +
    labs(title = "Number of loans by president", x = "President", y = "Number of loans") +
    theme_minimal()

plotly::ggplotly(p)
