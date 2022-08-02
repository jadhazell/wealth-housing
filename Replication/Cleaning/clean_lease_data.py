import os
import pandas as pd
import pickle

lease_file = os.path.join("..","..","Input","gov_uk","LEASES_FULL_2022_06.csv")
df = pd.read_csv(lease_file)

print(df.head())

cols = ["Associated Property Description","County","Region"]

addresses = df[cols]

# Drop duplicates
print("Dropping duplicates")
addresses = addresses.drop_duplicates()

print("Removing punctuation")
addresses[cols] = addresses[cols].replace({'.':''}, regex=True)
addresses[cols] = addresses[cols].replace({',':''}, regex=True)

print("Uppercase")
for col in cols:
	addresses[col] = addresses[col].str.upper()

print(addresses.head())

output_file = os.path.join("..","Data","gov_uk","lease_data")
addresses.to_pickle(output_file)