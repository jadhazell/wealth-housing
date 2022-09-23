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

def valid_match(property_obj, address):
	if clean_number(property_obj.street_number) in address and clean_number(property_obj.flat_number) in address:
		return True 
	return False

main_dir = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP"
input_folder = os.path.join(main_dir, "Cleaning", "Output")
stata_working_folder = os.path.join(main_dir, "Cleaning", "Working", "stata_working")
output_folder = os.path.join(main_dir, "Cleaning", "Working", "Scraped Names")

# input_folder = os.path.join("..","Input")
# output_folder = os.path.join("..","Output")

proxy='http://orange:orange@43.132.109.229:23992'

# Login Info:
headers = {
    'authority': 'tracegenie.com',
    'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'max-age=0',
    # Requests sorts cookies= alphabetically
    # 'cookie': 'PHPSESSID=4909c423d1e655241effd2049b3563c1; _ga=GA1.2.826987009.1663070199; amember_nr=fda6d4b1c4687c4b8c8067cd4cc01e96; _gid=GA1.2.2014828953.1663856187; _gat=1',
    'origin': 'https://www.tracegenie.com',
    'referer': 'https://www.tracegenie.com/',
    'sec-ch-ua': '"Google Chrome";v="105", "Not)A;Brand";v="8", "Chromium";v="105"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"macOS"',
    'sec-fetch-dest': 'document',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'same-site',
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36',
}

api_key = "WYILHXMUMDNJ8HZSC1YEQD21KWI186E4YAO7Y2Z4BWUJKO6LWT96IM0P7YM89N6HGV6W5BZ02MBES0YK"

# Functions

def webscrape_names_addresses(inp):

	# print("Starting scrape:")

	postcode = inp[0]
	session = inp[1]
	existing_properties = inp[2]

	output_msg = f"Scraping {postcode}!\n"
	# print(f"Scraping {postcode}!\n")

	all_addresses = set()
	new_data = []

	postcode_pt1 = postcode.split()[0]
	postcode_pt2 = postcode.split()[1]

	output_file = os.path.join(output_folder, f"{postcode}.csv")

	output_msg += f"Existing properties: {[prop.address for prop in existing_properties]}"

	# print(postcode)
	# print([prop.address for prop in existing_properties])

	valid_request = True
	page_num = 0
	while valid_request:
		url = f"https://www.tracegenie.com/amember4/amember/1DAY/allpcsnew.php?s={page_num}&q6={postcode_pt1}%20{postcode_pt2}"

		output_msg += f"\n\n\nPage {page_num}\n---------------------\n"
		output_msg += f"Request: {url}\n"

		# print(f"\n\n\nPage {page_num}\n---------------------\n")
		# print(f"Request: {url}\n")

		result = session.get(url, params = {'render_js': 'False',}, cookies=cookies, headers=headers)
		if result.status_code != 200:
			print(f"I was blocked from {url}!")
			print(result.status_code)
			quit()
		soup = BeautifulSoup(result.text, 'html.parser')

		# Search each div tag
		divs = soup.find_all("div")
		for div in divs:

			name = div.find("h2").get_text(separator=" ")
			address = div.find("h4").get_text(separator=" ")
			extra_info = div.find_all("a", href=True)

			# Remove extra spaces
			name = " ".join(name.split())
			address = clean(" ".join(address.split()))

			# If we've already reviewed this address, continue
			if address in all_addresses:
				continue
			else:
				all_addresses.add(address)

			# print(name)
			output_msg += "\nAddress:\n"
			output_msg += address + "\n"
			# print(f"\nAddress: {address}\n")

			# Check that the address exists in our transaction data
			address_exists = False
			for existing_property in existing_properties:
				if valid_match(existing_property, address):
					address_exists = True 
					existing_properties.remove(existing_property)
					break
			if not address_exists:
				output_msg += "Address is not in transaction data\n"
				continue

			# Get the full history of residents of this address
			href = ""
			for tag in extra_info:
				if tag["href"].startswith("occs.php"):
					href = tag["href"]

			history_url = f"https://www.tracegenie.com/amember4/amember/1DAY/{href}"
			history_result = session.get(history_url, params = {'render_js': 'False',}, cookies=cookies, headers=headers)
			if history_result.status_code != 200:
				print(f"I was blocked from {history_url}!")
				print(result.status_code)
				quit()

			history_soup = BeautifulSoup(history_result.text, 'html.parser')

			output_msg += f"Getting history at: {history_url}\n"
			# print(f"Getting history at: {history_url}\n")
			# print(history_result.text)

			b = history_soup.find_all("b")
			history = dict()
			for item in b:

				# Clean string
				item = item.get_text(separator=" ").replace(u'\xa0', u' ').replace(",","")
				item = " ".join(item.split())

				# Check whether the tag is a year
				if re.search("20[0-2][0-9]", item):
					current_year = item
					history[current_year] = []
				# If not, it is the name of the person living at the location in the previous year
				else:
					history[current_year].append(item)

			for year in history:
				if history[year]:
					new_data.append([address, year] + history[year])
					names = " and ".join(history[year])
					output_msg += f"{names} lived at {address} in in {year}\n"
					# print(f"{names} lived at {address} in in {year}\n")

		# Jump to next page
		page_num += 10

		# If the page there is no next button, don't keep searching
		if "Next" not in result.text or len(divs)==0:
			output_msg += "No next button. Skipping to next postcode.\n"
			valid_request = False

		# If we've matched all the properties in our transaction data set, don't keep searching
		if len(existing_properties) == 0:
			output_msg += "Matched all properties.\n"
			valid_request = False

	print(output_msg)
	if len(new_data) > 0:
		print("Storing data!\n")
		with open(output_file, "w") as f:
			writer = csv.writer(f)
			writer.writerow(["Address", "Date", "Name1", "Name2", "Name3"])
			writer.writerows(new_data)

def parallel_scraping(operation, input, pool):
	pool.map(operation, input)


if __name__ == "__main__":

	data = {
	    'amember_login': 'nturco@princeton.edu',
	    'amember_pass': 'bnbrk5',
	}

	# cookies = {
 #    # 'PHPSESSID': '4909c423d1e655241effd2049b3563c1',
 #    '_ga': 'GA1.2.826987009.1663070199',
 #    'amember_nr': 'fda6d4b1c4687c4b8c8067cd4cc01e96',
 #    '_gid': 'GA1.2.2014828953.1663856187',
 #    '_gat': '1',
	# }

	cookies = dict()


	# Log in to website
	print("Trying to log in...")

	session = ScrapingBeeClient(api_key=api_key)
	result = session.post("https://tracegenie.com/amember4/amember/login", data=data, params = {'render_js': 'False',})
	if result.status_code != 200:
		print(f"Unable to log in!")
		print(result.status_code)
		quit()

	returned_cookies = result.headers["Spb-Set-Cookie"]
	returned_cookies = returned_cookies.split(";")
	print(f"Returned Cookies:", returned_cookies)
	for cookie in returned_cookies:
		if 'PHPSESSID' in cookie:
			print("adding new cookie")
			cookies["PHPSESSID"] = cookie.replace("PHPSESSID=","")
			break
	print("Cookies: ", cookies)

	url = "https://www.tracegenie.com/amember4/amember/1DAY/allpcsnew.php?s=0&q6=AL1%201AJ"
	result = session.get(url, params = {'render_js': 'False',}, cookies=cookies, headers=headers)
	print(result.text)

	# print("Logged into Trace Genie")

	# # File Paths
	# transactions_file = os.path.join(input_folder, "postcodes.csv")

	# # Load properties addresses data
	# df = pd.read_csv(transactions_file)

	# # Load existing properties in transaction data
	# with open(os.path.join(stata_working_folder, "all_transaction_data.p"), "rb") as f:
	# 	transaction_data = pickle.load(f)

	# # # Keep only first 500,000
	# df = df.tail(5)
	# processed_postcodes = []
	# # processed_postcodes = [postcode.replace(".csv","") for postcode in os.listdir(output_folder)]

	# # Collect input data:
	# inp = []
	# for _, row in df.iterrows():
	# 	postcode = row["postcode"]
	# 	if postcode in transaction_data:
	# 		inp.append((postcode, session, set(transaction_data[postcode])))

	# # print(f"Postcodes Left: {inp}")

	# print(f"Loaded data: [{len(inp)}/{df.shape[0]}] (= {100*len(inp)/df.shape[0]} %) postcodes left to process")

	# # Parallelize code
	# num_processes = os.cpu_count()
	# processes_pool = Pool(num_processes)

	# print("Scraping in parallel:")
	# parallel_scraping(webscrape_names_addresses, inp, processes_pool)



