
* Get parameters
local differenced = 1
local logs = 1
local restricted = 0
local drop_under_80 = 1

if !missing(`"`1'"') {
	local differenced = `1'
}

if !missing(`"`2'"') {
	local logs = `2'
}

if !missing(`"`3'"') {
	local restricted = `3'
}

if !missing(`"`4'"') {
	local drop_under_80 = `4'
}

di "`1'"
di "`2'"
di "`3'"
di "`4'"

di "`differenced'"
di "`logs'"
di "`restricted'"
di "`drop_under_80'"

* Get data
do select_sample `differenced' `logs' `restricted' `drop_under_80'


global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Snowballing"
global FIGURES "$RESULTS/Figures/Snowballing"


*******************************************************
* For the differenced regression, we can include
* an interest rate level interaction in the regression
*******************************************************
if `differenced' {

	gen med_interest_rate = (interest_rate+L_interest_rate)/2

	local interest_rate_labels "Sale Rate" "Purchase Rate" "Midpoint Rate"
	local bucket_name bucket_3_sale

	local count = 0
	foreach rate_var of varlist interest_rate L_interest_rate med_interest_rate {
		local count = `count'+1
		local interest_rate_label : word `count' of "`interest_rate_labels'"
		
		if `count'==1 {
			continue
		}
		
		eststo clear 
		foreach fe of global fes  {
			di "`fe'"
			eststo: reghdfe $dep_var c.$indep_var##c.`rate_var'##(c.lease_duration_at_trans i.freehold), absorb(`fe') cluster($cluster)
		}

		esttab using "$TABLES/snowballing_regression_`rate_var'.tex", ///
			se title("Regression Results With Interacted `interest_rate_label' Level \label{tab: snowballing `rate_var'}") ///
			keep(c.$indep_var#c.lease_duration_at_trans ///
				 c.$indep_var#c.`rate_var'#c.lease_duration_at_trans ///
				 1.freehold#c.$indep_var ///
				 1.freehold#c.$indep_var#c.`rate_var' ) ///
			varlabels(c.$indep_var#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $\Delta$ Rate}" ///
					  c.$indep_var#c.`rate_var'#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $\Delta$ Rate x `interest_rate_label'}" ///
					  1.freehold#c.$indep_var "\multirow{2}{4.5cm}{Freehold x $\Delta$ Rate }" ///
					  1.freehold#c.$indep_var#c.`rate_var'#i.freehold"\multirow{2}{4.5cm}{Freehold x $\Delta$ Rate x `interest_rate_label'}") ///
			gaps replace substitute(\_ _)  ///
			mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") ///
			stats(N r2 r2_within, fmt(%9.0fc %9.4fc) labels("N" "R2" "Within R2")) 
	}

// 	* Narrow in on first regression with sale interest rate interaction
// 	reghdfe $dep_var i.bucket_3_sale##c.$indep_var##c.interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster($cluster)
// 	sum interest_rate
// 	global h_rate = r(mean)+r(sd)
// 	global l_rate = r(mean)-r(sd)
//
// 	sum d_interest_rate
// 	global h_d_rate = r(mean)+r(sd)
// 	global l_d_rate = r(mean)-r(sd)
//
// 	margins, at(bucket_3_sale=(1 2 3) interest_rate=($h_rate $l_rate ) d_interest_rate=($h_d_rate $l_d_rate )) vsquish
// 	marginsplot, recast(line) noci xlabel(1 "Low Duration" 2 "High Duration" 3 "Freehold") xtitle(" ") legend(order(1 "Low Rate Level & Large Rate Drop" 2 "Low Rate Level & Small Rate Drop" 3 "High Rate Level & Large Rate Drop" 4 "High Rate Level & Small Rate Drop"))
// 	graph export "$FIGURES/linear_predictions_sale.png", replace
	
	*******************************************************
	* Run regression on each quarter + plot 
	*******************************************************
	
	foreach var of varlist date_trans L_date_trans {
		
		if "`var'" == "date_trans" {
			local other_var "L_date_trans"
			local rate_var "interest_rate"
		}
		else {
			local other_var "date_trans"
			local rate_var "L_interest_rate"
		}
		
		cap drop xaxis rate leasehold_* freehold_*
		
		gen xaxis = .
		gen leasehold_coeff = .
		gen freehold_coeff = .
		gen leasehold_se = .
		gen freehold_se = .
		gen rate = .
		
		levelsof `var', local(quarters)
		local count = 1
		foreach quarter of local quarters {
			reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold) if `var'==`quarter', absorb(i.district_n##i.year##i.L_year) cluster(`other_var' location_n)
			replace leasehold_coeff = _b[c.$indep_var#c.lease_duration_at_trans]  if _n == `count'
			replace freehold_coeff  = _b[1.freehold#c.$indep_var]  if _n == `count'
			replace leasehold_se    = _se[c.$indep_var#c.lease_duration_at_trans] if _n == `count'
			replace freehold_se     = _se[1.freehold#c.$indep_var] if _n == `count'
			replace xaxis           = `quarter'                        if _n == `count'
			
			summarize `rate_var' if `var'==`quarter'
			replace rate 			= r(mean) 						   if _n == `count'
			
			local count = `count'+1
		}
		
		gen leasehold_ub = leasehold_coeff + 1.96*leasehold_se
		gen leasehold_lb = leasehold_coeff - 1.96*leasehold_se
		gen freehold_ub  = freehold_coeff  + 1.96*freehold_se
		gen freehold_lb  = freehold_coeff  - 1.96*freehold_se
		
		* Coefficient vs year scatter plots
		
		twoway (scatter freehold_coeff xaxis, yaxis(1)) ///
			   (rcap freehold_ub freehold_lb xaxis, yaxis(1)) ///
			   (lfit freehold_coeff xaxis, yaxis(1)) ///
			   (line rate xaxis, yaxis(2) lpattern(solid) lcolor(black) lwidth(medthick)), ///
			   legend(off) xtitle("Year") ytitle("Coefficient") ytitle("Interest Rate", axis(2))
		graph export "$FIGURES/freehold_snowballing_by_quarter_`var'.png", replace
		
		twoway (scatter freehold_coeff xaxis, yaxis(1)) ///
			   (rcap freehold_ub freehold_lb xaxis, yaxis(1)) ///
			   (lfit freehold_coeff xaxis, yaxis(1)) ///
			   (line rate xaxis, yaxis(2) lpattern(solid) lcolor(black) lwidth(medthick)) if xaxis >= 2000, ///
			   legend(off) xtitle("Year") ytitle("Coefficient") ytitle("Interest Rate", axis(2))
		graph export "$FIGURES/freehold_snowballing_by_quarter_zoomed_`var'.png", replace
		
		twoway (scatter freehold_coeff xaxis, yaxis(1)) ///
			   (rcap freehold_ub freehold_lb xaxis, yaxis(1)) ///
			   (lfit freehold_coeff xaxis, yaxis(1)) ///
			   (line rate xaxis, yaxis(2) lpattern(solid) lcolor(black) lwidth(medthick)) if xaxis <= 2015, ///
			   legend(off) xtitle("Year") ytitle("Coefficient") ytitle("Interest Rate", axis(2))
		graph export "$FIGURES/freehold_snowballing_by_quarter_zoomed_down_`var'.png", replace
		
		twoway (scatter leasehold_coeff xaxis, yaxis(1)) ///
			   (rcap leasehold_ub leasehold_lb xaxis, yaxis(1)) ///
			   (lfit leasehold_coeff xaxis, yaxis(1)) ///
			   (line rate xaxis, yaxis(2) lpattern(solid) lcolor(black) lwidth(medthick)), ///
			   legend(off) xtitle("Year") ytitle("Coefficient") ytitle("Interest Rate", axis(2))
		graph export "$FIGURES/leasehold_snowballing_by_quarter_`var'.png", replace
		
		twoway (scatter leasehold_coeff xaxis, yaxis(1)) ///
			   (rcap leasehold_ub leasehold_lb xaxis, yaxis(1)) ///
			   (lfit leasehold_coeff xaxis, yaxis(1)) ///
			   (line rate xaxis, yaxis(2) lpattern(solid) lcolor(black) lwidth(medthick)) if xaxis >= 2000, ///
			   legend(off) xtitle("Year") ytitle("Coefficient") ytitle("Interest Rate", axis(2))
		graph export "$FIGURES/leasehold_snowballing_by_quarter_zoomed_`var'.png", replace
		
		twoway (scatter leasehold_coeff xaxis, yaxis(1)) ///
			   (rcap leasehold_ub leasehold_lb xaxis, yaxis(1)) ///
			   (lfit leasehold_coeff xaxis, yaxis(1)) ///
			   (line rate xaxis, yaxis(2) lpattern(solid) lcolor(black) lwidth(medthick)) if xaxis <= 2015, ///
			   legend(off) xtitle("Year") ytitle("Coefficient") ytitle("Interest Rate", axis(2))
		graph export "$FIGURES/leasehold_snowballing_by_quarter_zoomed_down_`var'.png", replace
		
		* Without interest rate overlayed

		twoway (scatter freehold_coeff xaxis, yaxis(1)) ///
			   (rcap freehold_ub freehold_lb xaxis, yaxis(1)) ///
			   (lfit freehold_coeff xaxis, yaxis(1)) , ///
			   legend(off) xtitle("Year") ytitle("Coefficient")
		graph export "$FIGURES/freehold_snowballing_by_quarter_norate_`var'.png", replace
		
		twoway (scatter freehold_coeff xaxis) ///
			   (rcap freehold_ub freehold_lb xaxis) ///
			   (lfit freehold_coeff xaxis, lwidth(thick))  if xaxis >= 2000 , ///
			   legend(off) xtitle("Year") ytitle("Coefficient")
		graph export "$FIGURES/freehold_snowballing_by_quarter_norate_zoomed_`var'.png", replace
		
		local var "date_trans"
		twoway (scatter freehold_coeff xaxis) ///
			   (rcap freehold_ub freehold_lb xaxis) ///
			   (lfit freehold_coeff xaxis, lwidth(thick))  if xaxis <= 2015 , ///
			   legend(off) xtitle("Year") ytitle("Coefficient")
		graph export "$FIGURES/freehold_snowballing_by_quarter_norate_zoomed_down_`var'.png", replace
		
		local var date_trans
		twoway (scatter leasehold_coeff xaxis, yaxis(1)) ///
			   (rcap leasehold_ub leasehold_lb xaxis, yaxis(1)) ///
			   (lfit leasehold_coeff xaxis, yaxis(1)) , ///
			   legend(off) xtitle("Year") ytitle("Coefficient")
		graph export "$FIGURES/leasehold_snowballing_by_quarter_norate_`var'.png", replace
		
		twoway (scatter leasehold_coeff xaxis, yaxis(1)) ///
			   (rcap leasehold_ub leasehold_lb xaxis, yaxis(1)) ///
			   (lfit leasehold_coeff xaxis, yaxis(1)) if xaxis >= 2000, ///
			   legend(off) xtitle("Year") ytitle("Coefficient")
		graph export "$FIGURES/leasehold_snowballing_by_quarter_norate_zoomed_`var'.png", replace
		
		twoway (scatter leasehold_coeff xaxis, yaxis(1)) ///
			   (rcap leasehold_ub leasehold_lb xaxis, yaxis(1)) ///
			   (lfit leasehold_coeff xaxis, yaxis(1)) if xaxis <= 2015, ///
			   legend(off) xtitle("Year") ytitle("Coefficient")
		graph export "$FIGURES/leasehold_snowballing_by_quarter_norate_zoomed_down_`var'.png", replace
		
		
		* Coefficient vs interest rate binscatters
		binscatter2 leasehold_coeff rate, xtitle("Interest Rate") ytitle("Coefficient") nquantiles(50)
		graph export "$FIGURES/leasehold_snowballing_by_rate_binscatter_`var'_nofe.png", replace
		
		binscatter2 freehold_coeff rate, xtitle("Interest Rate") ytitle("Coefficient") nquantiles(50)
		graph export "$FIGURES/freehold_snowballing_by_rate_binscatter_`var'_nofe.png", replace
		
	}
	
}
//
// else {
// 	//////////////////////////////////////////////////////////
// 	// Regress on particular year blocks
// 	//////////////////////////////////////////////////////////
//
// 	// Run regressions only on main specification
// 	//
// 	local datevar date_trans
// 	local fe2 : word 2 of $fes
//
// 	eststo clear
// 	foreach l of numlist 1995(5)2020 {
// 		quietly eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if `datevar' >= `l' & `datevar' < `l'+5 & obs_to_use2, absorb(`fe2') cluster($cluster) 
// 	}
//
// 	esttab using "$TABLES/snowballing_by_year_$tag.tex", ///
// 		se title("Snowballing by Year \label{tab: snowballing by year $tag}") ///
// 		keep( ///
// 		2.$bucket_name#c.$indep_var ///
// 		3.$bucket_name#c.$indep_var ) ///
// 		varlabels( ///
// 		2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}"  ///
// 		3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
// 		mtitles("1995-2000" "2000-2005" "2005-2010" "2010-2015" "2015-2020" "2020+") ///
// 		gaps replace substitute(\_ _) collabels($dep_var_label )
//
// 	di "$tag"
//
// 	// Run regressions on year blocks + store results to plot
//	
// 	local datevar date_trans
// 	cap drop time 
// 	cap drop lh* fh*
// 	gen time = 1995 if _n==1
// 	replace time = time[_n-1] + 5 if _n > 1 & _n < 7
//		
// 	local count = 1
// 	foreach fe of global fes {
// 		cap gen lh_`count' = .
// 		cap gen fh_`count' = .
// 		local count = `count'+1
// 	}
//	
// 	foreach l of numlist 1995(5)2020 {
// 		di "$bucket_name"
// 		di "`l'"
// 		di " "
//		
// 		eststo clear 
// 		local count = 1
// 		foreach fe of global fes {
//			
// 			if `count' > 3 {
// 				continue
// 			}
//			
// 			di "Fixed effect: `fe'"
// 			eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if `datevar' >= `l' & `datevar' < `l'+5 & obs_to_use`count', absorb(`fe') cluster($cluster)
// 			replace lh_`count' =  _b[2.$bucket_name#c.$indep_var] if time==`l'
// 			replace fh_`count' =  _b[3.$bucket_name#c.$indep_var] if time==`l'
// 			local count = `count'+1
// 		}
//		
// 		list time lh* fh* in 1/6
// 	}
//	
// 	graph twoway (line lh_1 time) (line lh_2 time) (line lh_3 time), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" )) xtitle("Year Bucket") ytitle("Regression Coefficient")
// 	graph export "$FIGURES/snowballing_lh_`var'_$tag.png", replace
//	
// 	graph twoway (line fh_1 time) (line fh_2 time) (line fh_3 time), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" )) xtitle("Year Bucket") ytitle("Regression Coefficient")
// 	graph export "$FIGURES/snowballing_fh_`var'_$tag.png", replace
//
//
//
// 	// Run regressions on interest rate blocks + store results to plot
// 	set scheme plotplainblind
// 	cap drop xaxis
// 	cap drop lh* fh*
// 	gen xaxis = _n if _n <= 5
//		
// 	local count = 1
// 	foreach fe of global fes {
// 		cap gen lh_`count' = .
// 		cap gen fh_`count' = .
// 		local count = `count'+1
// 	}
//	
// 	xtile interest_rate_quintiles = interest_rate, nq(5)
//
// 	forvalues l = 1/5 {
// 		di "$bucket_name"
// 		di "`l'"
// 		di " "
//		
// 		eststo clear 
// 		local count = 1
// 		foreach fe of global fes {
//			
// 			if `count' > 3{
// 				continue
// 			}
//			
// 			eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if interest_rate_quintiles==`l' & obs_to_use`count', absorb(`fe') cluster($cluster)
// 			replace lh_`count' =  _b[2.$bucket_name#c.$indep_var] if xaxis==`l'
// 			replace fh_`count' =  _b[3.$bucket_name#c.$indep_var] if xaxis==`l'
// 			local count = `count'+1
// 		}
//		
// 		list xaxis lh* fh* in 1/10
// 	}
//
// 	graph twoway (line lh_1 xaxis) (line lh_2 xaxis) (line lh_3 xaxis), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" )) xtitle("Year Bucket") ytitle("Regression Coefficient")
// 	graph export "$FIGURES/snowballing_by_rate_lh_`var'_$tag.png", replace
//
// 	graph twoway (line fh_1 xaxis) (line fh_2 xaxis) (line fh_3 xaxis), legend(order(1 "Baseline Regression" 2 "Add Type FE" 3 "Add Price Quintile FE" )) xtitle("Year Bucket") ytitle("Regression Coefficient")
// 	graph export "$FIGURES/snowballing_by_rate_fh_`var'_$tag.png", replace
// }
