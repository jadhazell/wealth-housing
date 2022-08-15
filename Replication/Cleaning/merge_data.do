
/////////////////////////////////////
// MERGE DATA WITH POSTCODES
/////////////////////////////////////

use "$WORKING/lease_data_for_merge.dta", clear
merge 1:1 merge_key using "$WORKING/price_data_for_merge1.dta"

// Save merged entries
preserve
	keep if _merge==3
	gen merge_num = 1
	keep merge_key property_id merge_num
	save "$WORKING/merge1.dta", replace
restore

preserve
	keep if _merge==2
	gen merge_num = 1
	save "$WORKING/unmerged_price_data_1.dta", replace
restore

keep if _merge==1
drop property_id

drop _merge
merge 1:1 merge_key using "$WORKING/price_data_for_merge2.dta"

preserve
	keep if _merge==3
	gen merge_num = 2
	keep merge_key property_id merge_num
	save "$WORKING/merge2.dta", replace
restore

preserve
	keep if _merge==2
	gen merge_num = 2
	save "$WORKING/unmerged_price_data_2.dta", replace
restore

// Store unmerged lease data for Python analysis	
preserve 
	keep if _merge == 1
	drop _merge
	save "$WORKING/unmerged_lease_data", replace
restore

// Store unmerged price data for Python analysis
use "$WORKING/unmerged_price_data_1.dta", clear
append using "$WORKING/unmerged_price_data_2.dta"
duplicates drop property_id, force
save "$WORKING/unmerged_price_data.dta", replace


// Combine first and second merge:
use "$WORKING/merge1.dta", clear
append using "$WORKING/merge2.dta"
save "$WORKING/merge_keys.dta", replace

// Combine with python merges:
import delimited "$WORKING/matched_with_python.csv", varnames(1) clear
save "$WORKING/matched_with_python.dta", replace
gen merge_num = 3
append using "$WORKING/merge_keys.dta"
sort property_id

// Deal with duplicates
duplicates drop
cap drop dup
duplicates tag property_id, gen(dup)

gen last_word = word(property_id, -1)
gen second_to_last_word = word(property_id, -2)
egen postcode = concat(second_to_last_word last_word), punct(" ")
drop last_word second_to_last_word

gen numbers = subinstr(property_id, postcode, "",.)
replace numbers = subinstr(numbers, " ", "", .)

// Of the  duplicates, keep the one that start with the street number
keep if dup==0 | (dup>0 & strpos(merge_key, numbers) == 1)

// For now, drop remaining duplicates (they seem to be referring to the same thing though...)
duplicates drop property_id, force
// duplicates drop merge_key, force

save "$WORKING/merge_keys.dta", replace


// Merge back into price data
use "$WORKING/merge_keys.dta", clear
merge 1:m property_id using "$WORKING/cleaned_price_data_leaseholds.dta"
save "$WORKING/merged_data_with_postcodes", replace

/////////////////////////////////////
// MERGE DATA WITHOUT POSTCODES
/////////////////////////////////////

// Get unmerged lease data
import delimited "$WORKING/matched_with_python.csv", varnames(1) clear
duplicates drop merge_key, force
merge 1:1 merge_key using "$WORKING/unmerged_lease_data.dta"
keep if _merge==2
drop _merge
save "$WORKING/unmerged_lease_data_for_no_postcode_cleaning.dta", replace

// Merge
import delimited "$WORKING/no_postcode_matched_with_python.csv", varnames(1) clear

// Deal with duplicate merges
gen property_id_no_spaces = subinstr(property_id," ","",.)
duplicates tag property_id, gen(dup)
keep if dup==0 | (dup>0 & strpos(merge_key, property_id_no_spaces) == 1)
duplicates drop property_id, force

duplicates report merge_key
// duplicates drop merge_key, force

// Merge back into price data
merge 1:m property_id using "$WORKING/cleaned_price_data_no_postcode_leaseholds.dta"
save "$WORKING/merged_data_without_postcodes", replace

/////////////////////////////////////
// COMBINE PRICE DATA WITH AND WITHOUT POSTCODES
/////////////////////////////////////

use "$WORKING/merged_data_with_postcodes", clear
append using "$WORKING/merged_data_without_postcodes"
drop if missing(date_trans)

/////////////////////////////////////
// MERGE DATA INTO LEASE DATA
/////////////////////////////////////

// Merge back into lease data
cap drop _merge
joinby merge_key using "$WORKING/lease_data.dta"
save "$WORKING/merged_data.dta", replace

// preserve
// 	keep if _merge==1
// 	keep postcode street street_number flat_number locality city property_id
// 	drop if missing(postcode)
// 	duplicates drop property_id, force
// 	sort postcode street street_number flat_number
//	
// 	merge m:1 property_id using "$WORKING/duplicate_merges.dta"
// 	drop if _merge!=1
//	
// 	export delimited "$WORKING/unmerged_price_post_python.csv", replace
// 	save "$WORKING/unmerged_price_post_python.dta", replace
// restore
//
// preserve
// 	keep if _merge==2
// 	keep description
// 	export delimited "$WORKING/unmerged_lease_post_python.csv", replace
// 	save "$WORKING/unmerged_lease_post_python.dta", replace
// restore

// Keep only merged data 
sort property_id date_trans date_registered

// We want to keep the registration date that most closely precedes each transaction
// Keep only observsations where the transaction date is the same or after the registration date 
keep if date_trans >= date_registered

// Pick most recent registration
by property_id date_trans, sort: egen most_recent_date_registered = max(date_registered)
format most_recent_date_registered %td
duplicates tag property_id date_trans, gen(dup)
keep if date_registered == most_recent_date_registered
drop most_recent_date_registered

// Merge back into full price data set

merge 1:1 property_id date_trans using "$WORKING/full_price_data.dta"

// Drop unnecessary vars
drop v16 unique_id merge_key* merge_num property_id_* dup* _merge date

save "$WORKING/full_merged_data.dta", replace
