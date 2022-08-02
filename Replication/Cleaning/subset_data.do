
import delimited "$DATA/pp-complete.txt", clear
keep postcode
duplicates drop
save "$WORKING/postcodes.dta", replace

// Chose a subset of postcodes
gen random = runiform()
sort random
keep if _n <= 1000
save "$WORKING/postcodes_subset.dta", replace

// Get corresponding subset of price data
use "$WORKING/postcodes_subset.dta", clear
merge 1:m postcode using "$WORKING/full_price_data.dta"
keep if _merge==3
drop random _merge
save "$WORKING/price_data_subset.dta", replace

// Get corresponding subset of lease data

// First must generate postcode in lease data
use "$WORKING/full_lease_data.dta", clear
// Get last two words:
gen last_word = word(associatedpropertydescription, -1)
gen second_to_last_word = word(associatedpropertydescription, -2)
egen postcode = concat(second_to_last_word last_word), punct(" ")
gen str_length = strlen(postcode)
drop if str_length > 7

merge m:1 postcode using "$WORKING/postcodes_subset.dta"
keep if _merge==3
drop random _merge str_length
save "$WORKING/price_data_subset.dta", replace
