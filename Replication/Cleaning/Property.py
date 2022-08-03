class Property:
	def __init__(self, house_number, second_number, street, locality, city, postcode, property_id):
		self.house_number = house_number.replace(".","").replace(",","")
		self.second_number = second_number.replace(".","").replace(",","")
		self.street = street.replace(".","").replace(",","")
		self.locality = locality.replace(".","").replace(",","")
		self.city = city.replace(".","").replace(",","")
		self.postcode = postcode.replace(".","").replace(",","")
		self.property_id = property_id.replace(".","").replace(",","")
		self.address = f"{self.second_number} {self.house_number} {self.street} {self.locality} {self.city}"

	def __str__(self):
		output = f"Property ID: {self.property_id}\n"
		output += f"Address: {self.second_number} {self.house_number} {self.street} {self.locality} {self.city}"
		return output

	def split_address(self):
		return f" Second Number: {self.second_number}\n House Number: {self.house_number}\n Street: {self.street}\n Locality: {self.locality}\n City: {self.city}"