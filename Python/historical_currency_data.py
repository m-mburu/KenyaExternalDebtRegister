
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def navigate_to_year_and_currency(driver, base_url, year, currency_pair):
    try:
        # Construct the URL based on the base URL, year, and currency pair
        target_url = f"{base_url}/USD-to-{currency_pair}-{year}"
        # Navigate to the constructed URL
        driver.get(target_url)
        print(f"Successfully navigated to the year {year} for USD to {currency_pair}")
        
        # Wait for the page to load
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.TAG_NAME, 'body')))
        
        # Return the page source
        html_content = driver.page_source
        dfs = fetch_data(html_content, currency_pair)
        df = pd.concat(dfs, ignore_index=True)
        return df
    
    except TimeoutException:
        print('Timeout while loading the page.')
        return None
    except Exception as e:
        print(f'An error occurred while navigating: {str(e)}')
        return None



from bs4 import BeautifulSoup
import pandas as pd

def fetch_data(html_content, currency_pair):
    if not html_content:
        return None
    
    # Create a BeautifulSoup object
    soup = BeautifulSoup(html_content, 'html.parser')
    
    # Find the container with class 'tab-content'
    tab_content = soup.find('div', class_='tab-content')
    if not tab_content:
        print("No 'tab-content' class found in the HTML.")
        return None
    
    # Initialize a list to store DataFrames
    data_frames = []
    
    # Loop through each month block found by h3 within the 'tab-content'
    for h3 in tab_content.find_all('h3'):
        month_year = h3.get_text().strip()
        table_body = h3.find_next('tbody')
        
        # Lists to store column data
        days = []
        rates = []
        
        # Extract each day and corresponding rate
        for row in table_body.find_all('tr'):
            day_cells = row.find_all('td', class_='calendar-day')
            for cell in day_cells:
                day_number = cell.find('div', class_='day-number').get_text().strip()
                rate = cell.find('p').get_text().strip()
                days.append(day_number)
                rates.append(rate)
        
        # Create a DataFrame for the current month
        df = pd.DataFrame({
            'Currency_Pair': currency_pair',
            'Day_Number': days,
            'Month_Year': month_year,
            'Exchange_Rate': rates
        })
        data_frames.append(df)
    
    return data_frames

chrome_options = Options()
chrome_options.add_experimental_option('excludeSwitches', ['enable-logging'])
driver = webdriver.Chrome(options=chrome_options)

# Define parameters
base_url = 'https://www.poundsterlinglive.com/bank-of-england-spot/historical-spot-exchange-rates/usd'
year = '1981'
currency_pair = 'EUR'

# Navigate and fetch data
df = navigate_to_year_and_currency(driver, base_url, year, currency_pair)
df = pd.concat(data_frames, ignore_index=True)

#driver.quit()

# create a list from 1982 to 2024 and loop though the years returning the dataframes

years = list(range(1983, 2025))
currency_pair = 'EUR'
dfs = []

for year in years:
    chrome_options = Options()
    chrome_options.add_experimental_option('excludeSwitches', ['enable-logging'])
    driver = webdriver.Chrome(options=chrome_options)
    df = navigate_to_year_and_currency(driver, base_url, str(year), currency_pair)
    if df is not None:
        dfs.append(df)
    driver.quit()
    

## write to data/raw folder as f{currency_pair}_historical_data.csv

df = pd.concat(dfs, ignore_index=True)
df.to_csv(f'data/raw/{currency_pair}_historical_data.csv', index=False)


currencies_incorrect = ["JPK",  "CHF", "SEK", "INR", "GBP", "CAD", "DKK", "EUR", 
                        "XDR", "SAR", "CNY", "KRW", "AUA", "KWD", "AED"]

currencies_pair_list = ["JPY",  "CHF", "SEK", "INR", "GBP", "CAD", "DKK", "EUR", 
                      "XDR", "SAR", "CNY", "KRW", "AUD", "KWD", "AED"]
                      
                      
years = list(range(1983, 2025))
dfs = []
all_dfs = []
for currency_pair in currencies_pair_list:
    for year in years:
        chrome_options = Options()
        chrome_options.add_experimental_option('excludeSwitches', ['enable-logging'])
        driver = webdriver.Chrome(options=chrome_options)
        df = navigate_to_year_and_currency(driver, base_url, str(year), currency_pair)
        if df is not None:
            dfs.append(df)
        driver.quit()
    
    df = pd.concat(dfs, ignore_index=True)
    all_dfs.append(df)

historical_rates = pd.concat(all_dfs, ignore_index=True)
historical_rates.to_csv('data/raw/historical_exchange_rates.csv', index=False)
