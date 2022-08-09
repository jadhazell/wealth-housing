
import delimited "$DATA/pp-complete.txt", clear

duplicates drop

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

//Clean date
gen     length_date = length(date)
replace date = substr(date,1,length(date)-5) if length_date == 16
replace date = substr(date,1,length(date)-8) if length_date == 19
replace date = subinstr(date,"/","-",.)

gen     date_trans = date(date,"DMY")
replace date_trans = date(date,"YMD") if date_trans == .
replace date       = substr(date,1,length(date)-2) + "20" + substr(date,length(date)-1,.) if date_trans == .
replace date_trans = date(date,"DMY") if date_trans == .
format  date_trans %td

drop length_date date

// Clean address variables
foreach var of varlist postcode street_number flat_number street locality city district county {
	replace `var' = subinstr(`var',".","",.)
	replace `var' = subinstr(`var',",","",.)
	replace `var' = subinstr(`var',"'","",.)
	replace `var' = upper(strtrim(stritrim(`var')))
}

// Generate property id
egen property_id = concat(flat_number street_number postcode), punct(" ")
replace property_id = strtrim(stritrim(property_id))

// Drop if unknown property duration
drop if duration == "U"

//////////////////////////////////////
// Investigate and drop duplicates
//////////////////////////////////////

// For each duplicates in terms of property_id and date (not counting descriptive vars), keep only one
gsort -locality // Prioritize data that is not missing locality
duplicates drop date_trans price type new duration property_id, force

sort postcode city street street_number flat_number 
// Drop all instances where there are multiple prices/types/new labels/durations for one property_id-date pair
// Price
duplicates tag date_trans type new duration property_id, gen(dup_price)
browse if dup_price > 0
drop if dup_price > 0
// Type
duplicates tag date_trans new duration property_id, gen(dup_type)
browse if dup_type > 0
drop if dup_type > 0
// New
duplicates tag date_trans duration property_id, gen(dup_new)
browse if dup_new > 0
drop if dup_new > 0
// Duration
duplicates tag date_trans property_id, gen(dup_duration)
browse if dup_duration > 0
drop if dup_duration > 0

save "$WORKING/full_price_data.dta", replace

drop if duration == "F"
save "$WORKING/price_data_leaseholds.dta", replace

// Save data without postcodes -- we will deal with this separately
preserve 
	keep if missing(postcode)
	
	drop property_id
	
	egen property_id = concat(flat_number street_number street locality city), punct(" ") 
	egen property_id2 = concat(flat_number street_number street city), punct(" ")	
	replace property_id = property_id2 if locality == city
	replace property_id = subinstr(property_id,".","",.)
	replace property_id = subinstr(property_id,",","",.)
	replace property_id = upper(strtrim(stritrim(property_id)))
	duplicates drop date property_id, force
	save "$WORKING/cleaned_price_data_no_postcode_leaseholds_unique.dta", replace 
	duplicates drop property_id, force
	save "$WORKING/cleaned_price_data_no_postcode_leaseholds.dta", replace 
restore

// Drop entries with missing postcode values
drop if postcode == ""

save "$WORKING/cleaned_price_data_leaseholds.dta", replace

// Keep only one entry per property_id
duplicates drop property_id, force

// Create merge keys
egen merge_key_1 = concat(flat_number street_number street city postcode), punct(" ")
replace merge_key_1 = upper(strtrim(stritrim(merge_key_1)))

egen merge_key_2 = concat(flat_number street_number street locality city postcode), punct(" ")
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
