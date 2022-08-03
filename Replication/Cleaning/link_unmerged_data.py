import os
import csv
import pandas as pd 
import pickle
from tqdm.notebook import tqdm
from Property import Property

data_directory = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Data/gov_uk/"
zip_data_directory = "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Data/zip_divided/"


new_matches = [["merge_key","property_id"]]

for postcode in sorted(os.listdir(zip_data_directory)):

	try:
		lease_file = os.path.join(zip_data_directory, postcode, "lease_properties.p")
		price_file = os.path.join(zip_data_directory, postcode, "price_properties.p")

		with open(lease_file, "rb") as f:
			leases = pickle.load(f)

		with open(price_file, "rb") as f:
			prices = pickle.load(f)

		print(f"\n\n\n{postcode}\n===================\n")
		for prop1 in leases:
			for prop2 in prices:

				if prop2.street in prop1 and " " + prop2.house_number + " " in " " + prop1 and (prop2.second_number == "" or " " + prop2.second_number + " " in " " + prop1):
					print("Found a match!")
					print(f"Lease data point: {prop1}")
					print(f"Price data point: {prop2.address}")
					print(f"{prop2.split_address()}\n")

					match_key = prop1.replace(" ", "")

					new_matches.append([match_key, prop2.property_id])

				# # This code produces some incorrect matches -- need to revise
				# elif prop2.street in prop1 and " " + prop2.house_number + " " in " " + prop1:
				# 	print("Found a match (without second_number)!")
				# 	print(f"Lease data point: {prop1}")
				# 	print(f"Price data point: {prop2.address()}")
				# 	print(f"{prop2.split_address()}\n")
	except:
		# print(f"\n\n\n{postcode}\n===================\n")
		continue

output_file = os.path.join(data_directory, "matched_with_python.csv")
with open(output_file, "w") as f:
	writer = csv.writer(f)
	writer.writerows(new_matches)