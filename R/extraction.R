
## This didn't work wit this pdf


install.packages("tabulapdf", repos = c("https://ropensci.r-universe.dev", "https://cloud.r-project.org"))

library(tabulapdf)

file_path <- "data/Public-Debt-Stock-External-Debt-Register-FY-2022-23.pdf"
pages <- 7:33  # Define the pages you are interested in


file_path <- "data/Public-Debt-Stock-External-Debt-Register-FY-2022-23.pdf"
pages <- 8:33  # Define the pages you are interested in

# Attempt to extract tables
tables <- lapply(pages, function(page) {
    tryCatch({
        extract_tables(file_path, pages = page)
    }, error = function(e) {
        cat("Error on page", page, ":", e$message, "\n")
        NULL  # Return NULL on error
    })
})

df = tables[[1]][[1]]
library(tidyverse)
str_split(df, "\\t") %>% unlist %>%
    janitor::make_clean_names() %>% dput
library(data.table)
DF2=df[[1]] |> setDT()

unique_creditors = public_debt_df %>% 
    select(creditor_name) %>% 
    distinct() %>% 
    pull() %>%
    paste0(collapse = "|")
public_debt_df %>%
    mutate(creditor_name = ifelse(creditor_name=="", str_extract_all(loan_title, unique_creditors), creditor_name)) 



text <- "1972005_1 Second Small Holder Agricultural Project International Development Association Multilateral Central Government Government of Kenya 29/11/1972 01/08/2022 6 ,000,000.00 6,000,000.00 USD 90,000.00 9 0,000.00 - - - -
1974002_1 Population Project International Development Association Multilateral Central Government Government of Kenya 01/04/1974 01/02/2024 1 2,000,000.00 12,000,000.00 USD 720,000.00 360,000.00 - - - 360,000.00
1974003_1 Second Livestock Development Project International Development Association Multilateral Central Government Government of Kenya 05/06/1974 01/02/2024 2 1,500,000.00 12,480,800.00 USD 747,389.00 373,666.00 - - - 373,723.00
1975002_1 Group Farm Rehabilitation Project International Development Association Multilateral Central Government Government of Kenya 26/03/1975 01/02/2025 7 ,500,000.00 5,172,235.00 USD 465,533.00 155,166.00 - - - 310,367.00
1975005_1 Site And Services Project - Dandora International Development Association Multilateral Central Government Government of Kenya 06/05/1975 15/04/2025 8 ,000,000.00 8,000,000.00 USD 720,000.00 240,000.00 - - - 480,000.00
1975018_1 Second Forestry Plantation Project. International Development Association Multilateral Central Government Government of Kenya 27/06/1975 01/04/2025 1 0,000,000.00 10,000,000.00 USD 900,000.00 300,000.00 - - - 600,000.00
1976006_1 Intergrated Agriculture Development Project International Development Association Multilateral Central Government Government of Kenya 09/07/1976 15/07/2025 1 0,000,000.00 6,666,074.09 USD 796,074.09 200,000.00 - - - 596,074.09
1976007_1 Rural Access Roads Project International Development Association Multilateral Central Government Government of Kenya 09/07/1976 15/03/2026 4 ,000,000.00 4,000,000.00 USD 480,000.00 120,000.00 - - - 360,000.00
1977006_1 Third Agricultural Credit Project International Development Association Multilateral Central Government Government of Kenya 15/04/1977 15/03/2027 2 0,000,000.00 18,651,620.67 USD 2,797,620.67 559,600.00 - - - 2,238,020.67
1977010_1 Bura Irrigation Settlement Project International Development Association Multilateral Central Government Government of Kenya 22/06/1977 15/05/2027 6 ,000,000.00 6,000,000.00 USD 900,000.00 180,000.00 - - - 720,000.00
1977019_1 Small Scale Industry Project International Development Association Multilateral Central Government Government of Kenya 28/11/1977 01/10/2027 1 0,000,000.00 5,066,968.49 USD 836,092.49 152,008.00 - - - 684,084.49
1978019_1 Fourth Education Project International Development Association Multilateral Central Government Government of Kenya 07/06/1978 15/03/2028 1 9,173,514.12 19,173,514.12 USD 3,451,278.12 575,204.00 - - - 2,876,074.12
1978022_1 IDA Second Urban Project International Development Association Multilateral Central Government Government of Kenya 05/05/1978 15/03/2028 2 5,000,000.00 25,000,000.00 USD 4,500,000.00 750,000.00 - - - 3,750,000.00
1978031_1 Narok Agricultural Development Project International Development Association Multilateral Central Government Government of Kenya 20/12/1978 15/11/2028 1 3,000,000.00 3,199,712.71 USD 623,987.71 9 5,990.00 - - - 527,997.71
Second Integrated Agricultural Development
1979005_1 Project International Fund For Agricultural Dev. Multilateral Central Government Government of Kenya 21/12/1979 15/08/2029 2 ,700,000.00 1,998,862.00 XDR 371,418.63 4 9,522.00 - - - 321,896.63
1979007_1 Small Holder Coffee Improvement Project International Development Association Multilateral Central Government Government of Kenya 11/06/1979 15/05/2029 2 7,000,000.00 10,497,101.90 USD 2,204,491.90 314,910.00 - - - 1,889,581.90
Nyeri Sewerage and Nanyuki Water Supply
1979010_1 Sewage African Development Fund Multilateral Central Government Government of Kenya 19/09/1979 01/07/2029 7 ,498,425.13 7,498,425.13 USD 1,675,297.77 223,372.26 - - - 1,451,925.51
Nyeri Sewerage and Nanyuki Water Supply and
1979011_1 Sewage African Development Fund Multilateral Central Government Government of Kenya 19/09/1979 01/07/2029 4 01,171.95 401,171.95 GBP 90,263.69 1 2,035.16 - - - 78,228.54
1980006_1 Baringo Pilot Semi Arid Area Project International Development Association Multilateral Central Government Government of Kenya 12/03/1980 15/07/2029 6 ,500,000.00 4,000,000.00 USD 900,045.25 119,998.00 - - - 780,047.25
1980008_1 Structural Adjustment Credit International Development Association Multilateral Central Government Government of Kenya 10/04/1980 01/10/2029 5 5,000,000.00 55,000,000.00 USD 12,375,000.00 1,650,000.00 - - - 1 0,725,000.00
1980010_1 Export Promotion Technical Project International Development Association Multilateral Central Government Government of Kenya 14/07/1980 15/01/2030 4 ,500,000.00 759,679.00 USD 182,339.00 2 2,790.00 - - - 159,549.00
1980011_1 IDA - Fisheries Project. International Development Association Multilateral Central Government Government of Kenya 14/07/1980 15/02/2030 1 0,000,000.00 227,199.38 USD 54,591.61 6 ,814.00 - - - 47,777.61
Second Intergrated Agricultural Development
1980022_1 Project International Development Association Multilateral Central Government Government of Kenya 23/04/1980 15/08/2029 4 6,000,000.00 5,333,594.72 USD 1,200,119.72 160,006.00 - - - 1,040,113.72
1980026_1 Special Action Credit International Development Association Multilateral Central Government Government of Kenya 10/04/1980 01/11/2029 2 ,134,000.00 2,134,000.00 DKK 544,170.00 7 3,623.00 - - - 470,547.00
1980031_1 Special Action Credit International Development Association Multilateral Central Government Government of Kenya 10/04/1980 01/11/2029 1 ,011,180.00 6,894,321.06 EUR 1,918,746.07 259,596.24 - - - 1,659,149.83
1980033_1 Special Action Credit International Development Association Multilateral Central Government Government of Kenya 10/04/1980 01/11/2029 2 ,101,400.00 2,101,400.00 GBP 535,857.00 7 2,498.30 - - - 463,358.70
1981002_1 Fourth Agricultural Project International Development Association Multilateral Central Government Government of Kenya 10/12/1981 01/02/2031 8 ,200,000.00 8,200,000.00 XDR 2,214,000.00 246,000.00 - - - 1,968,000.00
1981004_1 Fifth Education Project International Development Association Multilateral Central Government Government of Kenya 07/05/1981 01/08/2031 3 1,400,000.00 30,398,030.30 XDR 8,204,772.30 911,636.00 - - - 7,293,136.30
1981034_1 Ndia Water Supply Project African Development Fund Multilateral Central Government Government of Kenya 30/12/1981 01/07/2031 6 ,316,818.13 6,316,818.13 USD 1,800,293.19 189,504.54 - - - 1,610,788.65
1982002_1 Third Forestry Project International Development Association Multilateral Central Government Government of Kenya 27/08/1982 01/03/2032 1 3,600,000.00 13,600,000.00 XDR 4,080,000.00 408,000.00 - - - 3,672,000.00
1982010_1 Second Structural Adjstment Credit International Development Association Multilateral Central Government Government of Kenya 21/07/1982 01/04/2032 6 2,900,000.00 62,900,000.00 XDR 18,870,000.00 1,887,000.00 - - - 1 6,983,000.00
1982029_1 Agricultural Technical Assistance Project International Development Association Multilateral Central Government Government of Kenya 21/07/1982 01/03/2032 5 ,400,000.00 5,400,000.00 XDR 1,620,000.00 162,000.00 - - - 1,458,000.00
1982035_1 Integrated Rural Health Family Planning Project International Development Association Multilateral Central Government Government of Kenya 27/08/1982 01/04/2032 2 0,500,000.00 19,751,821.68 XDR 5,923,323.69 592,326.00 - - - 5,330,997.69
1983002_1 Cotton Processing and Marketing Project. International Development Association Multilateral Central Government Government of Kenya 01/03/1983 15/08/2032 1 8,700,000.00 17,034,704.85 XDR 5,110,504.85 511,038.00 - - - 4,599,466.85
1983007_1 National Extension Project International Development Association Multilateral Central Government Government of Kenya 22/09/1983 01/09/2033 1 3,900,000.00 12,183,773.65 XDR 4,020,685.65 365,512.00 - - - 3,655,173.65
1983008_1 Secondry Town Project. International Development Association Multilateral Central Government Government of Kenya 22/09/1983 15/03/2033 1 2,699,167.50 12,699,167.50 XDR 4,190,761.50 380,974.00 - - - 3,809,787.50
1983011_1 National Extension Project. International Fund For Agricultural Dev. Multilateral Central Government Government of Kenya 09/11/1983 01/03/2033 5 ,600,000.00 4,630,192.03 XDR 1,331,203.03 115,754.00 - - - 1,215,449.03
1983015_1 Sergoit Tambach Road Project European Economic Community Multilateral Central Government Government of Kenya 28/03/1983 15/02/2023 8 ,994,816.25 8,994,816.25 EUR 345,400.88 345,400.88 - - - -
1983016_1 Rural Private Enterprises Project Phase I Government of United States of America Bilateral Central Government Government of Kenya 25/08/1983 17/08/2027 1 1,600,000.00 10,438,369.54 USD 2,936,516.88 498,773.55 - - - 2,437,743.34
1983017_1 Rural Private Enterprises Project Phase II Government of United States of America Bilateral Central Government Government of Kenya 29/12/1983 14/12/2027 1 2,400,000.00 11,478,266.81 USD 2,357,872.93 400,489.65 - - - 1,957,383.26"

library(stringr)
library(dplyr)

library(stringr)
library(dplyr)

parse_projects <- function(text_data) {
    # Split the text into lines based on the project ID pattern
    lines <- str_split(text_data, "(?<=\\d)\\n(?=\\d{7}_\\d+)")[[1]]
    
    # Initialize a list to store each line's data frame
    df_list <- list()
    
    # Process each line
    for (line in lines) {
        # Remove spaces before commas in numeric values
        line <- gsub(" (?=\\,)", "", line, perl=TRUE)
        
        # Split the line into columns; adjust the split regex as needed based on your actual data structure
        columns <- str_split(line, "\\s+", simplify = TRUE)[1,]
        
        # Create a DataFrame for the line
        df_list[[length(df_list) + 1]] <- as.data.frame(t(columns), stringsAsFactors = FALSE)
    }
    
    # Combine all data frames into one, reversing the order
    final_df <- do.call(rbind, rev(df_list))
    
    # Set column names, assuming we know the structure
    col_names <- c("loan_ref_number", "loan_title", "creditor_name", "creditor_category", 
                   "borrower_category", "borrower_name", "agreement_date", "maturity_date", 
                   "org_financed_amount", "revised_financed_amount", "curr", 
                   "amount_outstanding_as_at_30_06_2022_fx", "principal_repaid_in_2022_23_fy_fx", 
                   "draw_downs_during_2023_24fy_fx", "principal_refinanced_in_2022_23fy_fx", 
                   "restructured_debt_in_2022_23fy_fx", "amount_outstanding_as_at_30_06_2023_fx")
    colnames(final_df) <- col_names
    
    return(final_df)
}


result_df <- parse_projects(text_data = text)
print(result_df)
