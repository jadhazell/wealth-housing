global WORKING "`1'"

di "Working folder: $WORKING"

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
