import os
import pandas as pd 
import pickle
from tqdm import tqdm
from Property import Property
from utilities import * 
import sys
import re

def delete_existing_pickled_files(divided_data_directory, output_lease_file = "lease_properties.p", output_price_file = "price_properties.p", run_price="T", run_lease="T"):
	'''
	deletes pickled postcode divided or city divided data so that it can be properly updated with the new data

	args:
	divided_data_directory : string
		path to the directory in which we will store pickled, divided data

	returns: None
	'''
	print("\nDeleting existing pickled files...")

	for postcode in tqdm(sorted(os.listdir(divided_data_directory))):
		postcode_directory = os.path.join(divided_data_directory, postcode)
		if run_price == "T":
			try:
				os.remove(os.path.join(postcode_directory, output_price_file))
				# print("deleted price file")
			except:
				pass
		if run_lease == "T":
			try:
				os.remove(os.path.join(postcode_directory, output_lease_file))
				# print("deleted lease file")
			except:
				pass

def extract_unmerged_price_data(data_directory, unmerged_prices_data_file, divided_data_directory, output_price_file, division_level="postcode"):
	'''
	extract data from .dta file, separate it by the appropriate division level, and store it in a pickled dictionary (with keys that are members of the identified division level)

	args:
	unmerged_prices_data_file : string
		path to the .dta file with unmerged price data
	divided_data_directory : string
		path to the directory in which we will store pickled, divided data
	division_level : string
		string denoting the division level at which we should store the data

	return:
	keys: list<string>
		list of keys to price_data, which includes all unique members of division level
	'''
	print("Extracting unmerged price data with postcodes...")

	# Load data from DTA file
	prices = pd.read_stata(unmerged_prices_data_file)

	print(f"Number of data point in input file: {prices.shape[0]}")

	# Convert data into Property objects and sort by postcode/city
	price_data = dict()
	for index, row in tqdm(prices.iterrows()):
		street_number = row["street_number"]
		flat_number = row["flat_number"]
		street = row["street"]
		locality = row["locality"]
		city = row["city"]
		postcode = row["postcode"]
		property_id = row["property_id"]

		prop = Property(street_number, flat_number, street, locality, city, postcode, property_id)

		if division_level == "postcode":
			if postcode in price_data:
				price_data[postcode].append(prop)
			else:
				price_data[postcode] = [prop]
		
		elif division_level == "city":
			if city in price_data:
				price_data[city].append(prop)
			else:
				price_data[city] = [prop]

	print("Storing unmerged price data in folders...")

	# Dump all data:
	main_file = os.path.join(data_directory, f"all_transaction_data.p")
	with open(main_file, "wb") as f:
		pickle.dump(price_data, f)

	# Store data into postcode-separated folders
	total_obs = 0
	for key in tqdm(price_data):

		print(f"{key}: {len(price_data[key])} observations")
		total_obs += len(price_data[key])

		folder = os.path.join(divided_data_directory, key)

		try:
			os.mkdir(folder)
		except:
			pass

		file = os.path.join(folder, output_price_file)
		with open(file, "wb") as f:
			pickle.dump(price_data[key], f)

	print(f"Number of stored data points: {total_obs}")

	keys = price_data.keys()
	return keys

def extract_unmerged_lease_data(data_directory, unmerged_lease_data_file, divided_data_directory, output_lease_file, division_level="postcode", keys=[]):
	'''
	extract data from .dta file, separate it by the appropriate division level, and store it in a pickled dictionary (with keys that are members of the identified division level)

	args:
	unmerged_lease_data_file : string
		path to the .dta file with unmerged lease data
	divided_data_directory : string
		path to the directory in which we will store pickled, divided data
	division_level : string
		string denoting the division level at which we should store the data
	keys: list<string>
		list of keys to price_data, which includes all unique members of division level

	return: None
	'''
	print("Extracting all unmerged lease data...")

	# Load data from DTA file
	if unmerged_lease_data_file.endswith("dta"):
		leases = pd.read_stata(unmerged_lease_data_file)
	elif unmerged_lease_data_file.endswith("csv"):
		leases = pd.read_csv(unmerged_lease_data_file)

	print("Loaded data:")
	print("Num obvs:", leases.shape[0])

	if division_level == "city":
		cities_with_length_3 = [city for city in keys if len(city.split()) == 3]
		cities_with_length_4 = [city for city in keys if len(city.split()) == 4]


	# Iterate through lease data and extract postcode/city from address (store values which do not have a valid city or postcode)
	lease_data = dict()
	invalid_data = []
	for index, row in tqdm(leases.iterrows()):
		address = row["description"]
		split_address = address.split()

		if division_level == "postcode":		
			# Check if lease data point has postcodecode
			postcode = split_address[-2] + " " + split_address[-1]
			match = re.search("([Gg][Ii][Rr] 0[Aa]{2})|((([A-Za-z][0-9]{1,2})|(([A-Za-z][A-Ha-hJ-Yj-y][0-9]{1,2})|(([A-Za-z][0-9][A-Za-z])|([A-Za-z][A-Ha-hJ-Yj-y][0-9][A-Za-z]?))))\s?[0-9][A-Za-z]{2})", postcode)
			
			if match:
				# Check that postcode has valid format
				try:
					lease_data[postcode].append(address)
				except KeyError:
					lease_data[postcode] = [address]

		elif division_level == "city":
			#Check if lease data point has valid city
			city = None
			if len(split_address)>= 1 and split_address[-1] in keys:
				city = split_address[-1]
			elif len(split_address)>= 2 and split_address[-2] + " " + split_address[-1] in keys:
				city = split_address[-2] + " " + split_address[-1]
			elif len(split_address)>= 3 and split_address[-3] + " " + split_address[-2] + " " + split_address[-1] in cities_with_length_3:
				city = split_address[-3] + " " + split_address[-2] + " " + split_address[-1]
			elif len(split_address)>= 4 and split_address[-4] + " " + split_address[-3] + " " + split_address[-2] + " " + split_address[-1] in cities_with_length_4:
				city = split_address[-4] + " " + split_address[-3] + " " + split_address[-2] + " " + split_address[-1]

			if city:
				if city in lease_data:
					lease_data[city].append(address)
				else:
					lease_data[city] = [address]

	print("Storing unmerged lease data in folders...")

	# Dump all data:
	main_file = os.path.join(data_directory, f"all_lease_data.p")
	with open(main_file, "wb") as f:
		pickle.dump(lease_data, f)

	# Store lease data by postcode
	for key in tqdm(lease_data):
		try:
			folder = os.path.join(divided_data_directory, key)
			file = os.path.join(folder, output_lease_file)
			with open(file, "wb") as f:
				pickle.dump(lease_data[key], f)
		except:
			pass

def main(data_directory, divided_data_directory, division_level="postcode", lease_file = "unmerged_lease_data.dta", price_file = "unmerged_price_data.dta", output_lease_file = "lease_properties.p", output_price_file = "price_properties.p", run_price="T", run_lease="T"):
	
	print("lease file: ", lease_file)
	print("price file: ", price_file)
	print("lease output file: ", output_lease_file)
	print("price output file: ", output_price_file)
	print("run price:", run_price)
	print("run lease:", run_lease)

	# delete_existing_pickled_files(divided_data_directory, output_lease_file = output_lease_file, output_price_file = output_price_file, run_price=run_price, run_lease=run_lease)

	if division_level == "city":
		price_file = "cleaned_price_data_no_postcode_leaseholds.dta"
		lease_file = "unmerged_lease_data_for_no_postcode_cleaning.dta"

	if run_price == "T":
		print("Extracting unmerged price data")
		keys = extract_unmerged_price_data(data_directory, os.path.join(data_directory, price_file), divided_data_directory, output_price_file, division_level=division_level)
	if run_lease == "T":
		print("Extracting unmerged lease data")
		extract_unmerged_lease_data(data_directory, os.path.join(data_directory, lease_file), divided_data_directory, output_lease_file, division_level=division_level)


if __name__ == "__main__":
	error_msg = 'The first argument specifies whether the data ought to be divided at the postcode or city level. Please have the first argument be either "postcode" to divide the data at the postcode level or "city" to divide the data at the city level.\nThe second argument specifies the path to the stata working directory.\nThe third argument specifies the path to the python working directory.\nSample commandline input: python3 extract_unmerged_data.py postcode "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Working/stata_working" "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Working/python_working".'

	if len(sys.argv) < 4:
		print("This program requires three arguments.")
		print(error_msg)
		sys.exit(1)

	division_level = sys.argv[1]
	stata_directory = sys.argv[2].replace('"','')
	python_directory = sys.argv[3].replace('"','')

	flags = ["-lease_file", "-price_file", "-output_lease_file", "-output_price_file", "-run_lease", "-run_price"]
	optional_arguments = ["unmerged_lease_data.dta", "unmerged_price_data.dta", "lease_properties.p", "price_properties.p", "T", "T"]

	# Get any optional arguments
	for i, flag in enumerate(flags):
		if flag in sys.argv:
			optional_arguments[i] = sys.argv[sys.argv.index(flag) + 1]

	print("Optional Arguments:", optional_arguments)

	if division_level not in ["postcode", "city"] or not os.path.isdir(stata_directory) or not os.path.isdir(python_directory):
		print("One of the arguments you entered was not valid.")
		print(error_msg)
		sys.exit(1)

	else:
		if division_level == "postcode":
			divided_data_directory = os.path.join(python_directory, "postcode_divided")
		elif division_level == "city":
			divided_data_directory = os.path.join(python_directory, "city_divided")

		main(stata_directory, divided_data_directory, division_level=division_level, lease_file = optional_arguments[0], price_file = optional_arguments[1], output_lease_file = optional_arguments[2], output_price_file = optional_arguments[3], run_lease=optional_arguments[4], run_price=optional_arguments[5])


