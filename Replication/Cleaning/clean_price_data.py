import os
import pandas as pd

price_file = os.path.join("..","..","Input","gov_uk","pp-complete.txt")
df = pd.read_csv(price_file, names=["id","Price", "Date", "Postcode", "Property_Type", "New", "Duration", "House_Number", "Secondary_Number", "Street", "Locality", "City", "District","County","v15","v16"])

# Drop unnecessary rows:
print("Dropping unnecessary rows")
df = df.drop(df[df.Property_Type == "U" or df.Property_Type == "F"])

print(df.head())

print("Making addresses df")
cols = ["Postcode","House_Number", "Secondary_Number", "Street", "Locality", "City", "District","County"]

addresses = df[cols]

# Drop duplicates
addresses = addresses.drop_duplicates()

# addresses[cols] = addresses[cols].replace({'.':''}, regex=True)
# addresses[cols] = addresses[cols].replace({',':''}, regex=True)

for col in cols:
	addresses[col] = addresses[col].str.upper()

print(addresses.head())

output_file = os.path.join("..","Data","gov_uk","price_data")
addresses.to_pickle(output_file)