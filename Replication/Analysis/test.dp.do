set scheme plotplainblind
gen time = 1995 if _n==1
replace time = time[_n-1] + 5 if _n > 1 & _n < 7

// local transaction_times "sale purchase"
	
local bucket_name bucket_3

local quintile_name price_quintile
local ventile_name price_ventile

eststo clear 
quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate, absorb(i.location_n##i.date_trans) cluster(date_trans  location_n)

quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate, absorb(i.location_n##i.date_trans##i.type_n) cluster(date_trans  location_n) 

quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate, absorb(i.location_n##i.date_trans##i.`quintile_name'##i.type_n) cluster(date_trans  location_n)

quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate, absorb(i.location_n##i.date_trans##i.`ventile_name'##i.type_n) cluster(date_trans  location_n)

quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate, absorb(i.location_n##i.date_trans##i.type_n i.location_n##i.`bucket_name') cluster(date_trans  location_n)
	esttab using "$RESULTS/main_regression_nodiff_`l'.tex", se title("Baseline Regression Results, `bucket_name'") keep(2.`bucket_name'#c.interest_rate 3.`bucket_name'#c.interest_rate) varlabels(2.`bucket_name'#c.interest_rate "\multirow{4}{2.5cm}{High Duration Leasehold x $\Delta$ Interest Rate}"  3.`bucket_name'#c.interest_rate "\multirow{4}{2.5cm}{Freehold x $\Delta$ Interest Rate}") gaps replace

	esttab, se title("Baseline Regression Results, `bucket_name'") keep(2.`bucket_name'#c.interest_rate 3.`bucket_name'#c.interest_rate) varlabels(2.`bucket_name'#c.interest_rate "High Duration Leasehold x $\Delta$ Interest Rate"  3.`bucket_name'#c.interest_rate "Freehold x $\Delta$ Interest Rate") replace

local bucket_name bucket_3

local quintile_name price_quintile
local ventile_name price_ventile
	
cap gen baseline_lh = .
cap gen typefe_lh = .
cap gen quintilefe_lh = .
cap gen ventilefe_lh = .
cap gen location_lh = .

cap gen baseline_fh = .
cap gen typefe_fh = .
cap gen quintilefe_fh = .
cap gen ventilefe_fh = .
cap gen location_fh = .

foreach l of numlist 1995(5)2020 {
	di "`l'"
	di " "
	
	eststo clear 
	quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate if date_trans >= `l' & date_trans < `l'+5, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
	replace baseline_lh = _b[2.`bucket_name'#c.interest_rate] if time==`l'
	replace baseline_fh = _b[3.`bucket_name'#c.interest_rate] if time==`l'
	
	quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate if date_trans >= `l' & date_trans < `l'+5, absorb(i.location_n##i.date_trans##i.type_n) cluster(date_trans location_n) 
	replace typefe_lh = _b[2.`bucket_name'#c.interest_rate] if time==`l'
	replace typefe_fh = _b[3.`bucket_name'#c.interest_rate] if time==`l'
	
	quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate if date_trans >= `l' & date_trans < `l'+5, absorb(i.location_n##i.date_trans##i.`quintile_name'##i.type_n) cluster(date_trans location_n)
	replace quintilefe_lh = _b[2.`bucket_name'#c.interest_rate] if time==`l'
	replace quintilefe_fh = _b[3.`bucket_name'#c.interest_rate] if time==`l'
	
	quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate if date_trans >= `l' & date_trans < `l'+5, absorb(i.location_n##i.date_trans##i.`ventile_name'##i.type_n) cluster(date_trans location_n)
	replace ventilefe_lh = _b[2.`bucket_name'#c.interest_rate] if time==`l'
	replace ventilefe_fh = _b[3.`bucket_name'#c.interest_rate] if time==`l'
	
	quietly eststo: reghdfe log_price i.`bucket_name'##c.interest_rate if date_trans >= `l' & date_trans < `l'+5, absorb(i.location_n##i.date_trans##i.type_n i.location_n##i.`bucket_name') cluster(date_trans location_n)
	replace location_lh = _b[2.`bucket_name'#c.interest_rate] if time==`l'
	replace location_fh = _b[3.`bucket_name'#c.interest_rate] if time==`l'
	
	list time baseline* typefe* quintilefe* ventilefe* location* in 1/6


// 	esttab using "$RESULTS/main_regression_`l'.tex", se title("Baseline Regression Results, `bucket_name'") keep(2.`bucket_name'#c.interest_rate 3.`bucket_name'#c.interest_rate) varlabels(2.`bucket_name'#c.interest_rate "\multirow{4}{2.5cm}{High Duration Leasehold x $\Delta$ Interest Rate}"  3.`bucket_name'#c.interest_rate "\multirow{4}{2.5cm}{Freehold x $\Delta$ Interest Rate}") gaps replace
//
// 	esttab, se title("Baseline Regression Results, `bucket_name'") keep(2.`bucket_name'#c.interest_rate 3.`bucket_name'#c.interest_rate) varlabels(2.`bucket_name'#c.interest_rate "High Duration Leasehold x $\Delta$ Interest Rate"  3.`bucket_name'#c.interest_rate "Freehold x $\Delta$ Interest Rate") replace
}

graph twoway (line baseline_lh time) (line typefe_lh time) (line quintilefe_lh time) (line ventilefe_lh time) (line location_lh time), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" 4 "Add Ventile FE" 5 "Interact Location and Duration FE")) xtitle("Year Bucket") ytitle("Regression Coefficient")

graph export "$RESULTS/main_regression_nodiff_lh.png", replace


graph twoway (line baseline_fh time) (line typefe_fh time) (line quintilefe_fh time) (line ventilefe_fh time) (line location_fh time), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" 4 "Add Ventile FE" 5 "Interact Location and Duration FE")) xtitle("Year Bucket") ytitle("Regression Coefficient")
graph export "$RESULTS/main_regression_nodiff_fh.png", replace
