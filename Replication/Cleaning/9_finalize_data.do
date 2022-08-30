global WORKING "`1'"
global OUTPUT "`2'"

di "Working folder: $WORKING"
di "Output folder: $OUTPUT"

use "$WORKING/full_merged_data.dta", clear

////////////////////////////////////////////
// Generate useful variables
////////////////////////////////////////////

// Calculate information about lease term at each date
// Record lease term at time of transactions
gen years_elapsed_at_trans = date_trans - date_registered
gen lease_duration_at_trans = number_years - years_elapsed_at_trans

// Leasehold indicator
gen leasehold = (duration == "L")

////////////////////////////////////////////
// Drop missing data
////////////////////////////////////////////

// Drop leaseholds with no lease length information 
drop if leasehold & missing(date_registered)

// Drop if property changes from leasehold to freehold at some point
duplicates tag property_id, gen(dup_pid)
duplicates tag property_id duration, gen(dup_pid_dur)

gen no_match = dup_pid != dup_pid_dur
egen switches_duration = total(no_match), by(property_id)

drop if switches_duration

drop dup* switches_duration no_match

// Drop if remaining lease duration is zero or negative
drop if lease_duration_at_trans <= 0

////////////////////////////////////////////
// Generate more useful variables
////////////////////////////////////////////

// Isolate first component of postcode
gen pos_empty   = strpos(postcode," ")
gen location      = substr(postcode,1,pos_empty)
replace location  = trim(location)
drop pos_empty
drop if missing(location)

// Make string factor variables numeric
egen location_n = group(location)
egen type_n = group(type)

// Winsorize price
winsor price, p(0.01) gen(price_win)

// Gen log price 
gen log_price = log(price)
gen log_price_win = log(price_win)

// Get lease duration centiles
xtile duration_centiles = lease_duration_at_trans, nq(100)

// Merge with interest rate data
cap drop _merge
merge m:1 year quarter using "$WORKING/interest_rates.dta"
keep if _merge==3
drop _merge

save "$OUTPUT/full_cleaned_data.dta", replace

////////////////////////////////////////////////////////////////////////////
// We are primarily interested in the change in price between transactions
// Generate logs of variables and collapse observations by date purchase/date sale
////////////////////////////////////////////////////////////////////////////
use "$OUTPUT/full_cleaned_data.dta", clear

//Generate lagged variables
sort property_id date_trans
by property_id: gen L_date_trans = date_trans[_n-1]
by property_id: gen L_price = price[_n-1]
by property_id: gen L_price_win = price_win[_n-1]
by property_id: gen L_interest_rate = interest_rate[_n-1]
by property_id: gen L_years_elapsed_at_trans = years_elapsed_at_trans[_n-1]
by property_id: gen L_lease_duration_at_trans = lease_duration_at_trans[_n-1]
by property_id: gen L_date_registered = date_registered[_n-1]
by property_id: gen L_number_years = number_years[_n-1]
by property_id: gen L_number_years_missing = number_years_missing[_n-1]
by property_id: gen L_number_years_partial_missing = number_years_partial_missing[_n-1]

save "$OUTPUT/full_cleaned_data_with_lags.dta", replace

// Keep only observations that record change over time (this will delete all properties for which we only have on observation)
drop if missing(L_date_trans)

// Tag data for which the lease was extended half way through the ownership
gen lease_was_extended = 0
replace lease_was_extended = 1 if leasehold & date_registered != L_date_registered

// Generate differenced variables
gen d_price = price - L_price
gen d_log_price = 100*(log(price) - log(L_price))

gen d_price_win = price_win - L_price_win
gen d_log_price_win = 100*(log(price_win) - log(L_price_win))

gen d_interest_rate = interest_rate - L_interest_rate
gen d_log_interest_rate = log(interest_rate) - log(L_interest_rate)

gen years_held = date_trans - L_date_trans

//////////////////////////////////////////////////////////
// Classify data into percentiles:
/////////////////////////////////////////////////////////////

// (1) Data with lease extensions:
// Generate x_tiles of purchase price 
xtile price_quintile = L_price, nq(5) 
xtile price_ventile = L_price, nq(20)

// Classify leaseholds by x-tile
xtile bucket_3_sale = lease_duration_at_trans, nq(2)
replace bucket_3_sale = 3 if !leasehold
replace bucket_3_sale = 4 if lease_was_extended // flag data for which lease was extended as different

xtile bucket_6_sale = lease_duration_at_trans, nq(5)
replace bucket_6_sale = 6 if !leasehold
replace bucket_6_sale = 7 if lease_was_extended

xtile bucket_11_sale = lease_duration_at_trans, nq(10)
replace bucket_11_sale = 11 if !leasehold
replace bucket_11_sale = 12 if lease_was_extended

save "$OUTPUT/final_data_with_extensions.dta", replace

// (2) Drop data with extensions
drop if lease_was_extended
drop price_quintile price_ventile bucket_*
count

// Generate x_tiles of purchase price 
xtile price_quintile = L_price, nq(5) 
xtile price_ventile = L_price, nq(20)

// Classify leaseholds by x-tile
xtile bucket_3_sale = lease_duration_at_trans, nq(2)
replace bucket_3_sale = 3 if !leasehold

xtile bucket_6_sale = lease_duration_at_trans, nq(5)
replace bucket_6_sale = 6 if !leasehold

xtile bucket_11_sale = lease_duration_at_trans, nq(10)
replace bucket_11_sale = 11 if !leasehold

// Classify data into five year periods (based on purchase data, sale date, and halfway point)
gen purchase = L_date_trans
gen sale = date_trans
gen half_way = (purchase + sale)/2
foreach var of varlist purchase half_way sale {
	gen year_bucket_`var' = "1995-2000" if `var' >= 1995 & `var' < 2000
	replace year_bucket_`var' = "2000-2005" if `var' >= 2000 & `var' < 2005
	replace year_bucket_`var' = "2005-2010" if `var' >= 2005 & `var' < 2010
	replace year_bucket_`var' = "2010-2015" if `var' >= 2010 & `var' < 2015
	replace year_bucket_`var' = "2015-2020" if `var' >= 2015 & `var' < 2020
	replace year_bucket_`var' = "2020+" if `var' >= 2020
}

count

save "$OUTPUT/final_data.dta", replace
