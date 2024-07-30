import pdfplumber
import fitz  # PyMuPDF
import pandas as pd

col_names = ["loan_ref_number", "loan_title", "creditor_name", "creditor_category", 
"borrower_category", "borrower_name", "agreement_date", "maturity_date", "org_financed_amount",
"revised_financed_amount", "curr", "amount_outstanding_as_at_30_06_2022_fx", "principal_repaid_in_2022_23_fy_fx",
"draw_downs_during_2023_24fy_fx", "principal_refinanced_in_2022_23fy_fx", "restructured_debt_in_2022_23fy_fx", 
"amount_outstanding_as_at_30_06_2023_fx"]


file_path = "data/Public-Debt-Stock-External-Debt-Register-FY-2022-23.pdf"

def extract_and_parse_pdf(file_path, column_names, pages_to_extract=None):
    dataframes = []

    with pdfplumber.open(file_path) as pdf:
        total_pages = len(pdf.pages)
        pages_to_extract = pages_to_extract if pages_to_extract else range(total_pages)
        
        for page_number in pages_to_extract:
            if page_number >= total_pages:
                continue  # Skip if the page number is out of range

            page = pdf.pages[page_number]
            table = page.extract_table()

            if table and len(table) > 1:
                df = pd.DataFrame(table[1:], columns=table[0])
                dataframes.append(df)
            else:
                doc = fitz.open(file_path)
                page = doc.load_page(page_number)
                text = page.get_text()
                doc.close()

                df = parse_text_to_df(text, column_names=column_names)
                if not df.empty:
                    dataframes.append(df)

    return dataframes

# import re
# import pandas as pd
# 
# 
# def parse_text_to_df(text, column_names):
#     # Use regex to split the text into rows based on the specific ID format
#     # Assumes IDs are like '1974002_1' and are at the start of each new line followed by content
#     rows = re.split(r'\n(?=\d{7}_\d)', text)
# 
#     # Clean and prepare data for DataFrame creation
#     data = []
#     for row in rows:
#         # Check if the row starts with the ID format and contains a space
#         if re.match(r'^\d{7}_\d', row) and ' ' in row:
#             # Split row into fields by newline to separate each column's data
#             fields = row.strip().split('\n')
#             # Filter out fields that are dashes or contain only non-alphanumeric characters and not spaces also
#             fields = [f for f in fields if (re.search(r'\w', f) or '-' in f) and not (re.search(r'Page \d{1,2}', f) or re.search(r'^\s+\s$', f))]
#             # Calculate the number of extra fields
#             extra_fields_count = len(fields) - len(column_names)
#             if extra_fields_count > 0:
#                 # Join the extra fields starting from index 1
#                 joined_field = ' '.join(fields[1:1 + extra_fields_count + 1])
#                 fields = [fields[0]] + [joined_field] + fields[1 + extra_fields_count + 1:]
#             # Ensure the data list has the same length as headers, truncate or fill if necessary
#             if len(fields) > len(column_names):
#                 fields = fields[:len(column_names)]  # Truncate extra fields
#             elif len(fields) < len(column_names):
#                 fields.extend([''] * (len(column_names) - len(fields)))  # Fill missing fields with empty strings
#             data.append(fields)
# 
#     # Create DataFrame from the processed data
#     df = pd.DataFrame(data, columns=column_names)
#     return df



import re
import pandas as pd

def parse_text_to_df(text, column_names):
    # Use regex to split the text into rows based on the specific ID format
    # Assumes IDs are like '1974002_1' and are at the start of each new line followed by content
    rows = re.split(r'\n(?=\d{7}_\d)', text)

    # Clean and prepare data for DataFrame creation
    data = []
    for row in rows:
        # Check if the row starts with the ID format and contains a space
        if re.match(r'^\d{7}_\d', row): #and ' ' in row
            # Split row into fields by newline to separate each column's data
            fields = row.strip().split('\n')
            # Filter for fields that are dashes or contain only alphanumeric characters and not spaces also
            fields = [f for f in fields if (re.search(r'\w', f) or '-' in f) and not (re.search(r'Page \d{1,2}', f) or re.search(r'^\s+\s$', f))]

            # The project name has multiple rows
            if len(fields) > len(column_names):
                joined_field = ' '.join(fields[1:len(fields)-len(column_names)+2])
                fields = [fields[0]] + [joined_field] + fields[len(fields)-len(column_names)+2:]

            # Project name/loan title is sometimes in the same line with bank name
            if len(fields) < len(column_names):
                # Insert empty string at index 2
                fields.insert(2, '')
                # Fill the rest of the missing fields
                while len(fields) < len(column_names):
                    fields.append('')

            data.append(fields)

    # Create DataFrame from the processed data
    df = pd.DataFrame(data, columns=column_names)
    return df


column_names = col_names

public_debt_dfs = extract_and_parse_pdf(file_path, pages_to_extract=range(8, 33), column_names=column_names)

public_debt_df = pd.concat(public_debt_dfs)

# save to data folder
public_debt_df.to_csv('data/raw/public_debt.csv', index=False)




unique_creditors = public_debt_df['creditor_name'].unique()

len(public_debt_dfs)  # Output: Number of DataFrames extracted from the PDF

df_f = public_debt_dfs[5]


doc = fitz.open(file_path)
page = doc.load_page(30)  # Load the same page with fitz
text = page.get_text()
rows = re.split(r'\n(?=\d{7}_\d)', text)
#
row = [f for f in rows if (re.search(r'^2021303_1', f))]
fields = row[0].strip().split('\n')
print(fields)
## save csvs

# 
# import numpy as np
# 
# 
# # Get unique values from the 'creditor_name' column
# unique_creditors = public_debt_df['creditor_name'].drop_duplicates()
# 
# # Create a single string of unique creditors separated by '|'
# creditors_pattern = '|'.join(unique_creditors)
# 
# def extract_creditors(title):
#     matches = re.findall(creditors_pattern, title)
#     # Flatten any tuples into strings
#     flat_matches = [', '.join(match) if isinstance(match, tuple) else match for match in matches]
#     return ', '.join(flat_matches)
# 
# # Step 4: Apply numpy.where to perform the conditional modification
# public_debt_df['creditor_name'] = np.where(
#     public_debt_df['creditor_name'] == "",  # Condition
#     public_debt_df['loan_title'].apply(extract_creditors),  # True: apply function to find matches
#     public_debt_df['creditor_name']  # False: retain original creditor_name
# )
# 
# mylist = public_debt_df['loan_title'].apply(extract_creditors)
#  
