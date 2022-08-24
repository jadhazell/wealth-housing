import os
import sys
import csv
import pandas as pd 
import pickle
from tqdm import tqdm
from Property import Property
from utilities import * 

def identify_and_write_matches(data_directory, divided_data_directory, division_level="postcode", verbose=False):
	new_matches = [["merge_key","property_id"]]

	print("Starting search...")
	for i, area in enumerate(tqdm(sorted(os.listdir(divided_data_directory)))):
		
		area_directory = os.path.join(divided_data_directory, area)

		if os.path.isdir(area_directory) and len(os.listdir(area_directory)) == 2:
			lease_file = os.path.join(divided_data_directory, area, "lease_properties.p")
			price_file = os.path.join(divided_data_directory, area, "price_properties.p")

			with open(lease_file, "rb") as f:
				leases = pickle.load(f)

			with open(price_file, "rb") as f:
				prices = pickle.load(f)

			if verbose:
				print(f"\n\n\n{area}\n===================\n")
			for prop2 in prices:

				# For the SELSEY COUNTRY CLUB LITTLE SPAIN, the order of the secondary number is flipped in the price data. Manually fix it.
				if prop2.street_number == "SELSEY COUNTRY CLUB LITTLE SPAIN":
					prop2.flat_number = prop2.flat_number.split()[1] + " " + prop2.flat_number.split()[0]

				# We need at least one number to properly identify
				if prop2.street_number=="" and prop2.flat_number=="":
					continue

				for prop1_not_cleaned in leases:

					prop1 = clean(prop1_not_cleaned)

					# print(f"Lease data point: {prop1}")
					# print(f"Price data point:{prop2.address}\n")
					# print(is_valid_street_and_locality(prop1, prop2))
					# print(is_valid_number(prop1, prop2))
					# print(no_invalid_terms(prop1, prop2))
					# print("\n")

					# Look for addresses that contain house and secondary house number, no invalid terms, and either have a valid street/locality or are not missing either number
					if (division_level == "postcode" and is_valid_number(prop1, prop2) and no_invalid_terms(prop1, prop2)) or \
						(division_level == "city" and is_valid_street_and_locality(prop1, prop2) and is_valid_number(prop1, prop2) and no_invalid_terms(prop1, prop2)):
						
						if verbose:
							print("Found a match!")
							print(f"Lease data point: {prop1}")
							print(f"Price data point:{prop2.address}\n")
							# print(f"{prop2.split_address()}\n")

						match_key = prop1_not_cleaned.replace(".","").replace("'","").replace(" ", "")
						new_matches.append([match_key, prop2.property_id])

	print("Number of matches:", len(new_matches))

	if division_level == "postcode":
		output_file = os.path.join(data_directory, "matched_with_python.csv")
	elif division_level == "city":
		output_file = os.path.join(data_directory, "no_postcode_matched_with_python.csv")
	with open(output_file, "w") as f:
		writer = csv.writer(f)
		writer.writerows(new_matches)

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

	if "-v" in sys.argv:
		verbose = True 
	else:
		verbose = False

	identify_and_write_matches(stata_directory, divided_data_directory, division_level=division_level, verbose=verbose)

