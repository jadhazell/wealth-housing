local differenced = `1'
local restricted = `2'
local logs = `3'

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Snowballing"
global TABLES "$RESULTS/Tables"
global FIGURES "$RESULTS/Figures"

// Select correct sample according to parameters
do select_sample `differenced' `restricted' `logs'

//////////////////////////////////////////////////////////
// For the differenced regression, we can include
// an interest rate level interaction in the regression
//////////////////////////////////////////////////////////
if `differenced' {

	gen med_interest_rate = (interest_rate+L_interest_rate)/2

	local interest_rate_labels "Sale Rate" "Purchase Rate" "Midpoint Rate"
	local bucket_name bucket_3_sale

	local count = 0
	foreach rate_var of varlist interest_rate L_interest_rate med_interest_rate {
		local count = `count'+1
		local interest_rate_label : word `count' of "`interest_rate_labels'"
		
		eststo clear 
		foreach fe of global fes  {
			di "`fe'"
			di "reghdfe $dep_var i.$bucket_name##c.$indep_var##c.`rate_var', absorb(`fe') cluster($cluster)"
			eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var, absorb(`fe') cluster($cluster)
		}

		esttab using "$TABLES/snowballing_regression_`rate_var'.tex", ///
			se title("Regression Results With Interacted `interest_rate_label' Level \label{tab: `interest_rate_label'}") ///
			keep(2.$bucket_name#c.$indep_var ///
				 3.$bucket_name#c.$indep_var ///
				 2.$bucket_name#c.$indep_var#c.`rate_var' ///
				 3.$bucket_name#c.$indep_var#c.`rate_var') ///
			varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $\Delta$ Rate}" ///
					  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $\Delta$ Rate}" ///
					  2.$bucket_name#c.$indep_var#c.`rate_var' "\multirow{2}{4.5cm}{High Duration Leasehold x $\Delta$ Rate x `interest_rate_label'}" ///
					  3.$bucket_name#c.$indep_var#c.`rate_var' "\multirow{2}{4.5cm}{Freehold x $\Delta$ Rate x `interest_rate_label'}") ///
			gaps replace substitute(\_ _)
	}

	// Narrow in on first regression with sale interest rate interaction
	reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate##c.interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
	sum interest_rate
	global h_rate = r(mean)+r(sd)
	global l_rate = r(mean)-r(sd)

	sum d_interest_rate
	global h_d_rate = r(mean)+r(sd)
	global l_d_rate = r(mean)-r(sd)

	margins, at(bucket_3_sale=(1 2 3) interest_rate=($h_rate $l_rate ) d_interest_rate=($h_d_rate $l_d_rate )) vsquish
	marginsplot, recast(line) noci xlabel(1 "Low Duration" 2 "High Duration" 3 "Freehold") xtitle(" ") legend(order(1 "Low Rate Level & Large Rate Drop" 2 "Low Rate Level & Small Rate Drop" 3 "High Rate Level & Large Rate Drop" 4 "High Rate Level & Small Rate Drop"))
	graph export "$FIGURES/linear_predictions_sale.png", replace


	margins bucket_3_sale, at(d_interest_rate=($h_d_rate $l_d_rate) interest_rate=($h_rate $l_rate)
	marginsplot, by(bucket_3_sale)
	graph export "$FIGURES/linear_predictions_by_duration_sale.png", replace

	// Narrow in on first regression with purchase interest rate interaction
	reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate##c.L_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
	sum interest_rate
	global h_rate = r(mean)+r(sd)
	global l_rate = r(mean)-r(sd)

	sum d_interest_rate
	global h_d_rate = r(mean)+r(sd)
	global l_d_rate = r(mean)-r(sd)

	margins, at(bucket_3_sale=(1 2 3) L_interest_rate=($h_rate $l_rate ) d_interest_rate=($h_d_rate $l_d_rate )) vsquish
	marginsplot, recast(line) xlabel(1 "Low Duration" 2 "High Duration" 3 "Freehold") xtitle(" ") legend(order(1 "Low Rate Level & Large Rate Drop" 2 "Low Rate Level & Small Rate Drop" 3 "High Rate Level & Large Rate Drop" 4 "High Rate Level & Small Rate Drop"))
	graph export "$FIGURES/linear_predictions_purchase.png", replace


	margins bucket_3_sale, at(d_interest_rate=($h_d_rate $l_d_rate) interest_rate=($h_rate $l_rate)
	marginsplot, by(bucket_3_sale)
	graph export "$FIGURES/linear_predictions_by_duration_purchase.png", replace
}

// Plot marginal effect 

//////////////////////////////////////////////////////////
// Regress on particular year blocks
//////////////////////////////////////////////////////////

// Run regressions only on main specification
//
local datevar : word 1 of `timeslist'
local fe2 : word 2 of `fes'

foreach l of numlist 1995(5)2020 {
	quietly eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if `datevar' >= `l' & `datevar' < `l'+5 & obs_to_use2, absorb(`fe2') cluster($cluster) 
}

esttab using "$TABLES/snowballing_by_year_$tag.tex", ///
	se title("Snowballing by Year \label{tab: snowballing by year $tag}") ///
	keep( ///
	2.$bucket_name#c.$indep_var ///
	3.$bucket_name#c.$indep_var ) ///
	varlabels( ///
	2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}"  ///
	3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mtitles("1995-2000" "2000-2005" "2005-2010" "2010-2015" "2015-2020" "2020+") gaps replace substitute(\_ _)

di "$tag"

// Run regressions on year blocks + store results to plot
set scheme plotplainblind
cap drop time lh* fh*
gen time = 1995 if _n==1
replace time = time[_n-1] + 5 if _n > 1 & _n < 7

// local transaction_times "sale purchase"
foreach var of local timeslist  {
	
	local count = 1
	foreach fe of local fes {
		cap gen lh_`count' = .
		cap gen fh_`count' = .
		local count = `count'+1
	}
	
	foreach l of numlist 1995(5)2020 {
		di "$bucket_name"
		di "`var'"
		di "`l'"
		di " "
		
		eststo clear 
		local count = 1
		foreach fe of local fes {
			eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if `var' >= `l' & `var' < `l'+5 & obs_to_use2, absorb(`fe') cluster($cluster)
			replace lh_`count' =  _b[2.$bucket_name#c.$indep_var] if time==`l'
			replace fh_`count' =  _b[3.$bucket_name#c.$indep_var] if time==`l'
			local count = `count'+1
		}
		
		list time lh* fh* in 1/6
	}
	
	graph twoway (line lh_1 time) (line lh_2 time) (line lh_3 time), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" )) xtitle("Year Bucket") ytitle("Regression Coefficient")
	graph export "$FIGURES/snowballing_lh_`var'_$tag.png", replace
	
	graph twoway (line fh_1 time) (line fh_2 time) (line fh_3 time), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" )) xtitle("Year Bucket") ytitle("Regression Coefficient")
	graph export "$FIGURES/snowballing_fh_`var'_$tag.png", replace
}



// Run regressions on interest rate blocks + store results to plot
set scheme plotplainblind
cap drop xaxis
cap drop lh* fh*
gen xaxis = 0 if _n==1
replace xaxis = xaxis[_n-1] + 1 if _n > 1 & _n < 10

// local transaction_times "sale purchase"
foreach var of local indep_var  {
	
	local count = 1
	foreach fe of local fes {
		cap gen lh_`count' = .
		cap gen fh_`count' = .
		local count = `count'+1
	}
	
	foreach l of numlist 0(1)8 {
		di "$bucket_name"
		di "`var'"
		di "`l'"
		di " "
		
		sum `var' if `var' >= `l' & `var' < `l'+1
		
		eststo clear 
		local count = 1
		foreach fe of local fes {
			eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if `var' >= `l' & `var' < `l'+1 & obs_to_use2, absorb(`fe') cluster($cluster)
			replace lh_`count' =  _b[2.$bucket_name#c.$indep_var] if xaxis==`l'
			replace fh_`count' =  _b[3.$bucket_name#c.$indep_var] if xaxis==`l'
			local count = `count'+1
		}
		
		list xaxis lh* fh* in 1/10
	}
	
	graph twoway (line lh_1 xaxis) (line lh_2 xaxis) (line lh_3 xaxis), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" )) xtitle("Year Bucket") ytitle("Regression Coefficient")
	graph export "$FIGURES/snowballing_by_rate_lh_`var'_$tag.png", replace
	
	graph twoway (line fh_1 xaxis) (line fh_2 xaxis) (line fh_3 xaxis), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" )) xtitle("Year Bucket") ytitle("Regression Coefficient")
	graph export "$FIGURES/snowballing_by_rate_fh_`var'_$tag.png", replace
}
