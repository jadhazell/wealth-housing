use "$WORKING/merged_data.dta", clear

// Keep only merged data 
keep if _merge == 3
sort property_id date_trans date_registered

// Drop unnecessary variabes
drop _merge merge_num merge_key unique_id property_id_* dup* numbers v16

// Leasehold indicator
gen leasehold = (duration == "L")

// We want to keep the registration date that most closely precedes each transaction
// Keep only observsations where the transaction date is the same or after the registration date 
keep if date_trans >= date_registered
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
	
********************************************************************
* CREATE SOME MORE VARIABLES THAT WE WILL USE LATER
********************************************************************

gen  log_price     = log(price)
gen  month_of_sale = mofd(date_trans)
gen  year          = year(date_trans)
gen month		   = month(date_trans)
gen  quarter       = qofd(date_trans)
egen proptype      = group(type)
gen  is_flat       = (type=="F")

winsor log_price, gen(log_price_win) p(0.05)

// Isolate each component of postcode

gen pos_empty   = strpos(postcode," ")
gen post_0      = substr(postcode,1,pos_empty)
gen post_2      = substr(postcode,1,pos_empty+2)
replace post_0  = trim(post_0)
drop pos_empty

// Fixed effects for regressions
egen fe_12   = group(post_0  year    proptype)
egen fe_12_q = group(post_0  quarter proptype)
egen fe_12_m = group(post_0  month   proptype)

compress
cap drop _merge

// Merge with interest rate data
merge m:1 year month using "$WORKING/interest_rates.dta"

save "$WORKING/full_cleaned_data.dta", replace
