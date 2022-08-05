import pickle 
import os
from tqdm import tqdm
import csv
from utilities import * 

root = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP"
data_directory = os.path.join(root, "Data", "gov_uk")
zip_data_directory = os.path.join(root, "Data", "zip_divided")
city_data_directory = os.path.join(root, "Data", "city_divided")

new_matches = [["merge_key","property_id"]]

########################################################################################
#First, try to match data within same city
########################################################################################

new_matches = [["merge_key","property_id"]]
for city in sorted(os.listdir(city_data_directory)):

	city_directory = os.path.join(city_data_directory, city)
	if os.path.isdir(city_directory):

		# Get lease data (if it doesn't exist, then continue)
		if "lease_properties.p" in os.listdir(city_directory):
			with open(os.path.join(city_directory, "lease_properties.p"), "rb") as f:
				lease_data = pickle.load(f)
		else:
			continue

		# Combine price data with and without postcode (if it exists)
		if "price_properties_no_postcode.p" in os.listdir(city_directory):
			with open(os.path.join(city_directory, "price_properties_no_postcode.p"), "rb") as f:
				price_data = pickle.load(f)
		else:
			continue


		print(f"\n\n\n{city}\n===================\n")
		for prop1 in lease_data:
			for prop2 in price_data:
				if is_valid_street_and_locality(prop1, prop2) and is_valid_number(prop1, prop2) and no_invalid_terms(prop1, prop2):
					print("Found match!")
					print(f"Lease data point: {prop1}")
					print(f"Price data point: {prop2.address}\n")

					match_key = prop1.replace(" ", "")
					new_matches.append([match_key, prop2.property_id])


print("Matches:")
print(len(new_matches))


output_file = os.path.join(data_directory, "no_postcode_matched_with_python.csv")
with open(output_file, "w") as f:
	writer = csv.writer(f)
	writer.writerows(new_matches)
