global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Analysis/Output"

use "$INPUT/final_data.dta", clear


// First stage regression
// Dependent variable: log change in property price between date of purchase and date of sale
// Independent variables: 
	// duration ## change in interest rate
// Fixed effects: 3 digit postcode X quarter of purchase X quarter of sale

foreach var of varlist bucket_3_sale bucket_3_purchase  {
	local tags " " "_hpi _nr"
	foreach tag of local tags{
		
		local bucket_name `var'`tag'
		local quintile_name price_quintile`tag'
		local ventile_name price_ventile`tag'
		
		di "`bucket_name'"
		di "`quintile_name'"
		di "`ventile_name'"
		di " "
		
		eststo clear 
		quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
		quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)
		quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.`quintile_name'##i.type_n) cluster(date_trans L_date_trans location_n)
		quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.`ventile_name'##i.type_n) cluster(date_trans L_date_trans location_n)
		quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.`bucket_name') cluster(date_trans L_date_trans location_n)


		esttab using "$RESULTS/main_regression_`bucket_name'.tex", se title("Baseline Regression Results, `bucket_name'") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{High Duration Leasehold x $\Delta$ Interest Rate}"  3.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Freehold x $\Delta$ Interest Rate}") gaps replace

		esttab, se title("Baseline Regression Results, `bucket_name'") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "High Duration Leasehold x $\Delta$ Interest Rate"  3.`bucket_name'#c.d_interest_rate "Freehold x $\Delta$ Interest Rate") replace
	}
}


////////////////////////////////////////////////////////////
// Include lease extensions in baseline regression
////////////////////////////////////////////////////////////
		
local bucket_name bucket_3_sale
local quintile_name price_quintile
local ventile_name price_ventile

di "`bucket_name'"
di "`quintile_name'"
di "`ventile_name'"
di " "

eststo clear 
quietly eststo: reghdfe d_log_price i.`bucket_name'##i.lease_was_extended##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.`quintile_name'##i.type_n) cluster(date_trans L_date_trans location_n)
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.`bucket_name') cluster(date_trans L_date_trans location_n)

local bucket_name bucket_3_sale
esttab using "$RESULTS/main_regression_`bucket_name'_separating_extended_leases.tex", se title("Baseline Regression Results, Including Extended Leases, 2 Lease Buckets") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate 4.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{High Duration Leasehold x $\Delta$ Interest Rate}"  3.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Freehold x $\Delta$ Interest Rate}" 4.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Lease Extended x $\Delta$ Interest Rate}") gaps replace

esttab, se title("Baseline Regression Results, `bucket_name'") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "High Duration Leasehold x $\Delta$ Interest Rate"  3.`bucket_name'#c.d_interest_rate "Freehold x $\Delta$ Interest Rate") replace

////////////////////////////////////////////////////////////
// Repeat for more levels of lease variation
////////////////////////////////////////////////////////////




////////////////////////////////////////////////////////////
// Now repeat that but removing leases under 80 years
////////////////////////////////////////////////////////////
use "$INPUT/final_data.dta", clear
drop bucket_6_sale bucket_11_sale
drop if lease_duration_at_trans < 80

xtile bucket_6_sale = lease_duration_at_trans, nq(5)
replace bucket_6_sale = 6 if !leasehold
replace bucket_6_sale = 7 if lease_was_extended

xtile bucket_11_sale = lease_duration_at_trans, nq(10)
replace bucket_11_sale = 11 if !leasehold
replace bucket_11_sale = 12 if lease_was_extended

// Quintiles
local bucket_name bucket_6_sale

eststo clear 
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)

esttab using "$RESULTS/main_regression_`bucket_name'_separating_extended_leases_remove_under_80.tex", se title("Baseline Regression Results, Including Extended Leases, 5 Lease Buckets") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate 4.`bucket_name'#c.d_interest_rate 5.`bucket_name'#c.d_interest_rate 6.`bucket_name'#c.d_interest_rate 7.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Leasehold 2 x $\Delta$ Interest Rate}" 3.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Leasehold 3 x $\Delta$ Interest Rate}" 4.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Leasehold 4 x $\Delta$ Interest Rate}" 5.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Leasehold 5 x $\Delta$ Interest Rate}" 6.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Freehold x $\Delta$ Interest Rate}" 7.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Lease Extended x $\Delta$ Interest Rate}") gaps replace

local bucket_name bucket_6_sale
esttab, se title("Baseline Regression Results, Including Extended Leases, 5 Lease Buckets") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate 4.`bucket_name'#c.d_interest_rate 5.`bucket_name'#c.d_interest_rate 6.`bucket_name'#c.d_interest_rate 7.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "Leasehold 2 x $\Delta$ Interest Rate" 3.`bucket_name'#c.d_interest_rate "Leasehold 3 x $\Delta$ Interest Rate" 4.`bucket_name'#c.d_interest_rate "Leasehold 4 x $\Delta$ Interest Rate" 5.`bucket_name'#c.d_interest_rate "Leasehold 5 x $\Delta$ Interest Rate" 6.`bucket_name'#c.d_interest_rate "Freehold x $\Delta$ Interest Rate" 7.`bucket_name'#c.d_interest_rate "Lease Extended x $\Delta$ Interest Rate") gaps replace

cap drop xaxis coeff sd ub lb
gen xaxis = _n if _n <= 7 & _n >= 2
gen coeff = .
gen sd = .

forvalues n = 2/7 {
	replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
}

gen lb = coeff - 1.96*sd
gen ub = coeff + 1.96*sd

twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "2" 3 "3" 4 "4" 5 "5" 6 "Freehold" 7 "Extended", angle(45)) yline(0)
graph export "$RESULTS/bucket_6_regression_results_remove_under_80.png", replace

// Deciles:

local bucket_name bucket_11_sale

eststo clear 
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)

local bucket_name bucket_11_sale
esttab using "$RESULTS/main_regression_`bucket_name'_separating_extended_leases_remove_under_80.tex", se title("Baseline Regression Results, Including Extended Leases, 5 Lease Buckets \label{tab:regression_results_deciles}") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate 4.`bucket_name'#c.d_interest_rate 5.`bucket_name'#c.d_interest_rate 6.`bucket_name'#c.d_interest_rate 7.`bucket_name'#c.d_interest_rate 8.`bucket_name'#c.d_interest_rate 9.`bucket_name'#c.d_interest_rate 10.`bucket_name'#c.d_interest_rate 11.`bucket_name'#c.d_interest_rate 12.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 2 x $\Delta$ Interest Rate}"  3.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 3 x $\Delta$ Interest Rate}"  4.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 4 x $\Delta$ Interest Rate}"  5.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 5 x $\Delta$ Interest Rate}"  6.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 6 x $\Delta$ Interest Rate}"  7.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 7 x $\Delta$ Interest Rate}"  8.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 8 x $\Delta$ Interest Rate}"  9.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 9 x $\Delta$ Interest Rate}" 10.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 10 x $\Delta$ Interest Rate}" 11.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Freehold x $\Delta$ Interest Rate}"    12.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Lease Extended x $\Delta$ Interest Rate}") gaps replace

// Plot results
cap drop xaxis coeff sd ub lb
gen xaxis = _n if _n <= 12
gen coeff = .
gen sd = .

forvalues n = 2/12 {
	replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
}

gen lb = coeff - 1.96*sd
gen ub = coeff + 1.96*sd

twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "Freehold" 12 "Extended", angle(45)) yline(0)
graph export "$RESULTS/bucket_11_regression_results_remove_under_80.png", replace
