
// Price data

drop v1 v2 v3 v5 v6 v15 v16
rename v4 postcode
rename v7 duration
rename v8 house_number
rename v9 secondary_number
rename v10 street
rename v11 locality
rename v12 city
rename v13 district
rename v14 county

// Drop non leases (not relevant for merge)
drop if duration != "L"
// Drop missing data
drop if missing(postcode)
// Drop duplicates
duplicates drop postcode house_number secondary_number street locality city district county, force

// Create merge keys
egen merge_key_1 = concat(secondary_number house_number street city postcode), punct(" ")
replace merge_key_1 = upper(strtrim(stritrim(merge_key_1)))

if locality != city {
	egen merge_key_2 = concat(secondary_number house_number street locality city postcode), punct(" ")
	replace merge_key_2 = upper(strtrim(stritrim(merge_key_1)))	
}

// Lease data

// Drop unnecessary columns
keep associatedpropertydescription county region
rename associatedpropertydescription merge_key_1

//Remove commas/periods
replace merge_key_1 = subinstr(address,".","",.)
replace merge_key_1 = subinstr(address,",","",.)

//Make uppercase
replace merge_key_1 = upper(merge_key_1)
replace county = upper(county)
replace region = upper(region)

//Drop duplicates
duplicates drop address county region, force

//Create second merge key for merging with price data
gen merge_key_2 = merge_key_1



// Combine

use "lease_data", clear
merge 1:1 merge_key_1 using "price_data"

// Save merged entries

keep if _merge==1
keep merge_key_2 county region
merge 1:1 merge_key_2 "price_data"
