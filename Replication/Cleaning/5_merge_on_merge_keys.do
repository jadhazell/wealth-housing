global WORKING "`1'"

di "Working folder: $WORKING"

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
