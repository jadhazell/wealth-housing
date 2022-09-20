global DATA "`1'"
global WORKING "`2'"

di "Data folder: $DATA"
di "Working folder: $WORKING"

import delimited "$DATA/pp-complete.txt", clear

rename v1  unique_id
rename v2  price
rename v3  date
rename v4  postcode
rename v5  type
rename v6  new
rename v7  duration
rename v8  street_number
rename v9  flat_number
rename v10 street
rename v11 locality
rename v12 city
rename v13 district
rename v14 county
rename v15 record_status

// Clean date + aggregate at quarter level
replace date = substr(date,1,7)
gen date_trans = date(date,"YM")
gen  year = year(date_trans)
gen quarter = quarter(date_trans)
gen date_trans2 = year + (quarter-1)/4
drop date_trans
rename date_trans2 date_trans

// Clean address variables
foreach var of varlist postcode street_number flat_number street locality city district county {
	replace `var' = subinstr(`var',".","",.)
	replace `var' = subinstr(`var',",","",.)
	replace `var' = subinstr(`var',"'","",.)
	replace `var' = subinstr(`var'," - ","-",.)
	replace `var' = upper(strtrim(stritrim(`var')))
}

// Drop missing values
drop if missing(street_number) & missing(flat_number)

// Generate property id
egen property_id = concat(flat_number street_number postcode), punct(" ")
replace property_id = strtrim(stritrim(property_id))

// Create special property id if missing postcode
egen property_id_mp = concat(flat_number street_number street locality city), punct(" ") 
egen property_id_mp2 = concat(flat_number street_number street city), punct(" ")	
replace property_id_mp = property_id_mp2 if locality == city
replace property_id_mp = strtrim(stritrim(property_id_mp))
replace property_id = property_id_mp if missing(postcode)

// Drop if unknown property duration
drop if duration == "U"

compress
save "$WORKING/pp-complete.dta", replace
use "$WORKING/pp-complete.dta", clear

// Combine property ids that should belong to the same property:
egen address_no_spaces = concat(flat_number street_number street city postcode), punct(" ")
replace address_no_spaces = upper(strtrim(stritrim(address_no_spaces)))
replace address_no_spaces = subinstr(address_no_spaces," ","",.)
duplicates tag property_id, gen(dup)
duplicates tag address_no_spaces, gen(dup_no_spaces)
by address_no_spaces, sort: egen property_id_corrected_no_spaces = mode(property_id), max

gen first_char = substr(street_number,1,1)
gen first_char_is_numeric = real(first_char)!=.

replace property_id = property_id_corrected_no_spaces if dup_no_spaces>0 & dup==0 & !first_char_is_numeric

drop dup* property_id_corrected* address*

//////////////////////////////////////
// Investigate and drop duplicates
//////////////////////////////////////
duplicates drop

// For each duplicates in terms of property_id and date (not counting descriptive vars), keep only one
gsort property_id -locality -street -city // Prioritize data that is not missing locality
duplicates drop date_trans price type new duration property_id, force
// Drop all instances where there are multiple prices/types/new labels/durations for one property_id-date pair
// Price
duplicates tag date_trans type new duration property_id, gen(dup_price)
// browse date_trans property_id duration price type new if dup_price > 0
drop if dup_price > 0
// Type
duplicates tag date_trans new duration property_id, gen(dup_type)
// browse date_trans property_id duration price type new if dup_type > 0
drop if dup_type > 0
// New
duplicates tag date_trans duration property_id, gen(dup_new)
// browse date_trans property_id duration price type new if dup_new > 0
drop if dup_new > 0
// Duration
duplicates tag date_trans property_id, gen(dup_duration)
// browse date_trans property_id duration price type new if dup_duration > 0
drop if dup_duration > 0

save "$WORKING/full_price_data.dta", replace

use "$WORKING/full_price_data.dta", clear
preserve
	gsort property_id -street -locality -city // Prioritize data that is not missing
	duplicates drop property_id, force
	save "$WORKING/full_price_data_unique.dta", replace
restore


preserve
	keep if duration == "F"
	save "$WORKING/price_data_freeholds.dta", replace
restore
	

drop if duration == "F"
save "$WORKING/price_data_leaseholds.dta", replace

// Save data without postcodes -- we will deal with this separately
preserve 
	keep if missing(postcode)
	save "$WORKING/cleaned_price_data_no_postcode_leaseholds.dta", replace 
	duplicates drop property_id, force
	save "$WORKING/cleaned_price_data_no_postcode_leaseholds_unique.dta", replace 
restore

// Drop entries with missing postcode values
drop if postcode == ""

// Create merge keys
egen merge_key_1 = concat(flat_number street_number street city postcode), punct(" ")
replace merge_key_1 = upper(strtrim(stritrim(merge_key_1)))

egen merge_key_2 = concat(flat_number street_number street locality city postcode), punct(" ")
replace merge_key_2 = upper(strtrim(stritrim(merge_key_2)))	
replace merge_key_2 = "" if locality==city | merge_key_1==merge_key_2

// // Remove spaces
// replace merge_key_1 = subinstr(merge_key_1," ","",.)
// replace merge_key_2 = subinstr(merge_key_2," ","",.)

save "$WORKING/cleaned_price_data_leaseholds.dta", replace

// Keep only one entry per property_id
gsort property_id -street -locality -city // Prioritize data that is not missing
duplicates drop property_id, force

save "$WORKING/price_data.dta", replace

// For merge1:

preserve
	rename merge_key_1 merge_key
	keep property_id merge_key flat_number street_number street locality city postcode duration
	duplicates drop merge_key, force
	save "$WORKING/price_data_for_merge1.dta", replace
restore

// For merge2:

preserve
	rename merge_key_2 merge_key
	keep property_id merge_key flat_number street_number street locality city postcode
	drop if missing(merge_key)
	duplicates drop merge_key, force
	save "$WORKING/price_data_for_merge2.dta", replace
restore
