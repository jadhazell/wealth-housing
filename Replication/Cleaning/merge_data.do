
use "$WORKING/lease_data_for_merge.dta", clear
merge 1:1 merge_key using "$WORKING/price_data_for_merge1.dta"

// Save merged entries
preserve
	keep if _merge==3
	gen merge_num = 1
	keep merge_key property_id merge_num
	save "$WORKING/merge1.dta", replace
restore

keep if _merge==1
drop property_id
save "$WORKING/unmerged1.dta", replace

drop _merge
merge 1:1 merge_key using "$WORKING/price_data_for_merge2.dta"

preserve
	keep if _merge==3
	gen merge_num = 2
	keep merge_key property_id merge_num
	save "$WORKING/merge2.dta", replace
restore
	
keep if _merge!=3
save "$WORKING/unmerged.dta", replace

// Combine first and second merge:
use "$WORKING/merge1.dta", clear
append using "$WORKING/merge2.dta"
save "$WORKING/merge_keys.dta", replace

// Merge back into lease data
use "$WORKING/merge_keys.dta", clear
merge 1:m merge_key using "$WORKING/lease_data.dta"

// Merge lease data back into price data
drop _merge
merge m:m property_id using "$WORKING/price_data.dta"
save "$WORKING/merged_data", replace
