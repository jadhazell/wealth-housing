import delimited "$DATA/LEASES_FULL_2022_06.csv", clear
save "$WORKING/full_lease_data.dta",replace

// USE SUBSET FOR NOW
// use "$WORKING/lease_data_subset.dta", clear

rename associatedpropertydescription property_description
rename dateoflease lease_date
keep property_description date term

// // Clean information on term
// replace term = strtrim(stritrim(lower(term)))
// drop if missing(term)
// // Remove strange characters
// replace term = subinstr(term,"¨","",.)
// replace term = subinstr(term,"´","",.)
// replace term = subinstr(term,"~","",.)
//
//
// // Clean date
// replace date = substr(date, 4, 7)
// gen date2 = date(date, "MY")
// format date2 %td
// drop date
// rename date2 date

////////////////////////////////////////////
// Make merge key
////////////////////////////////////////////

gen merge_key = strtrim(stritrim(upper(property_description)))
drop if missing(merge_key)

//Remove commas/periods
replace merge_key = subinstr(merge_key,".","",.)
replace merge_key = subinstr(merge_key,",","",.)
replace merge_key = subinstr(merge_key," ","",.)

//Drop missing entries
drop if missing(merge_key)

//Drop duplicates
duplicates drop
duplicates drop merge_key date, force // Eventually need to deal with these duplicates

//Create second merge key for merging with price data

save "$WORKING/lease_data.dta", replace

// For merge:

keep merge_key term
duplicates drop merge_key, force
save "$WORKING/lease_data_for_merge.dta", replace
