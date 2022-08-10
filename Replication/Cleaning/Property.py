from utilities import *

class Property:
	def __init__(self, street_number, flat_number, street, locality, city, postcode, property_id):
		self.street_number = clean_number(street_number)
		self.flat_number = clean_number(flat_number)
		self.street = clean(street)
		self.locality = clean(locality)
		self.city = clean(city)
		self.postcode = clean(city)
		self.property_id = clean(property_id)
		self.address = f"{self.flat_number} {self.street_number} {self.street} {self.locality} {self.city}"

	def __str__(self):
		output = f"Property ID: {self.property_id}\n"
		output += f"Address: {self.flat_number} {self.street_number} {self.street} {self.locality} {self.city}"
		return output

	def split_address(self):
		return f" Flat Number: {self.flat_number}\n Street Number: {self.street_number}\n Street: {self.street}\n Locality: {self.locality}\n City: {self.city}"