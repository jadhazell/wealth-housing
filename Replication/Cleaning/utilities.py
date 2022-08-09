def is_valid_number(lease, price):

	# Pad numbers to avoid errors (otherwise 11 could be counted as 1, for example)
	# Pad house number
	if price.street_number == "":
		padded_street_number = ""
	else:
		padded_street_number = " " + price.street_number + " "
	# Pad address
	padded_lease = " " + lease

	# It is possible that the second number is embedded within the "flat_number" string
	if not price.flat_number.isnumeric():
		# Check whether the numeric portion of the secondary number is in the address
		split_flat_number = price.flat_number.split()
		flat_number = None
		for word in split_flat_number:
			# If one of the words in the second number is a number (or begins with a number, such as 32A), then use it as the number
			if word.isnumeric() or word[:-1].isnumeric():
				flat_number = word
				break
	if price.flat_number.isnumeric() or flat_number == None:
		flat_number = price.flat_number

	# Pad secondary number
	if flat_number == "":
		padded_flat_number = ""
	else:
		padded_flat_number = " " + flat_number + " "

	# print(f"padded house number: '{padded_street_number}'")
	# print(f"padded second number: '{padded_flat_number}'")
	# print(f"padded lease: '{padded_lease}'")
	# print(padded_street_number in padded_lease)
	# print(padded_flat_number in padded_lease)

	# If both padded numbers are in the address and the address starts with one of them...
	# if padded_street_number in padded_lease and (padded_flat_number in padded_lease or flat_number in ["FLAT", "APARTMENT"])\
	if padded_street_number in padded_lease and padded_flat_number in padded_lease\
		and (lease.startswith(price.street_number) or lease.startswith(price.flat_number) or padded_lease.startswith(padded_flat_number) or lease.split()[1] == flat_number):
		# If the numbers are not contained in each other, then we're good to go
		if (padded_street_number=="" or padded_flat_number=="") or (padded_street_number not in padded_flat_number and padded_flat_number not in padded_street_number):
			return True
		# If not, must check that the number appears twice in the address
		elif padded_street_number in padded_lease.replace(padded_flat_number, " "): 
			return True
		print(padded_lease.replace(padded_flat_number, " "))

	return False

def is_valid_street_and_locality(lease, price):
	if price.street != "" and price.street in lease:
		return True
	elif price.street == "" and price.locality != "" and price.locality in lease:
		return True 
	return False

def no_invalid_terms(lease, price):
	# Do not want land/parking associated with a property:
	for term in ["ASSOCIATED WITH", "GARAGE", "PARKING", "STORAGE", "LAND ADJOINING"]:
		if term in lease and term not in price.address:
			return False
	return True