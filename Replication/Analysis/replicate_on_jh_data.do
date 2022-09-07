
import delimited "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Working/quarterly_data.csv", clear
rename l_* L_*
rename initial_term* number_years*
rename new_term lease_duration_at_trans
rename L_new_term L_lease_duration_at_trans
rename date date_trans
rename L_date L_date_trans
rename d_rate d_interest_rate
rename property_type type

egen location_n = group(location)
egen type_n = group(property_type)
egen postcode_n = group(postcode)

gen leasehold = duration == "L"
gen years_held = date_trans - L_date_trans

// drop if leasehold & missing(lease_duration_at_trans)
// drop if leasehold & missing(L_lease_duration_at_trans)

xtile bucket_3 = L_lease_duration_at_trans, nq(2)
replace bucket_3 = 3 if !leasehold

save "$WORKING/jad_quarterly_data.dta", replace


// Snowballing
		
// cap gen baseline_lh = .
// cap gen baseline_fh = .
// gen time = 1995 if _n==1
// replace time = time[_n-1] + 5 if _n > 1 & _n < 7
//
// local bucket_name bucket_3_sale
// // local bucket_name bucket_3_purchase
//
// local var date_trans
// local var L_date_trans
//
// foreach l of numlist 1995(5)2020 {
//	
// 	eststo clear 
// 	quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate if `var' >= `l' & `var' < `l'+5, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
// 	replace baseline_lh = _b[2.`bucket_name'#c.d_interest_rate] if time==`l'
// 	replace baseline_fh = _b[3.`bucket_name'#c.d_interest_rate] if time==`l'
// }
//
// graph twoway (line baseline_lh time), xtitle("Year Bucket") ytitle("Regression Coefficient")
// graph twoway (line baseline_fh time), xtitle("Year Bucket") ytitle("Regression Coefficient")


////////////////////////////
// More lease variation
////////////////////////////
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/More Lease Variation"
local bucket_name bucket_6_sale

eststo clear 
eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)

local bucket_name bucket_6_sale
esttab using "$RESULTS/main_regression_`bucket_name'_jh_data.tex", se title("Baseline Regression Results, Including Extended Leases, 5 Lease Buckets \label{tab: bucket 6}") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate 4.`bucket_name'#c.d_interest_rate 5.`bucket_name'#c.d_interest_rate 6.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Leasehold 2 x $\Delta$ Interest Rate}" 3.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Leasehold 3 x $\Delta$ Interest Rate}" 4.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Leasehold 4 x $\Delta$ Interest Rate}" 5.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Leasehold 5 x $\Delta$ Interest Rate}" 6.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Freehold x $\Delta$ Interest Rate}" ) gaps replace


cap drop xaxis coeff sd ub lb
gen xaxis = _n if _n <= 7
gen coeff = .
gen sd = .

local bucket_name bucket_6_sale
forvalues n = 2/6 {
	replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
}

gen lb = coeff - 1.96*sd
gen ub = coeff + 1.96*sd

twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "Freehold", angle(45)) yline(0)
graph export "$RESULTS/quintiles_jh_data.png", replace
