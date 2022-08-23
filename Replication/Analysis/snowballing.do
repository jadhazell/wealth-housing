global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Snowballing"

label var d_price "$\Delta$ house price"
// Get summary stats
estpost tabstat d_log_price d_price d_interest_rate lease_duration_at_trans, by(year_bucket_sale) statistics(mean sd) columns(statistics) listwise
esttab using "$RESULTS/summary_by_year_sale.tex", main(mean) aux(sd) nostar nonumber unstack label noobs nonote title("Stats By Year of Sale \label{tab: summary by year of sale}") replace

estpost tabstat d_log_price d_price d_interest_rate lease_duration_at_trans, by(year_bucket_purchase) statistics(mean sd) columns(statistics) listwise
esttab using "$RESULTS/summary_by_year_purchase.tex", main(mean) aux(sd) nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary by year of purchase}") replace

estpost tabstat d_log_price d_price d_interest_rate lease_duration_at_trans, by(year_bucket_half_way) statistics(mean sd) columns(statistics) listwise
esttab using "$RESULTS/summary_by_year_halfway.tex", main(mean) aux(sd) nonumber nostar unstack label noobs nonote title("Stats By Halfway Year Between Purchase and Sale \label{tab: summary by halfway year}")replace

// Run regressions only on main specification

foreach l of numlist 1995(5)2020 {
	
	quietly eststo: reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate if half_way >= `l' & half_way < `l'+5, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n) 
}

esttab using "$RESULTS/main_regression_by_year.tex", se title("Baseline Regression Results by Year \label{tab: regression results}") keep(2.bucket_3_sale#c.d_interest_rate 3.bucket_3_sale#c.d_interest_rate 4.bucket_3_sale#c.d_interest_rate) varlabels(2.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{High Duration Leasehold x $\Delta$ Interest Rate}"  3.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{Freehold x $\Delta$ Interest Rate}" 4.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{Lease Extension x $\Delta$ Interest Rate}") mtitles("1995-2000" "2000-2005" "2005-2010" "2010-2015" "2015-2020" "2020+") gaps replace


// Run regressions on year blocks + store results to plot
set scheme plotplainblind
gen time = 1995 if _n==1
replace time = time[_n-1] + 5 if _n > 1 & _n < 7

// local transaction_times "sale purchase"
local transaction_times "sale"
foreach transaction_tag of local transaction_times {
	
	local bucket_name bucket_3_`transaction_tag'
	
	local quintile_name price_quintile
	local ventile_name price_ventile
	
	foreach var of varlist sale purchase half_way  {
// 	foreach var of varlist sale  {
		
		cap gen baseline_`transaction_tag'_`var'_lh = .
		cap gen typefe_`transaction_tag'_`var'_lh = .
		cap gen quintilefe_`transaction_tag'_`var'_lh = .
		cap gen ventilefe_`transaction_tag'_`var'_lh = .
		cap gen location_`transaction_tag'_`var'_lh = .
		
		cap gen baseline_`transaction_tag'_`var'_fh = .
		cap gen typefe_`transaction_tag'_`var'_fh = .
		cap gen quintilefe_`transaction_tag'_`var'_fh = .
		cap gen ventilefe_`transaction_tag'_`var'_fh = .
		cap gen location_`transaction_tag'_`var'_fh = .
		
		foreach l of numlist 1995(5)2020 {
			di "`bucket_name'"
			di "`var'"
			di "`l'"
			di " "
			
			eststo clear 
			quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate if `var' >= `l' & `var' < `l'+5, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
			replace baseline_`transaction_tag'_`var'_lh = _b[2.`bucket_name'#c.d_interest_rate] if time==`l'
			replace baseline_`transaction_tag'_`var'_fh = _b[3.`bucket_name'#c.d_interest_rate] if time==`l'
			
			quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate if `var' >= `l' & `var' < `l'+5, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n) 
			replace typefe_`transaction_tag'_`var'_lh = _b[2.`bucket_name'#c.d_interest_rate] if time==`l'
			replace typefe_`transaction_tag'_`var'_fh = _b[3.`bucket_name'#c.d_interest_rate] if time==`l'
			
			quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate if `var' >= `l' & `var' < `l'+5, absorb(i.location_n##i.date_trans##i.L_date_trans##i.`quintile_name'##i.type_n) cluster(date_trans L_date_trans location_n)
			replace quintilefe_`transaction_tag'_`var'_lh = _b[2.`bucket_name'#c.d_interest_rate] if time==`l'
			replace quintilefe_`transaction_tag'_`var'_fh = _b[3.`bucket_name'#c.d_interest_rate] if time==`l'
			
			quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate if `var' >= `l' & `var' < `l'+5, absorb(i.location_n##i.date_trans##i.L_date_trans##i.`ventile_name'##i.type_n) cluster(date_trans L_date_trans location_n)
			replace ventilefe_`transaction_tag'_`var'_lh = _b[2.`bucket_name'#c.d_interest_rate] if time==`l'
			replace ventilefe_`transaction_tag'_`var'_fh = _b[3.`bucket_name'#c.d_interest_rate] if time==`l'
			
			quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate if `var' >= `l' & `var' < `l'+5, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.`bucket_name') cluster(date_trans L_date_trans location_n)
			replace location_`transaction_tag'_`var'_lh = _b[2.`bucket_name'#c.d_interest_rate] if time==`l'
			replace location_`transaction_tag'_`var'_fh = _b[3.`bucket_name'#c.d_interest_rate] if time==`l'
			
			list time baseline_`transaction_tag'_`var'* typefe_`transaction_tag'_`var'* quintilefe_`transaction_tag'_`var'* ventilefe_`transaction_tag'_`var'* location_`transaction_tag'_`var'* in 1/6


// 			esttab using "$RESULTS/main_regression_`bucket_name'_`var'_`l'.tex", se title("Baseline Regression Results in `l' \label{tab: regression results `transaction_tag' `var' `l''}") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate 4.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{High Duration Leasehold x $\Delta$ Interest Rate}"  3.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Freehold x $\Delta$ Interest Rate}" 4.`bucket_name'#c.d_interest_rate "\multirow{4}{2.5cm}{Lease Extension x $\Delta$ Interest Rate}") gaps replace
//
// 			esttab, se title("Baseline Regression Results, `bucket_name'") keep(2.`bucket_name'#c.d_interest_rate 3.`bucket_name'#c.d_interest_rate) varlabels(2.`bucket_name'#c.d_interest_rate "High Duration Leasehold x $\Delta$ Interest Rate"  3.`bucket_name'#c.d_interest_rate "Freehold x $\Delta$ Interest Rate") replace
		}
		
		graph twoway (line baseline_`transaction_tag'_`var'_lh time) (line typefe_`transaction_tag'_`var'_lh time) (line quintilefe_`transaction_tag'_`var'_lh time) (line ventilefe_`transaction_tag'_`var'_lh time) (line location_`transaction_tag'_`var'_lh time), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" 4 "Add Ventile FE" 5 "Interact Location and Duration FE")) xtitle("Year Bucket") ytitle("Regression Coefficient")
		
		graph export "$RESULTS/main_regression_`bucket_name'_`var'_lh.png", replace
		
		
		graph twoway (line baseline_`transaction_tag'_`var'_fh time) (line typefe_`transaction_tag'_`var'_fh time) (line quintilefe_`transaction_tag'_`var'_fh time) (line ventilefe_`transaction_tag'_`var'_fh time) (line location_`transaction_tag'_`var'_fh time), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" 4 "Add Ventile FE" 5 "Interact Location and Duration FE")) xtitle("Year Bucket") ytitle("Regression Coefficient")
		graph export "$RESULTS/main_regression_`bucket_name'_`var'_fh.png", replace
	}
}
