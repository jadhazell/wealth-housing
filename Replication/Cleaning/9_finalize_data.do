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
gen lease_duration_at_trans = number_years - years_elapsed_at_transaction
	
// Leasehold indicator
gen leasehold = (duration == "L")

// Isolate first component of postcode
gen pos_empty   = strpos(postcode," ")
gen location      = substr(postcode,1,pos_empty)
replace location  = trim(location)
drop pos_empty

// Make string factor variables numeric
egen location_n = group(location)
egen type_n = group(type)

// Merge with interest rate data
cap drop _merge
merge m:1 year quarter using "$WORKING/interest_rates.dta"
keep if _merge==3
drop _merge

xtile bucket_3 = lease_duration_at_trans, nq(2)
replace bucket_3 = 3 if !leasehold

save "$OUTPUT/full_cleaned_data.dta", replace

////////////////////////////////////////////////////////////////////////////
// We are primarily interested in the change in price between transactions
// Generate logs of variables and collapse observations by date purchase/date sale
////////////////////////////////////////////////////////////////////////////

//Generate lagged variables
sort property_id date_trans
by property_id: gen L_date_trans = date_trans[_n-1]
by property_id: gen L_price = price[_n-1]
by property_id: gen L_interest_rate = interest_rate[_n-1]
by property_id: gen L_years_elapsed_at_transaction = years_elapsed_at_transaction[_n-1]
by property_id: gen L_lease_duration_at_transaction = lease_duration_at_transaction[_n-1]
by property_id: gen L_date_registered = date_registered[_n-1]
by property_id: gen L_number_years = number_years[_n-1]

// Keep only observations that record change over time (this will delete all properties for which we only have on observation)
drop if missing(L_date_trans)
drop if leasehold & missing(date_registered)

// We are also interested in restricting the sample bassed on:
	// (1) Observations for which the purchase does not have lease information
	// (2) Observations for which the lease is extended half way through the ownership

// (1) Tag data for which the purchase does not have lease information
gen has_purchase_lease = 1
replace has_purchase_lease = 0 if leasehold & missing(L_date_registered)

// For now, drop observations for which we do not have purchase lease information
drop if !has_purchase_lease

// (2) Tag data for which the lease was extended half way through the ownership
gen lease_was_extended = 0
replace lease_was_extended = 1 if leasehold & has_purchase_lease & date_registered != L_date_registered

// Generate differenced variables
gen d_price = price - L_price
gen d_log_price = 100*(log(price) - log(L_price))

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

save "$OUTPUT/final_data.dta", replace
