import os
import pandas as pd 
import pickle
from tqdm import tqdm
from Property import Property
from utilities import * 

def extract_unmerged_price_data(unmerged_prices_data_file, zip_data_directory):
	print("Extracting unmerged price data with zipcodes...")

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

		if postcode in price_data:
			price_data[postcode].append(prop)
		else:
			price_data[postcode] = [prop]

	print("Storing unmerged price data in folders...")
	# Store data into postcode-separated folders
	for postcode in tqdm(price_data):
		zip_folder = os.path.join(zip_data_directory, postcode)

		try:
			os.mkdir(zip_folder)
		except:
			pass

		file = os.path.join(zip_folder, "price_properties.p")
		with open(file, "wb") as f:
			pickle.dump(price_data[postcode], f)

def extract_unmerged_lease_data(unmerged_lease_data_file, zip_data_directory):
	print("Extracting all unmerged lease data...")

	# Load data from DTA file
	leases = pd.read_stata(unmerged_lease_data_file)

	# Iterate through lease data and extract zipcode/city from address (store values which do not have a valid city or zipcode)
	lease_data = dict()
	lease_data_by_city = dict()
	invalid_data = []
	for index, row in tqdm(leases.iterrows()):
		address = clean(row["description"])
		split_address = address.split()

		# Check if lease data point has zipcode
		postcode = split_address[-2] + " " + split_address[-1]
		try:
			lease_data[postcode].append(address)
		except KeyError:
			lease_data[postcode] = [address]

	print("Storing unmerged lease data in folders...")
	# Store lease data by postcode
	for postcode in tqdm(lease_data):
		try:
			zip_folder = os.path.join(zip_data_directory, postcode)
			file = os.path.join(zip_folder, "lease_properties.p")
			with open(file, "wb") as f:
				pickle.dump(lease_data[postcode], f)
		except:
			pass


''' MAIN CODE '''

root = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP"
data_directory = os.path.join(root, "Data", "gov_uk")
zip_data_directory = os.path.join(root, "Data", "zip_divided")
zip_data_directory_2 = os.path.join(root, "Data", "zip_divided_2")


for postcode in tqdm(sorted(os.listdir(zip_data_directory))):
	postcode_directory = os.path.join(zip_data_directory, postcode)
	try:
		os.remove(os.path.join(postcode_directory, "price_properties.p"))
	except:
		pass
	try:
		os.remove(os.path.join(postcode_directory, "lease_properties.p"))
	except:
		pass

# print("Deleting existing files...")
# for postcode in tqdm(sorted(os.listdir(zip_data_directory_2))):
# 	postcode_directory = os.path.join(zip_data_directory_2, postcode)
# 	try:
# 		price_file_path = os.path.join(postcode_directory, "price_properties.p")
# 		os.remove(price_file_path)
# 	except:
# 		pass
# 	try:
# 		os.remove(os.path.join(postcode_directory, "lease_properties.p"))
# 	except:
# 		pass


########################################################################################
### Extract unmerged price data with zipcodes
########################################################################################

extract_unmerged_price_data(os.path.join(data_directory, "unmerged_price_data.dta"), zip_data_directory)
#extract_unmerged_price_data(os.path.join(data_directory, "unmerged_price_post_python.dta"), zip_data_directory_2)

########################################################################################
### Extract all unmerged lease data
########################################################################################

extract_unmerged_lease_data(os.path.join(data_directory, "unmerged_lease_data.dta"), zip_data_directory)
#extract_unmerged_lease_data(os.path.join(data_directory, "unmerged_lease_post_python.dta"), zip_data_directory_2)


#################################################
### Print data by zipcode
#################################################

# for postcode in sorted(os.listdir(zip_data_directory_2)):
# 	postcode_path = os.path.join(zip_data_directory_2, postcode)
# 	if os.path.isdir(postcode_path) and "price_properties.p" in os.listdir(postcode_path) and "lease_properties.p" in os.listdir(postcode_path):
# 		print(f"\n\n\n\n==========================\n{postcode}\n==========================\n")

# 		with open(os.path.join(postcode_path, "price_properties.p"), "rb") as f:
# 			price_data = pickle.load(f)
# 		with open(os.path.join(postcode_path, "lease_properties.p"), "rb") as f:
# 			lease_data = pickle.load(f)

# 		print("Lease data:")
# 		for prop in lease_data:
# 			print(prop)

# 		print("\nPrice data:")
# 		for prop in price_data:
# 			print(prop.address + " " + prop.postcode)
# 			print(prop.split_address())
# 			print()



