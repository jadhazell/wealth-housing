import os
import csv
import pandas as pd 
import pickle
from tqdm import tqdm
from Property import Property
from utilities import * 

root = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP"
data_directory = os.path.join(root, "Data", "gov_uk")
zip_data_directory = os.path.join(root, "Data", "zip_divided")
#zip_data_directory = os.path.join(root, "Data", "zip_divided_2")


new_matches = [["merge_key","property_id"]]

print("Starting search...")
for i, postcode in enumerate(sorted(os.listdir(zip_data_directory))):
	
	zip_directory = os.path.join(zip_data_directory, postcode)

	# if postcode != "AL1 1AR":
	# 	continue

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
			if prop2.street_number == "SELSEY COUNTRY CLUB LITTLE SPAIN":
				prop2.flat_number = prop2.flat_number.split()[1] + " " + prop2.flat_number.split()[0]

			for prop1 in leases:
		
				# We need at least one number to properly identify
				if prop2.street_number=="" and prop2.flat_number=="":
					continue

				# Look for addresses that contain house and secondary house number, no invalid terms, and either have a valid street/locality or are not missing either number
				if  is_valid_number(prop1, prop2) and no_invalid_terms(prop1, prop2):
					
					print("Found a match!")
					print(f"Lease data point: {prop1}")
					print(f"Price data point:{prop2.address} {postcode}\n")
					print(f"{prop2.split_address()}\n")

					match_key = prop1.replace(" ", "")
					new_matches.append([match_key, prop2.property_id])

print("Matches:")
print(len(new_matches))

output_file = os.path.join(data_directory, "matched_with_python.csv")
with open(output_file, "w") as f:
	writer = csv.writer(f)
	writer.writerows(new_matches)

