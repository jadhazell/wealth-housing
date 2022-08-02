import pandas

price_file = os.path.join("..","Data","gov_uk","price_data")
lease_file = os.path.join("..","Data","gov_uk","lease_data")

price = pd.read_pickle(price_file)
lease = pd.read_pickle(lease_file)

# First, extract all rows that match
# Combine address from price data
cols = ["Postcode","House_Number", "Secondary_Number", "Street", "Locality", "City", "District","County"]
price["merge_key_1"] = df[cols].apply(lambda row: '_'.join(row.values.astype(str)), axis=1)

cols = ["Postcode","House_Number", "Secondary_Number", "Street", "Locality", "City", "District","County"]
price["merge_key_1"] = df[cols].apply(lambda row: '_'.join(row.values.astype(str)), axis=1)


# Iterative process to go through rows that don't match