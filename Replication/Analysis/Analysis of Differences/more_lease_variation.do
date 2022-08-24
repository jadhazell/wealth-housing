global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/More Lease Variation"


set scheme plotplainblind

local bucket_name bucket_6_sale

eststo clear 
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)

esttab using "$RESULTS/main_regression_`bucket_name'_separating_extended_leases.tex", se title("Baseline Regression Results, Including Extended Leases, 5 Lease Buckets \label{tab: bucket 6}") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate 4.`bucket_name'#c.d_interest_rate 5.`bucket_name'#c.d_interest_rate 6.`bucket_name'#c.d_interest_rate 7.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Leasehold 2 x $\Delta$ Interest Rate}" 3.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Leasehold 3 x $\Delta$ Interest Rate}" 4.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Leasehold 4 x $\Delta$ Interest Rate}" 5.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Leasehold 5 x $\Delta$ Interest Rate}" 6.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Freehold x $\Delta$ Interest Rate}" 7.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Lease Extended x $\Delta$ Interest Rate}") gaps replace

local bucket_name bucket_6_sale
esttab, se title("Baseline Regression Results, Including Extended Leases, 5 Lease Buckets") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate 4.`bucket_name'#c.d_interest_rate 5.`bucket_name'#c.d_interest_rate 6.`bucket_name'#c.d_interest_rate 7.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "Leasehold 2 x $\Delta$ Interest Rate" 3.`bucket_name'#c.d_interest_rate "Leasehold 3 x $\Delta$ Interest Rate" 4.`bucket_name'#c.d_interest_rate "Leasehold 4 x $\Delta$ Interest Rate" 5.`bucket_name'#c.d_interest_rate "Leasehold 5 x $\Delta$ Interest Rate" 6.`bucket_name'#c.d_interest_rate "Freehold x $\Delta$ Interest Rate" 7.`bucket_name'#c.d_interest_rate "Lease Extended x $\Delta$ Interest Rate") gaps replace

cap drop xaxis coeff sd ub lb
gen xaxis = _n if _n <= 7
gen coeff = .
gen sd = .

local bucket_name bucket_6_sale
forvalues n = 2/7 {
	replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
}

gen lb = coeff - 1.96*sd
gen ub = coeff + 1.96*sd

twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "Freehold" 7 "Extended", angle(45)) yline(0)
graph export "$RESULTS/bucket_6_regression_results.png", replace

// Deciles:

local bucket_name bucket_11_sale

eststo clear 
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)

local bucket_name bucket_11_sale
esttab using "$RESULTS/main_regression_`bucket_name'_separating_extended_leases.tex", se title("Baseline Regression Results, Including Extended Leases, 5 Lease Buckets \label{tab: bucket 11}") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate 4.`bucket_name'#c.d_interest_rate 5.`bucket_name'#c.d_interest_rate 6.`bucket_name'#c.d_interest_rate 7.`bucket_name'#c.d_interest_rate 8.`bucket_name'#c.d_interest_rate 9.`bucket_name'#c.d_interest_rate 10.`bucket_name'#c.d_interest_rate 11.`bucket_name'#c.d_interest_rate 12.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 2 x $\Delta$ Interest Rate}"  3.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 3 x $\Delta$ Interest Rate}"  4.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 4 x $\Delta$ Interest Rate}"  5.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 5 x $\Delta$ Interest Rate}"  6.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 6 x $\Delta$ Interest Rate}"  7.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 7 x $\Delta$ Interest Rate}"  8.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 8 x $\Delta$ Interest Rate}"  9.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 9 x $\Delta$ Interest Rate}" 10.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 10 x $\Delta$ Interest Rate}" 11.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Freehold x $\Delta$ Interest Rate}"    12.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Lease Extended x $\Delta$ Interest Rate}") gaps replace

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
graph export "$RESULTS/bucket_11_regression_results.png", replace








/////////
// Repeat but remove leaseholds with less than 80 years remaining
///////

drop if leasehold & lease_duration_at_trans < 80
drop bucket_6_sale bucket_11_sale

xtile bucket_6_sale = lease_duration_at_trans, nq(5)
replace bucket_6_sale = 6 if !leasehold
replace bucket_6_sale = 7 if lease_was_extended

xtile bucket_11_sale = lease_duration_at_trans, nq(10)
replace bucket_11_sale = 11 if !leasehold
replace bucket_11_sale = 12 if lease_was_extended

local bucket_name bucket_6_sale

eststo clear 
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)

cap drop xaxis coeff sd ub lb
gen xaxis = _n if _n <= 7
gen coeff = .
gen sd = .

local bucket_name bucket_6_sale
forvalues n = 2/7 {
	replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
}

gen lb = coeff - 1.96*sd
gen ub = coeff + 1.96*sd

twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "Freehold" 7 "Extended", angle(45)) yline(0)
graph export "$RESULTS/bucket_6_regression_results_less_than_80.png", replace

// Deciles:

local bucket_name bucket_11_sale

eststo clear 
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)

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
graph export "$RESULTS/bucket_11_regression_results_less_than_80.png", replace


