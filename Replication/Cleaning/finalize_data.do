use "$WORKING/merged_data.dta", clear

// Keep only merged data 
drop if missing(date_trans) | missing(date_registered)
sort property_id date_trans date_registered

// Drop unnecessary variabes
drop merge_num merge_key* unique_id property_id_* dup* numbers v16

// We want to keep the registration date that most closely precedes each transaction
// Keep only observsations where for at least one date in the time period, the transaction date is the same or after the registration date 
gen transaction_after_registration = date_trans >= date_registered
by property_id, sort: egen temp = total(transaction_after_registration)
drop if temp == 0

by property_id date_trans, sort: egen most_recent_date_registered = max(date_registered)
format most_recent_date_registered %td
duplicates tag property_id date_trans, gen(dup)
keep if date_registered == most_recent_date_registered
drop most_recent_date_registered

// Record time elapsed since start of date
gen years_elapsed = round((date_trans - date_registered)/365)

// Record lease term at time of transactions
gen number_years_at_trans = number_years - years_elapsed
replace number_years_at_trans = . if number_years_at_trans < 0

// Combine with freehold data
append using "$WORKING/price_data_freeholds.dta"
	
// Leasehold indicator
gen leasehold = (duration == "L")

// Useful variables
gen  year          = year(date_trans)
gen month		   = month(date_trans)

// Isolate each component of postcode
gen pos_empty   = strpos(postcode," ")
gen location      = substr(postcode,1,pos_empty)
replace location  = trim(location)
drop pos_empty

// Make string factor variables numeric
egen location_n = group(location)
egen type_n = group(type)

compress
cap drop _merge

// Merge with interest rate data
merge m:1 year month using "$WORKING/interest_rates.dta"
keep if _merge==3
drop _merge
drop dup*

save "$WORKING/full_cleaned_data.dta", replace

///////////////////////////////////////////////////
// We are primarily interested in the change in price between transactions
///////////////////////////////////////////////////

//Log change in price 
sort property_id date_trans
by property_id: gen L_date_trans = date_trans[_n-1]
by property_id: gen L_price = price[_n-1]
by property_id: gen L_interest_rate = interest_rate[_n-1]

format L_date_trans %td

// Keep only observations that record change over time (this will delete all properties for which we only have on observation)
drop if missing(L_date_trans)

// Generate more variables of
gen d_price = price - L_price
gen d_log_price = log(price) - log(L_price)

gen d_interest_rate = interest_rate - L_interest_rate
gen d_log_interest_rate = log(interest_rate) - log(L_interest_rate)

gen years_held = round((date_trans - L_date_trans)/365, 0.01)

gen quarter_purchase = quarter(L_date_trans)
gen quarter_sale = quarter(date_trans)

// Tag leaseholds as above or below median term length
egen med_term_lendth = median(number_years_at_trans)
replace duration = "SL" if leasehold & number_years_at_trans < med_term_lendth
replace duration = "LL" if leasehold & number_years_at_trans >= med_term_lendth
 

save "$WORKING/full_cleaned_data_diff.dta", replace
