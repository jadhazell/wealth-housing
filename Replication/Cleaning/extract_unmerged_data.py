import os
import pandas as pd 
import pickle
from tqdm.notebook import tqdm
from Property import Property

data_directory = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Data/gov_uk/"
zip_data_directory = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Data/zip_divided/"

### FIRST: PRICE DATA
unmerged_prices_data_file = os.path.join(data_directory, "unmerged_price_data.dta")
prices = pd.read_stata(unmerged_prices_data_file)

print("PRICE DATA:")

price_data = dict()

for index, row in tqdm(prices.iterrows()):
	house_number = row["house_number"]
	second_number = row["secondary_number"]
	street = row["street"]
	locality = row["locality"]
	city = row["city"]
	postcode = row["postcode"]
	property_id = row["property_id"]

	prop = Property(house_number, second_number, street, locality, city, postcode, property_id)

	if postcode in price_data:
		price_data[postcode].append(prop)
	else:
		price_data[postcode] = [prop]

for postcode in price_data:

	zip_folder = os.path.join(zip_data_directory, postcode)

	try:
		os.mkdir(zip_folder)
	except:
		print("Folder exists")

	file = os.path.join(zip_folder, "price_properties.p")
	with open(file, "wb") as f:
		pickle.dump(price_data[postcode], f)

#### SECOND: LEASE DATA:
print("\n\n\n\n\n\n\n\n\n\n\n\n\n")
print("LEASE DATA:")
valid_postcodes = price_data.keys()
unmerged_lease_data_file = os.path.join(data_directory, "unmerged_lease_data.dta")
leases = pd.read_stata(unmerged_lease_data_file)
lease_data = dict()

for index, row in tqdm(leases.iterrows()):
	address = row["property_description"].replace(".","").replace(",","")
	split_address = address.split()
	postcode = split_address[-2] + " " + split_address[-1]

	if postcode in lease_data:
		lease_data[postcode].append(address)
	else:
		print(postcode)
		lease_data[postcode] = [address]

print("\n\n\n\n\n\n\n\n\n\n\n\n\n")
print("Storing data:")
print("Addresses without valid zicpodes:")
no_zip = []
for postcode in lease_data:
	if postcode in valid_postcodes:
		zip_folder = os.path.join(zip_data_directory, postcode)
		file = os.path.join(zip_folder, "lease_properties.p")
		with open(file, "wb") as f:
			pickle.dump(lease_data[postcode], f)
	elif len(postcode) > 7:
		no_zip.extend(lease_data[postcode])

file = os.path.join(zip_data_directory, "no_zipcode_lease_properties.p")
with open(file, "wb") as f:
	pickle.dump(no_zip, f)
print(no_zip)

