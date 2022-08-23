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
gen years_elapsed_at_transaction = date_trans - date_registered
gen lease_duration_at_transaction = number_years - years_elapsed_at_transaction
	
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
// Create percentiles for three categories: 
// (1) All data (including data with no lease information in lagged period)
// (2) Excluding data with no lease information in lagged period
// (3) Like (2) but also excluding data where lease was extended half way through ownership
/////////////////////////////////////////////////////////////

// (1) All data:
rename lease_duration_at_transaction lease_duration_at_trans_all
rename L_lease_duration_at_transaction L_lease_duration_at_trans_all

// Generate x_tiles of purchase price 
xtile price_quintile_all = L_price, nq(5)
xtile price_ventile_all = L_price, nq(20)

// // Classify leaseholds by x-tile
// xtile bucket_3_sale_all = lease_duration_at_trans_all, nq(2)
// replace bucket_3_sale_all = 3 if !leasehold
//
// xtile bucket_3_purchase_all = L_lease_duration_at_trans_all, nq(2)
// replace bucket_3_purchase_all = 3 if !leasehold
//
// xtile bucket_6_sale_all = lease_duration_at_trans_all, nq(5)
// replace bucket_6_sale_all = 6 if !leasehold
//
// xtile bucket_6_purchase_all = L_lease_duration_at_trans_all, nq(5)
// replace bucket_6_purchase_all = 6 if !leasehold

// (2) Repeat but excluding data that is missing purchase lease duration 
// Generate x_tiles of purchase price 
gen L_price_has_purchase_lease = L_price 
replace L_price_has_purchase_lease = . if !has_purchase_lease

xtile price_quintile = L_price_has_purchase_lease, nq(5) 
xtile price_ventile = L_price_has_purchase_lease, nq(20)

// Classify leaseholds by x-tile
gen lease_duration_at_trans = lease_duration_at_trans_all
replace lease_duration_at_trans = .  if !has_purchase_lease

gen L_lease_duration_at_trans = L_lease_duration_at_trans_all
replace L_lease_duration_at_trans = .  if !has_purchase_lease

xtile bucket_3_sale = lease_duration_at_trans, nq(2)
replace bucket_3_sale = 3 if !leasehold
replace bucket_3_sale = 4 if lease_was_extended // flag data for which lease was extended as different

xtile bucket_3_purchase = L_lease_duration_at_trans, nq(2)
replace bucket_3_purchase = 3 if !leasehold
replace bucket_3_purchase = 4 if lease_was_extended // flag data for which lease was extended as different

xtile bucket_6_sale = lease_duration_at_trans, nq(5)
replace bucket_6_sale = 6 if !leasehold
replace bucket_6_sale = 7 if lease_was_extended

xtile bucket_6_purchase = L_lease_duration_at_trans, nq(5)
replace bucket_6_purchase = 6 if !leasehold
replace bucket_6_purchase = 7 if lease_was_extended

xtile bucket_11_sale = lease_duration_at_trans, nq(10)
replace bucket_11_sale = 11 if !leasehold
replace bucket_11_sale = 12 if lease_was_extended

xtile bucket_11_purchase = L_lease_duration_at_trans, nq(10)
replace bucket_11_purchase = 11 if !leasehold
replace bucket_11_purchase = 12 if lease_was_extended

// // (3) Repeat but excluding data where lease is extended (nr = not extended)
// // Generate x_tiles of purchase price 
// gen L_price_no_ext = L_price_has_purchase_lease 
// replace L_price_no_ext = . if lease_was_extended
//
// xtile price_quintile_no_ext = L_price_no_ext, nq(5)
// xtile price_ventile_no_ext = L_price_no_ext, nq(20)
//
// // Classify leaseholds by x-tile
// gen lease_duration_at_trans_no_ext = lease_duration_at_trans
// replace lease_duration_at_trans_no_ext = .  if lease_was_extended
//
// gen L_lease_duration_at_trans_no_ext = L_lease_duration_at_trans
// replace L_lease_duration_at_trans_no_ext = .  if lease_was_extended
//
// xtile bucket_3_sale_no_ext = lease_duration_at_trans_no_ext, nq(2) 
// replace bucket_3_sale_no_ext = 3 if !leasehold 
//
// xtile bucket_3_purchase_no_ext = L_lease_duration_at_trans_no_ext, nq(2)
// replace bucket_3_purchase_no_ext = 3 if !leasehold
//
// xtile bucket_6_sale_no_ext = lease_duration_at_trans_no_ext, nq(5)
// replace bucket_6_sale_no_ext = 6 if !leasehold
//
// xtile bucket_6_purchase_no_ext = L_lease_duration_at_trans_no_ext, nq(5)
// replace bucket_6_purchase_no_ext = 6 if !leasehold

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
