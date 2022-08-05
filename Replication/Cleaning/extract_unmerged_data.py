import os
import pandas as pd 
import pickle
from tqdm import tqdm
from Property import Property

root = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP"
data_directory = os.path.join(root, "Data", "gov_uk")
zip_data_directory = os.path.join(root, "Data", "zip_divided")
city_data_directory = os.path.join(root, "Data", "city_divided")


for postcode in tqdm(sorted(os.listdir(zip_data_directory))):

	postcode_directory = os.path.join(zip_data_directory, postcode)
	if os.path.isdir(postcode_directory) and "price_properties.p" in os.listdir(postcode_directory):
		os.remove(os.path.join(postcode_directory, "price_properties.p"))

########################################################################################
### Extract unmerged price data with zipcodes
########################################################################################

print("Extracting unmerged price data with zipcodes...")

# Load data from DTA file
unmerged_prices_data_file = os.path.join(data_directory, "unmerged_price_data.dta")
prices = pd.read_stata(unmerged_prices_data_file)

# Convert data into Property objects and sort by postcode/city
price_data = dict()
price_data_by_city = dict()
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

	if prop.city in price_data_by_city:
		price_data_by_city[prop.city].append(prop)
	else:
		price_data_by_city[prop.city] = [prop]

# Store data into postcode-separated folders
for postcode in tqdm(price_data):
	zip_folder = os.path.join(zip_data_directory, postcode)

	if not zip_folder in os.listdir(zip_data_directory):
		os.mkdir(zip_folder)

	file = os.path.join(zip_folder, "price_properties.p")
	with open(file, "wb") as f:
		pickle.dump(price_data[postcode], f)

# Sort data into city-separated folders
for city in tqdm(price_data_by_city):
	city_folder = os.path.join(city_data_directory, city)

	if not city_folder in os.listdir(city_data_directory):
		os.mkdir(city_folder)

	file = os.path.join(city_folder, "price_properties.p")
	with open(file, "wb") as f:
		pickle.dump(price_data_by_city[city], f)

# ########################################################################################
# ### Extract all unmerged lease data
# ########################################################################################

print("Extracting all unmerged lease data...")

# Load data from DTA file
unmerged_lease_data_file = os.path.join(data_directory, "unmerged_lease_data.dta")
leases = pd.read_stata(unmerged_lease_data_file)

# Iterate through lease data and extract zipcode/city from address (store values which do not have a valid city or zipcode)
lease_data = dict()
lease_data_by_city = dict()
invalid_data = []
for index, row in tqdm(leases.iterrows()):
	address = row["property_description"].replace(".","").replace(",","")
	split_address = address.split()

	# Check if lease data point has zipcode
	postcode = split_address[-2] + " " + split_address[-1]
	if postcode in lease_data:
		lease_data[postcode].append(address)
	else:
		lease_data[postcode] = [address]

print("Storing lease data by zip...")
# Store lease data by postcode
for postcode in tqdm(lease_data):
	try:
		zip_folder = os.path.join(zip_data_directory, postcode)
		file = os.path.join(zip_folder, "lease_properties.p")
		with open(file, "wb") as f:
			pickle.dump(lease_data[postcode], f)
	except:
		print(f"Folder does not exist: {postcode}")
