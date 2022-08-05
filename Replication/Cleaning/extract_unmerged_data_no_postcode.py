
import os
import pandas as pd 
import pickle
from tqdm import tqdm
from Property import Property

root = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP"
data_directory = os.path.join(root, "Data", "gov_uk")
zip_data_directory = os.path.join(root, "Data", "zip_divided")
city_data_directory = os.path.join(root, "Data", "city_divided")


print("Deleting existing data...")
for city in tqdm(sorted(os.listdir(city_data_directory))):
	city_directory = os.path.join(city_data_directory, city)
	if os.path.isdir(city_directory) and "price_properties.p" in os.listdir(city_directory):
			os.remove(os.path.join(city_directory, "price_properties.p"))
	if os.path.isdir(city_directory) and "price_properties_no_postcode.p" in os.listdir(city_directory):
			os.remove(os.path.join(city_directory, "price_properties_no_postcode.p"))
	if os.path.isdir(city_directory) and "lease_properties.p" in os.listdir(city_directory):
			os.remove(os.path.join(city_directory, "lease_properties.p"))

# ########################################################################################
# ### Extract unmerged price data WITHOUT zipcodes
# ########################################################################################
print("Extracting unmerged price data WITHOUT zipcodes...")

# Load data from DTA file
no_postcode_prices_data_file = os.path.join(data_directory, "cleaned_price_data_no_postcode_leaseholds_unique.dta")
prices_no_zip = pd.read_stata(no_postcode_prices_data_file)

price_data_no_zip_by_city = dict()
for index, row in prices_no_zip.iterrows():
	house_number = row["house_number"]
	second_number = row["secondary_number"]
	street = row["street"]
	locality = row["locality"]
	city = row["city"]
	postcode = row["postcode"]
	property_id = row["property_id"]

	prop = Property(house_number, second_number, street, locality, city, postcode, property_id)

	if prop.city in price_data_no_zip_by_city:
		price_data_no_zip_by_city[prop.city].append(prop)
	else:
		price_data_no_zip_by_city[prop.city] = [prop]

# Sort data into city-separated folders
for city in price_data_no_zip_by_city:
	city_folder = os.path.join(city_data_directory, city)
	if not city in os.listdir(city_data_directory):
		os.mkdir(city_folder)
		print("Made new folder:", city_folder)
	file = os.path.join(city_folder, "price_properties_no_postcode.p")
	with open(file, "wb") as f:
		pickle.dump(price_data_no_zip_by_city[city], f)


valid_cities = price_data_no_zip_by_city.keys()
# ########################################################################################
# ### Extract all unmerged lease data
# ########################################################################################


print("Extracting all unmerged lease data...")

cities_with_length_3 = [city for city in valid_cities if len(city.split()) == 3]
cities_with_length_4 = [city for city in valid_cities if len(city.split()) == 4]

# Load data from DTA file
unmerged_lease_data_file = os.path.join(data_directory, "unmerged_lease_data_for_no_postcode_cleaning.dta")
leases = pd.read_stata(unmerged_lease_data_file)

# Iterate through lease data and extract zipcode/city from address (store values which do not have a valid city or zipcode)

print("Lease data by city...")
lease_data_by_city = dict()
invalid_data = []
for index, row in tqdm(leases.iterrows()):
	address = row["property_description"].replace(".","").replace(",","")
	split_address = address.split()

	#Check if lease data point has valid city
	city = None
	if len(split_address)>= 1 and split_address[-1] in valid_cities:
		city = split_address[-1]
	elif len(split_address)>= 2 and split_address[-2] + " " + split_address[-1] in valid_cities:
		city = split_address[-2] + " " + split_address[-1]
	elif len(split_address)>= 3 and split_address[-3] + " " + split_address[-2] + " " + split_address[-1] in cities_with_length_3:
		city = split_address[-3] + " " + split_address[-2] + " " + split_address[-1]
	elif len(split_address)>= 4 and split_address[-4] + " " + split_address[-3] + " " + split_address[-2] + " " + split_address[-1] in cities_with_length_4:
		city = split_address[-4] + " " + split_address[-3] + " " + split_address[-2] + " " + split_address[-1]

	if city:
		if city in lease_data_by_city:
			lease_data_by_city[city].append(address)
		else:
			lease_data_by_city[city] = [address]

print("Storing lease data by city...")
#Store lease data by city
for city in lease_data_by_city:
	city_folder = os.path.join(city_data_directory, city)
	file = os.path.join(city_folder, "lease_properties.p")
	with open(file, "wb") as f:
		pickle.dump(lease_data_by_city[city], f)
