global WORKING "`1'"

di "Working folder: $WORKING"

/////////////////////////////////////
// COMBINE PRICE DATA WITH AND WITHOUT POSTCODES
/////////////////////////////////////

use "$WORKING/merged_data_with_postcodes", clear
append using "$WORKING/merged_data_without_postcodes"
drop if missing(date_trans)
keep if _merge == 3

di "Number of merged observations:"
di _N

/////////////////////////////////////
// MERGE DATA INTO LEASE DATA
/////////////////////////////////////

// Merge back into lease data
cap drop _merge
joinby merge_key using "$WORKING/lease_data.dta"
save "$WORKING/merged_data.dta", replace

sort property_id date_trans date_registered
drop v16 unique_id merge_key* merge_num property_id_* dup* date
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
