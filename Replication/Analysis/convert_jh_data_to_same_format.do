
import delimited "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Working/quarterly_data.csv", clear
rename l_* L_*
rename initial_term* number_years*
rename new_term lease_duration_at_trans
rename L_new_term L_lease_duration_at_trans
rename date date_trans
rename L_date L_date_trans
rename d_rate d_interest_rate

encode location, gen(location_n)
encode property_type, gen(type_n)

gen leasehold = duration == "L"

drop if leasehold & missing(lease_duration_at_trans)
drop if leasehold & missing(L_lease_duration_at_trans)

xtile bucket_3_sale = lease_duration_at_trans, nq(2)
replace bucket_3_sale = 3 if !leasehold

xtile bucket_3_purchase = L_lease_duration_at_trans, nq(2)
replace bucket_3_purchase = 3 if !leasehold


// Snowballing
		
cap gen baseline_lh = .
cap gen baseline_fh = .
gen time = 1995 if _n==1
replace time = time[_n-1] + 5 if _n > 1 & _n < 7

local bucket_name bucket_3_sale
// local bucket_name bucket_3_purchase

local var date_trans
local var L_date_trans

foreach l of numlist 1995(5)2020 {
	
	eststo clear 
	quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate if `var' >= `l' & `var' < `l'+5, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
	replace baseline_lh = _b[2.`bucket_name'#c.d_interest_rate] if time==`l'
	replace baseline_fh = _b[3.`bucket_name'#c.d_interest_rate] if time==`l'
}

graph twoway (line baseline_lh time), xtitle("Year Bucket") ytitle("Regression Coefficient")
graph twoway (line baseline_fh time), xtitle("Year Bucket") ytitle("Regression Coefficient")
