use "$WORKING/full_merged_data.dta", clear
sort property_id date_trans

////////////////////////////////////////////
// Aggregate at quarter level
////////////////////////////////////////////

gen  year          = year(date_trans)
gen month		   = month(date_trans)
gen quarter = quarter(date_trans)

gen date_trans2 = year + (quarter-1)/4
drop date_trans
rename date_trans2 date_trans

gen quarter_registered = quarter(date_registered)
gen year_registered = year(date_registered)
gen date_registered2 = year_registered + (quarter_registered-1)/4
drop date_registered
rename date_registered2 date_registered

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

save "$WORKING/full_cleaned_data.dta", replace

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

// Keep only observations that record change over time (this will delete all properties for which we only have on observation)
drop if missing(L_date_trans)
drop if leasehold & missing(date_registered)
drop if leasehold & missing(L_date_registered)

// Generate differenced variables
gen d_price = price - L_price
gen d_log_price = 100*(log(price) - log(L_price))

gen d_interest_rate = interest_rate - L_interest_rate
gen d_log_interest_rate = log(interest_rate) - log(L_interest_rate)

gen years_held = date_trans - L_date_trans

// Generate x_tiles of purchase price 
xtile price_quintile = L_price, nq(5)
xtile price_ventile = L_price, nq(20)

// Classify leaseholds as above and below median
egen med_lease_duration_at_sale = median(lease_duration_at_transaction) if leasehold
egen med_lease_duration_at_purchase = median(L_lease_duration_at_transaction) if leasehold

xtile duration_at_sale_n = lease_duration_at_transaction, nq(2)
replace duration_at_sale_n = 3 if !leasehold

xtile duration_at_purchase_n = L_lease_duration_at_transaction, nq(2)
replace duration_at_purchase_n = 3 if !leasehold

// gen duration_at_sale = "F" if !leasehold
// gen duration_at_purchase = "F" if !leasehold
//
// replace duration_at_sale = "SL" if leasehold & lease_duration_at_transaction < med_lease_duration_at_sale
// replace duration_at_sale = "LL" if leasehold & lease_duration_at_transaction >= med_lease_duration_at_sale
//
// replace duration_at_purchase = "SL" if leasehold & L_lease_duration_at_transaction < med_lease_duration_at_purchase
// replace duration_at_purchase = "LL" if leasehold & L_lease_duration_at_transaction >= med_lease_duration_at_purchase
//
// gen duration_at_sale_n = 1 if duration_at_sale=="SL"
// replace duration_at_sale_n = 2 if duration_at_sale=="LL"
// replace duration_at_sale_n = 3 if duration_at_sale=="F"
//
// gen duration_at_purchase_n = 1 if duration_at_purchase=="SL"
// replace duration_at_purchase_n = 2 if duration_at_purchase=="LL"
// replace duration_at_purchase_n = 3 if duration_at_purchase=="F"

save "$WORKING/full_cleaned_data_diff_restricted.dta", replace
