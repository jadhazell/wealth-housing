global WORKING "`1'"
global OUTPUT "`2'"

// global tag "_hedonic"
global tag ""

di "Working folder: $WORKING"
di "Output folder: $OUTPUT"

use "$WORKING/full_merged_data.dta", clear

* Merge with interest rate data
cap drop _merge
merge m:1 year quarter using "$WORKING/interest_rates.dta"
keep if _merge==3
drop _merge

if "$tag" == "_hedonic" {
	* Merge with hedonic characteristics
	cap drop _merge
	merge 1:1 property_id date_trans using  "$WORKING/matched_hedonic_characteristics_by_year.dta"
	drop _merge
}
	
save "$OUTPUT/full_data$tag.dta", replace
																																  
********************************************
* Generate useful variables
********************************************

* Leasehold indicator
gen leasehold = (duration == "L")
gen freehold = !leasehold

* Calculate information about lease term at each date
* Record lease term at time of transactions
gen years_elapsed_at_trans = date_trans - date_registered
gen lease_duration_at_trans = number_years - years_elapsed_at_trans

* Give freeholds a duration so that they are counted
replace lease_duration_at_trans = 0 if freehold
* Normalize duration to be in 1000s of years
replace lease_duration_at_trans = lease_duration_at_trans/1000

* Isolate first component of postcode
gen pos_empty   = strpos(postcode," ")
gen location      = substr(postcode,1,pos_empty)
replace location  = trim(location)
drop pos_empty
drop if missing(location)

* Make string factor variables numeric
egen location_n = group(location)
egen type_n = group(type)
egen postcode_n = group(postcode)
egen property_id_n = group(property_id)
egen new_n = group(new)
egen district_n = group(district)
egen city_n = group(city)
gen flat = type == "F" 

* Winsorize price
winsor price, p(0.01) gen(price_win)

* Gen log price 
gen log_price = log(price)
gen log_price_win = log(price_win)

* Create price quintile information by year 
egen price_quint_group=xtile(price), n(5) by(date_trans district_n)
egen price_dec_group=xtile(price), n(10) by(date_trans district_n)

********************************************
* Drop missing and incoherent data
********************************************

* Drop leaseholds with no lease length information 
drop if leasehold & missing(date_registered)

* Drop if property changes from leasehold to freehold at some point
duplicates tag property_id, gen(dup_pid)
duplicates tag property_id duration, gen(dup_pid_dur)

gen no_match = dup_pid != dup_pid_dur
egen switches_duration = total(no_match), by(property_id)

drop if switches_duration

drop dup* switches_duration no_match

* Drop if remaining lease duration is zero or negative
drop if lease_duration_at_trans <= 0

save "$OUTPUT/full_cleaned_data$tag.dta", replace

**************************************
* We are primarily interested in the change in price between transactions
* Generate logs of variables and collapse observations by date purchase/date sale
**************************************
use "$OUTPUT/full_cleaned_data$tag.dta", clear

*Generate lagged variables
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
by property_id: gen L_cesa_bianchi_cum = cesa_bianchi_cum[_n-1]
by property_id: gen L_cloyne_hurtgen_cum = cloyne_hurtgen_cum[_n-1]		
by property_id: gen L_price_quintile_yearly = price_quintile_yearly[_n-1]														   
by property_id: gen L_year = year[_n-1]	
																  
* Tag data for which the lease was extended half way through the ownership
gen lease_was_extended = 0
replace lease_was_extended = 1 if leasehold & !missing(L_date_registered) & date_registered != L_date_registered

* Generate differenced variables
gen d_price = price - L_price
gen d_log_price = 100*(log(price) - log(L_price))

gen d_price_win = price_win - L_price_win
gen d_log_price_win = 100*(log(price_win) - log(L_price_win))

gen d_interest_rate = interest_rate - L_interest_rate
gen d_log_interest_rate = log(interest_rate) - log(L_interest_rate)

gen years_held = date_trans - L_date_trans

gen d_cesa_bianchi = cesa_bianchi_cum - L_cesa_bianchi_cum

save "$OUTPUT/full_cleaned_data_with_lags_and_extensions$tag.dta", replace
drop if lease_was_extended

*****************************
* Classify data into percentiles:
******************************/

* Generate x_tiles of purchase price 
xtile price_quintile = L_price, nq(5) 
xtile price_quintile_sale = price, nq(5) 
xtile price_ventile = L_price, nq(20)

xtile bucket_3 = lease_duration_at_trans, nq(2)
replace bucket_3 = 3 if !leasehold

xtile bucket_6 = lease_duration_at_trans, nq(5)
replace bucket_6 = 3 if !leasehold

xtile bucket_11 = lease_duration_at_trans, nq(11)
replace bucket_11 = 11 if !leasehold

* Classify data into five year periods (based on purchase data, sale date, and halfway point)
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

xtile price_quintile_restricted = L_price if !missing(L_date_trans), nq(5) 
xtile price_quintile_sale_restricted = price if !missing(L_date_trans), nq(5) 
xtile price_ventile_restricted = L_price if !missing(L_date_trans), nq(20)

xtile bucket_3_restricted = lease_duration_at_trans if !missing(L_date_trans), nq(2)
replace bucket_3_restricted = 3 if !leasehold & !missing(L_date_trans)

xtile bucket_6_restricted = lease_duration_at_trans if !missing(L_date_trans), nq(5)
replace bucket_6_restricted = 3 if !leasehold & !missing(L_date_trans)

xtile bucket_11_restricted = lease_duration_at_trans if !missing(L_date_trans), nq(11)
replace bucket_11_restricted = 11 if !leasehold & !missing(L_date_trans)

save "$OUTPUT/full_cleaned_data_with_lags$tag.dta", replace

* Keep only observations that record change over time (this will delete all properties for which we only have on observation)
drop if missing(L_date_trans)

drop bucket_3 bucket_6 bucket_11 price_quintile price_quintile_sale price_ventile

rename bucket*_restricted bucket*
rename price*_restricted price*

count

save "$OUTPUT/final_data$tag.dta", replace
