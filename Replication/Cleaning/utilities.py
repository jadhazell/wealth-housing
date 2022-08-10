def clean_number(text):
	return clean(text).replace("THE","").replace("FLAT","").replace("APARTMENT","").strip()

def clean(text):
	return text.replace(".","").replace(",","").replace(" - ","-").replace("'","").strip()

def get_embedded_number(text):
	if not text.isnumeric():
		# Check whether the numeric portion of the secondary number is in the address
		split_text = text.split()
		number = None
		for word in split_text:
			# If one of the words in the second number is a number (or begins with a number, such as 32A), then use it as the number
			if word.isnumeric() or word[:-1].isnumeric():
				number = word
				break
	if text.isnumeric() or number == None:
		number = text
	return number

def contains_street_and_flat_number(price):
	# If price data contains both numbers, return true
	if price.flat_number != "" and price.street_number != "":
		return True
	# If either one of the numbers contains multiple words, one of which is numeric, return True
	elif len(price.flat_number.split()) > 1:
		for word in price.flat_number.split():
			if word.isnumeric or word[:-1].isnumeric():
				return True
	elif len(price.street_number.split()) > 1:
		for word in price.street_number.split():
			if word.isnumeric or word[:-1].isnumeric():
				return True
	return False


def is_valid_number(lease, price):

	# It is possible that the number is embedded within the string
	street_number = get_embedded_number(price.street_number)
	flat_number = get_embedded_number(price.flat_number)


	# Pad numbers to avoid errors (otherwise 11 could be counted as 1, for example)
	# Pad house number
	if street_number == "":
		padded_street_number = ""
	else:
		padded_street_number = " " + street_number + " "
	# Pad address
	padded_lease = " " + lease


	# Pad secondary number
	if flat_number == "":
		padded_flat_number = ""
	else:
		padded_flat_number = " " + flat_number + " "

	# Create rotated versions of numbers
	if len(street_number.split())<=1:
		padded_rotated_street_number = padded_street_number
	else:
		padded_rotated_street_number = " " + street_number.split()[-1] + " "
		for word in street_number.split()[:-1]:
			padded_rotated_street_number += word + " "

	# print(f"street number: {padded_street_number}, rotated street number: {padded_rotated_street_number}")

	if len(flat_number.split())<=1:
		padded_rotated_flat_number = padded_flat_number
	else:
		padded_rotated_flat_number = " " + flat_number.split()[-1] + " "
		for word in flat_number.split()[:-1]:
			padded_rotated_flat_number += word + " "

	# print(f"flat number: {padded_flat_number}, rotated flat number: {padded_rotated_flat_number}")

	# If both padded numbers (or their rotations) are in the address...
	if (padded_street_number in padded_lease or padded_rotated_street_number in padded_lease) and (padded_flat_number in padded_lease or padded_rotated_flat_number in padded_lease):
		# If the numbers are not contained in each other, then we're good to go
		if (padded_street_number=="" or padded_flat_number=="") or (padded_street_number not in padded_flat_number and padded_flat_number not in padded_street_number):
			return True
		# If not, must check that the number appears twice in the address
		elif padded_street_number in padded_lease.replace(padded_flat_number, " "): 
			return True

	return False

def is_valid_street_and_locality(lease, price):
	if price.street != "" and price.street in lease:
		return True
	elif price.street == "" and price.locality != "" and price.locality in lease:
		return True 

	# If neither of this holds, check whether a variation of the street name is in the lease address
	if len(price.street.split()) >= 1:
		for word in price.street.split():
			if word in lease or word[:-1] in lease:
				return True

	return False

def no_invalid_terms(lease, price):
	# Do not want land/parking associated with a property:
	for term in ["ASSOCIATED WITH", "GARAGE", "PARKING", "STORAGE", "LAND ADJOINING", "BALCONY ADJOINING"] + [f"LAND LYING TO THE {direction} OF" for direction in ["NORTH","SOUTH","EAST","WEST"]]:
		if term in lease and term not in price.address:
			return False
		if term in price.address and term not in lease:
			return False
	return True