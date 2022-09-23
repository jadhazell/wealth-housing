import pandas as pd
import os
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from bs4 import BeautifulSoup
from lxml import html
import pickle
import csv
import re
import urllib3, socket
from urllib3.connection import HTTPConnection
from multiprocessing import Pool
import time
from scrapingbee import ScrapingBeeClient
from Property import Property
from utilities import *


url = "http://www.theukelectoralroll.co.uk/search.php?type=address"

cookies = {
    'PHPSESSID': 'nsnc2iffie79hkams8ofam1013',
}

headers = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    'Accept-Language': 'en-US,en;q=0.9',
    'Cache-Control': 'max-age=0',
    'Connection': 'keep-alive',
    # 'Cookie': 'PHPSESSID=nsnc2iffie79hkams8ofam1013',
    'Origin': 'http://www.theukelectoralroll.co.uk',
    'Referer': 'http://www.theukelectoralroll.co.uk/login.php',
    'Upgrade-Insecure-Requests': '1',
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36',
}

data = {
    'email': 'veronicabp@princeton.edu',
    'password': 'ukduration',
    'submit': 'Log in',
}

session = requests.Session()
result = session.post("https://tracegenie.com/amember4/amember/login", data=data, headers=headers, cookies=cookies)

# Load existing properties in transaction data
with open(os.path.join(stata_working_folder, "all_transaction_data.p"), "rb") as f:
	transaction_data = pickle.load(f)

for postcode in transaction_data:
	print(f"=============\n{postcode}\n=============\n")
	for address in transaction_data[postcode]:
		print(f"{address.address}\n----------------------------------------\n")
		result = session.post("https://tracegenie.com/amember4/amember/login", data=data, headers=headers, cookies=cookies)