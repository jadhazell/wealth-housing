import os
import pandas as pd 
import pickle
from tqdm import tqdm
from Property import Property
from utilities import * 
import sys
import re

def delete_existing_pickled_files(divided_data_directory):
	'''
	deletes pickled postcode divided or city divided data so that it can be properly updated with the new data

	args:
	divided_data_directory : string
		path to the directory in which we will store pickled, divided data

	returns: None
	'''
	print("Deleting existing pickled files...")
	for postcode in tqdm(sorted(os.listdir(divided_data_directory))):
		postcode_directory = os.path.join(divided_data_directory, postcode)
		try:
			os.remove(os.path.join(postcode_directory, "price_properties.p"))
		except:
			pass
		try:
			os.remove(os.path.join(postcode_directory, "lease_properties.p"))
		except:
			pass

def extract_unmerged_price_data(unmerged_prices_data_file, divided_data_directory, division_level="postcode"):
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
	# Store data into postcode-separated folders
	for key in tqdm(price_data):
		folder = os.path.join(divided_data_directory, key)

		try:
			os.mkdir(folder)
		except:
			pass

		file = os.path.join(folder, "price_properties.p")
		with open(file, "wb") as f:
			pickle.dump(price_data[key], f)

	keys = price_data.keys()
	return keys

def extract_unmerged_lease_data(unmerged_lease_data_file, divided_data_directory, division_level="postcode", keys=[]):
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
	leases = pd.read_stata(unmerged_lease_data_file)

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
	# Store lease data by postcode
	for key in tqdm(lease_data):
		try:
			folder = os.path.join(divided_data_directory, key)
			file = os.path.join(folder, "lease_properties.p")
			with open(file, "wb") as f:
				pickle.dump(lease_data[key], f)
		except:
			pass

def main(data_directory, divided_data_directory, division_level="postcode"):
	delete_existing_pickled_files(divided_data_directory)

	if division_level == "postcode":
		price_file = "unmerged_price_data.dta"
		lease_file = "unmerged_lease_data.dta"
		# price_file = "price_data.dta"
		# lease_file = "lease_data_for_merge.dta"
	elif division_level == "city":
		price_file = "cleaned_price_data_no_postcode_leaseholds.dta"
		lease_file = "unmerged_lease_data_for_no_postcode_cleaning.dta"

	keys = extract_unmerged_price_data(os.path.join(data_directory, price_file), divided_data_directory, division_level=division_level)
	extract_unmerged_lease_data(os.path.join(data_directory, lease_file), divided_data_directory, division_level=division_level, keys=keys)


if __name__ == "__main__":
	error_msg = 'The first argument specifies whether the data ought to be divided at the postcode or city level. Please have the first argument be either "postcode" to divide the data at the postcode level or "city" to divide the data at the city level.\nThe second argument specifies the path to the stata working directory.\nThe third argument specifies the path to the python working directory.\nSample commandline input: python3 extract_unmerged_data.py postcode "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Working/stata_working" "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Working/python_working".'

	if len(sys.argv) < 4:
		print("This program requires three arguments.")
		print(error_msg)
		sys.exit(1)

	else:
		division_level = sys.argv[1]
		stata_directory = sys.argv[2].replace('"','')
		python_directory = sys.argv[3].replace('"','')

	if division_level not in ["postcode", "city"] or not os.path.isdir(stata_directory) or not os.path.isdir(python_directory):
		print("One of the arguments you entered was not valid.")
		print(error_msg)
		sys.exit(1)

	else:
		if division_level == "postcode":
			divided_data_directory = os.path.join(python_directory, "postcode_divided")
		elif division_level == "city":
			divided_data_directory = os.path.join(python_directory, "city_divided")

		main(stata_directory, divided_data_directory, division_level=division_level)


