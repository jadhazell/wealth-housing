class Property:
	def __init__(self, street_number, flat_number, street, locality, city, postcode, property_id):
		self.street_number = street_number.replace(".","").replace(",","")
		self.flat_number = flat_number.replace(".","").replace(",","")
		self.street = street.replace(".","").replace(",","")
		self.locality = locality.replace(".","").replace(",","")
		self.city = city.replace(".","").replace(",","")
		self.postcode = postcode.replace(".","").replace(",","")
		self.property_id = property_id.replace(".","").replace(",","")
		self.address = f"{self.flat_number} {self.street_number} {self.street} {self.locality} {self.city}"

	def __str__(self):
		output = f"Property ID: {self.property_id}\n"
		output += f"Address: {self.flat_number} {self.street_number} {self.street} {self.locality} {self.city}"
		return output

	def split_address(self):
		return f" Second Number: {self.flat_number}\n House Number: {self.street_number}\n Street: {self.street}\n Locality: {self.locality}\n City: {self.city}"