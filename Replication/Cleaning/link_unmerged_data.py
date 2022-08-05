import os
import csv
import pandas as pd 
import pickle
from tqdm import tqdm
from Property import Property
from utilities import * 

data_directory = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Data/gov_uk/"
zip_data_directory = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Data/zip_divided/"


new_matches = [["merge_key","property_id"]]

for i, postcode in enumerate(sorted(os.listdir(zip_data_directory))):

	# if postcode != "AL1 1AR":
	# 	continue

	zip_directory = os.path.join(zip_data_directory, postcode)
	if os.path.isdir(zip_directory) and len(os.listdir(zip_directory)) == 2:
		lease_file = os.path.join(zip_data_directory, postcode, "lease_properties.p")
		price_file = os.path.join(zip_data_directory, postcode, "price_properties.p")

		with open(lease_file, "rb") as f:
			leases = pickle.load(f)

		with open(price_file, "rb") as f:
			prices = pickle.load(f)

		print(f"\n\n\n{postcode}\n===================\n")
		for prop2 in prices:

			# For the SELSEY COUNTRY CLUB LITTLE SPAIN, the order of the secondary number is flipped in the price data. Manually fix it.
			if prop2.house_number == "SELSEY COUNTRY CLUB LITTLE SPAIN":
				prop2.second_number = prop2.second_number.split()[1] + " " + prop2.second_number.split()[0]

			for prop1 in leases:
		
				# We need at least one number to properly identify
				if prop2.house_number=="" and prop2.second_number=="":
					continue

				# print("\n----------------------------------------\n")

				# print(f"\nLease data point: {prop1}")
				# print(f"Price data point: {prop2.address}")
				# print(is_valid_street_and_locality(prop1, prop2))
				# print(is_valid_number(prop1, prop2))

				# Look for addresses that contain the street (or locality if missing street), house and secondary house number
				if is_valid_street_and_locality(prop1, prop2) and is_valid_number(prop1, prop2) and no_invalid_terms(prop1, prop2):

					print("Found a match!")
					print(f"Lease data point: {prop1}")
					print(f"Price data point: {prop2.address}\n")
					# print(f"{prop2.split_address()}\n")

					match_key = prop1.replace(" ", "")

					new_matches.append([match_key, prop2.property_id])

print("Matches:")
print(len(new_matches))

output_file = os.path.join(data_directory, "matched_with_python.csv")
with open(output_file, "w") as f:
	writer = csv.writer(f)
	writer.writerows(new_matches)

