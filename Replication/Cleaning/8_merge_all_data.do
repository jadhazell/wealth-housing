global WORKING "`1'"

di "Working folder: $WORKING"

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

// Store unmerged data in case we want to review it later on
preserve
	keep if _merge==1
	keep postcode street street_number flat_number locality city property_id
	drop if missing(postcode)
	duplicates drop property_id, force
	sort postcode street street_number flat_number
	
	merge m:1 property_id using "$WORKING/duplicate_merges.dta"
	drop if _merge!=1
	
	export delimited "$WORKING/unmerged_price_post_python.csv", replace
	save "$WORKING/unmerged_price_post_python.dta", replace
restore

preserve
	keep if _merge==2
	keep description
	export delimited "$WORKING/unmerged_lease_post_python.csv", replace
	save "$WORKING/unmerged_lease_post_python.dta", replace
restore

sort property_id date_trans date_registered
drop v16 unique_id merge_key* merge_num property_id_* dup* date

////////////////////////////////////////////
// Aggregate at quarter level
////////////////////////////////////////////

gen  year          = year(date_trans)
gen quarter = quarter(date_trans)

gen date_trans2 = year + (quarter-1)/4
drop date_trans
rename date_trans2 date_trans

gen quarter_registered = quarter(date_registered)
gen year_registered = year(date_registered)
gen date_registered2 = year_registered + (quarter_registered-1)/4
drop date_registered quarter_registered year_registered
rename date_registered2 date_registered
duplicates drop property_id date_trans date_registered, force

// We want to keep the registration date that most closely precedes each transaction
// Keep only observsations where the transaction date is the same or after the registration date 
keep if date_trans >= date_registered

// Pick most recent registration
by property_id date_trans, sort: egen most_recent_date_registered = max(date_registered)
format most_recent_date_registered %td
keep if date_registered == most_recent_date_registered
drop most_recent_date_registered

// Merge back into full price data set

merge 1:1 property_id date_trans using "$WORKING/full_price_data.dta"
drop _merge

save "$WORKING/full_merged_data.dta", replace
