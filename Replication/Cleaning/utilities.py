def is_valid_number(lease, price):

	# Pad numbers to avoid errors (otherwise 11 could be counted as 1, for example)
	# Pad house number
	if price.house_number == "":
		padded_house_number = ""
	else:
		padded_house_number = " " + price.house_number + " "
	# Pad address
	padded_lease = " " + lease

	# It is possible that the second number is embedded within the "second_number" string
	if not price.second_number.isnumeric():
		# Check whether the numeric portion of the secondary number is in the address
		split_second_number = price.second_number.split()
		second_number = None
		for word in split_second_number:
			# If one of the words in the second number is a number (or begins with a number, such as 32A), then use it as the number
			if word.isnumeric() or word[:-1].isnumeric():
				second_number = word
				break
	if price.second_number.isnumeric() or second_number == None:
		second_number = price.second_number

	# Pad secondary number
	if second_number == "":
		padded_second_number = ""
	else:
		padded_second_number = " " + second_number + " "

	# print(f"padded house number: '{padded_house_number}'")
	# print(f"padded second number: '{padded_second_number}'")
	# print(f"padded lease: '{padded_lease}'")
	# print(padded_house_number in padded_lease)
	# print(padded_second_number in padded_lease)

	# If both padded numbers are in the address and the address starts with one of them...
	# if padded_house_number in padded_lease and (padded_second_number in padded_lease or second_number in ["FLAT", "APARTMENT"])\
	if padded_house_number in padded_lease and padded_second_number in padded_lease\
		and (lease.startswith(price.house_number) or lease.startswith(price.second_number) or padded_lease.startswith(padded_second_number) or lease.split()[1] == second_number):
		# If the numbers are not contained in each other, then we're good to go
		if (padded_house_number=="" or padded_second_number=="") or (padded_house_number not in padded_second_number and padded_second_number not in padded_house_number):
			return True
		# If not, must check that the number appears twice in the address
		elif padded_house_number in padded_lease.replace(padded_second_number, " "): 
			return True
		print(padded_lease.replace(padded_second_number, " "))

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