global WORKING "`1'"

di "Working folder: $WORKING"

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

// Get unmerged lease data for more python analysis
import delimited "$WORKING/matched_with_python.csv", varnames(1) clear
duplicates drop merge_key, force
merge 1:1 merge_key using "$WORKING/unmerged_lease_data.dta"
keep if _merge==2
drop _merge
save "$WORKING/unmerged_lease_data_for_no_postcode_cleaning.dta", replace
