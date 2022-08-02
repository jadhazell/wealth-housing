
import delimited "$DATA/pp-complete.txt", clear

drop v1 v14 v15 v16
rename v2 price
rename v3 price_date
rename v4 postcode
rename v5 type
rename v6 new
rename v7 duration
rename v8 house_number
rename v9 secondary_number
rename v10 street
rename v11 locality
rename v12 city
rename v13 district

save "$WORKING/full_price_data.dta", replace

// USE SUBSET DATA FOR NOW
// use "$WORKING/price_data_subset.dta", clear

//Clean date
replace date = substr(date, 1, 7)
gen date2 = date(date, "YM")
format date2 %td
drop date
rename date2 date

// Remove whitespace
replace postcode = strtrim(stritrim(postcode))
replace house_number = strtrim(stritrim(house_number))

// Drop missing values
drop if postcode == ""
drop if house_number == ""
drop if duration == "U"
duplicates drop

// Generate property id
egen property_id = concat(secondary_number house_number postcode), punct(" ")
duplicates drop property_id date, force

// Create merge keys
egen merge_key_1 = concat(secondary_number house_number street city postcode), punct(" ")
replace merge_key_1 = upper(strtrim(stritrim(merge_key_1)))

egen merge_key_2 = concat(secondary_number house_number street locality city postcode), punct(" ")
replace merge_key_2 = upper(strtrim(stritrim(merge_key_2)))	
replace merge_key_2 = "" if locality==city | merge_key_1==merge_key_2

// Remove periods, commas and spaces
replace merge_key_1 = subinstr(merge_key_1,".","",.)
replace merge_key_1 = subinstr(merge_key_1,",","",.)
replace merge_key_1 = subinstr(merge_key_1," ","",.)

replace merge_key_2 = subinstr(merge_key_2,".","",.)
replace merge_key_2 = subinstr(merge_key_2,",","",.)
replace merge_key_2 = subinstr(merge_key_2," ","",.)


save "$WORKING/price_data.dta", replace

// For merge1:

drop if duration == "F"

preserve
rename merge_key_1 merge_key
keep property_id merge_key house_number secondary_number street locality city postcode duration
duplicates drop merge_key, force
save "$WORKING/price_data_for_merge1.dta", replace
restore

// For merge2:

preserve
rename merge_key_2 merge_key
keep property_id merge_key house_number secondary_number street locality city postcode
drop if missing(merge_key)
duplicates drop merge_key, force
save "$WORKING/price_data_for_merge2.dta", replace
restore
