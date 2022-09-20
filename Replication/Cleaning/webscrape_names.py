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
# from scrapingbee import ScrapingBeeClient
from itertools import cycle
from scraper_api import ScraperAPIClient

main_dir = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP"
input_folder = os.path.join(main_dir, "Cleaning", "Output")
output_folder = os.path.join(main_dir, "Cleaning", "Working", "Scraped Names")

# input_folder = os.path.join("..","Input")
# output_folder = os.path.join("..","Output")

proxy='http://orange:orange@43.132.109.229:23992'

header = {
	"accept" : "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
	"user-agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36"
}


# Functions

def webscrape_names_addresses(inp):

	# print("Starting scrape:")

	postcode = inp[0]
	session = inp[1]

	output_msg = f"Scraping {postcode}!\n"
	# print(f"Scraping {postcode}!\n")

	all_addresses = set()
	new_data = []

	postcode_pt1 = postcode.split()[0]
	postcode_pt2 = postcode.split()[1]

	output_file = os.path.join(output_folder, f"{postcode}.csv")

	valid_request = True
	page_num = 0
	while valid_request:
		url = f"https://www.tracegenie.com/amember4/amember/1DAY/allpcsnew.php?s={page_num}&q6={postcode_pt1}%20{postcode_pt2}"

		output_msg += f"\n\n\nPage {page_num}\n---------------------\n"
		output_msg += f"Request: {url}\n"

		# result = session.get(url=url, proxies={"http": proxy, "https": proxy})
		result = session.get(url=url, headers=header)
		#result = session.get('http://api.scraperapi.com', params={'api_key':'cd6ce6bfd2fe26b6f767477b093212e2', 'url':url})
		if result.status_code != 200:
			print(f"I was blocked from {url}!")
			print(result.status_code)
			quit()
		soup = BeautifulSoup(result.text, 'html.parser')

		# print("Full result:")
		# print(result.text)

		# Search each div tag
		divs = soup.find_all("div")
		for div in divs:

			name = div.find("h2").get_text(separator=" ")
			address = div.find("h4").get_text(separator=" ")
			extra_info = div.find_all("a", href=True)

			# Remove extra spaces
			name = " ".join(name.split())
			address = " ".join(address.split())

			# If we've already reviewed this address, continue
			if address in all_addresses:
				continue
			else:
				all_addresses.add(address)

			# print(name)
			output_msg += "\nAddress:\n"
			output_msg += address + "\n"
			# print(f"\nAddress:\n {address}")

			# Get the full history of residents of this address
			href = ""
			for tag in extra_info:
				if tag["href"].startswith("occs.php"):
					href = tag["href"]

			history_url = f"https://www.tracegenie.com/amember4/amember/1DAY/{href}"
			#history_result = session.get(history_url, proxies={"http": proxy, "https": proxy})
			history_result = session.get(url=history_url, headers=header)
			#history_result = session.get('http://api.scraperapi.com', params={'api_key':'cd6ce6bfd2fe26b6f767477b093212e2', 'url':history_url})
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

	# Login Info:
	payload = {
		"amember_login" : "veronicabp@gmail.com",
		"amember_pass" : "TGdavipami2k!"
	}

	# Log in to website
	print("Trying to log in...")

	# session = requests.Session()
	session = ScraperAPIClient('cd6ce6bfd2fe26b6f767477b093212e2')
	# request = session.post("https://tracegenie.com/amember4/amember/login", data=payload, headers=header, proxies={"http":proxy, "https":proxy}, )
	# request = session.post("https://tracegenie.com/amember4/amember/login", data=payload)
	# request = session.post('http://api.scraperapi.com', params={'api_key':'cd6ce6bfd2fe26b6f767477b093212e2', 'url':'https://tracegenie.com/amember4/amember/login'}, data=payload)
	request = session.post("https://tracegenie.com/amember4/amember/login", headers=header, body=payload)
	print(request.status_code)

	print("Logged in to Trace Genie")

	# print(request.text)

	# File Paths
	transactions_file = os.path.join(input_folder, "postcodes.csv")

	# Load properties addresses data
	df = pd.read_csv(transactions_file)

	# Keep only first 500,000
	df = df.head(500000)

	processed_postcodes = [postcode.replace(".csv","") for postcode in os.listdir(output_folder)]

	# print(f"Processed Postcodes: {processed_postcodes}")

	inp = [(row["postcode"], session) for _, row in df.iterrows() if row["postcode"] not in processed_postcodes]


	# print(f"Postcodes Left: {inp}")

	print(f"Loaded data: [{len(inp)}/{df.shape[0]}] (= {100*len(inp)/df.shape[0]} %) postcodes left to process")

	# Parallelize code
	# num_processes = os.cpu_count()
	# num_processes = 100
	num_processes = 1
	processes_pool = Pool(num_processes)

	print("Scraping in parallel:")
	parallel_scraping(webscrape_names_addresses, inp, processes_pool)



