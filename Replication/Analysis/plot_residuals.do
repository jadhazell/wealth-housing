global tag `1'

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Log Transformation and Residuals"

global TABLES "$RESULTS/Tables"
global FIGURES "$RESULTS/Figures"

if "$tag" == "levels" {
	use "$INPUT/full_cleaned_data_with_lags.dta", clear
	global dep_var_level price 
	global dep_var_log log_price
	global dep_var_level_label "Price"
	global dep_var_log_label "log(Price)"
	
	global indep_var interest_rate
	global indep_var_label "Interest Rate"
	
	global bucket_name bucket_3
	
	global fes `" "i.location_n##i.date_trans" "i.location_n##i.date_tran##i.type_n" "i.location_n##i.date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.type_n i.location_n##i.$bucket_name" "'
	global cluster "date_trans location_n"
	
		// Generate useful data
		cap drop bucket_3 price_quintile
		xtile bucket_3 = lease_duration_at_trans, nq(2)
		replace bucket_3 = 3 if !leasehold

		xtile price_quintile = price, nq(5)
	
}

if "$tag" == "differences" {
	use "$INPUT/final_data.dta", clear
	global dep_var_level d_price 
	global dep_var_log d_log_price
	global dep_var_level_label "$\Delta$ Price"
	global dep_var_log_label "$\Delta$ log(Price)"
	
	global indep_var d_interest_rate
	global indep_var_label "$\Delta$ Interest Rate"
	
	global bucket_name bucket_3_sale
	
	global fes `" "i.location_n##i.date_trans##i.L_date_trans" "i.location_n##i.date_trans##i.L_date_trans##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.$bucket_name"  "'
	global cluster "date_trans L_date_trans location_n"
}

di "Dependent Variable (Level): $dep_var_level"
di "Dependent Variable (Log): $dep_var_log"
di "Independent Variable: $indep_var"
di "Cluster: $cluster"

// drop if !leasehold

// Useful variables for later:
gen interacted_term = lease_duration_at_trans * $indep_var
winsor lease_duration_at_trans, p(0.01) gen(lease_duration_at_trans_win)
winsor interacted_term, p(0.01) gen(interacted_term_win)

global p25 = 84000
global p50 = 147500
global p75 = 244000


// /////////////////////////////////////////////////////////////
// // First get residuals for conitnuous by continuous regression
// ////////////////////////////////////////////////////////////
//
// local count=0
// foreach fe of global fes  {
//	
// 	local count = `count'+1
// 	if `count' == 4 {
// 		continue
// 	}
//	
// 	// Get residuals on first stage
// 	cap drop interacted_term_residuals fitted_values fitted_values_d interacted_term_residuals_win fitted_values_win
// 	reghdfe interacted_term lease_duration_at_trans $indep_var, absorb(`fe') cluster($cluster) residuals(interacted_term_residuals)
// 	predict fitted_values, xb
// 	predict fitted_values_d, xbd
//	
// 	winsor interacted_term_residuals, h(5) gen(interacted_term_residuals_win)
// 	winsor fitted_values, h(5) gen(fitted_values_win)
//	
// 	// Log
// 	graph twoway ///
// 	(scatter $dep_var_log interacted_term_residuals_win) ///
// 	(lfit $dep_var_log interacted_term_residuals_win,  lwidth(thick) lcolor(lavender)) if price < $p25 ,  ///
// 	xtitle("Residual From First Stage") ytitle("Log(Price)") yline(0) 
// 	graph export "$FIGURES/first_stage_residuals_by_log_price_quartile1_fe`count'_$tag.png", replace
//	
// 	graph twoway ///
// 	(scatter $dep_var_log interacted_term_residuals_win) ///
// 	(lfit $dep_var_log interacted_term_residuals_win,  lwidth(thick) lcolor(lavender)) if price >= $p25 & price < $p50 ,  ///
// 	xtitle("Residual From First Stage") ytitle("Log(Price)") yline(0) 
// 	graph export "$FIGURES/first_stage_residuals_by_log_price_quartile2_fe`count'_$tag.png", replace
//	
// 	graph twoway ///
// 	(scatter $dep_var_log interacted_term_residuals_win) ///
// 	(lfit $dep_var_log interacted_term_residuals_win,  lwidth(thick) lcolor(lavender)) if price >= $p50 & price < $p75 ,  ///
// 	xtitle("Residual From First Stage") ytitle("Log(Price)") yline(0) 
// 	graph export "$FIGURES/first_stage_residuals_by_log_price_quartile3_fe`count'_$tag.png", replace
//	
//	
// 	graph twoway ///
// 	(scatter $dep_var_log interacted_term_residuals_win) ///
// 	(lfit $dep_var_log interacted_term_residuals_win,  lwidth(thick) lcolor(lavender)) if price >= $p75 ,  ///
// 	xtitle("Residual From First Stage") ytitle("Log(Price)") yline(0) 
// 	graph export "$FIGURES/first_stage_residuals_by_log_price_quartile4_fe`count'_$tag.png", replace
//	
// 	// Level
// 	graph twoway ///
// 	(scatter $dep_var_level interacted_term_residuals_win) ///
// 	(lfit $dep_var_level interacted_term_residuals_win,  lwidth(thick) lcolor(lavender)) if price < $p25 ,  ///
// 	xtitle("Residual From First Stage") ytitle("Price") yline(0) 
// 	graph export "$FIGURES/first_stage_residuals_by_price_quartile1_fe`count'_$tag.png", replace
//	
// 	graph twoway ///
// 	(scatter $dep_var_level interacted_term_residuals_win) ///
// 	(lfit $dep_var_level interacted_term_residuals_win,  lwidth(thick) lcolor(lavender)) if price >= $p25 & price < $p50 ,  ///
// 	xtitle("Residual From First Stage") ytitle("Price") yline(0) 
// 	graph export "$FIGURES/first_stage_residuals_by_price_quartile2_fe`count'_$tag.png", replace
//	
// 	graph twoway ///
// 	(scatter $dep_var_level interacted_term_residuals_win) ///
// 	(lfit $dep_var_level interacted_term_residuals_win,  lwidth(thick) lcolor(lavender)) if price >= $p50 & price < $p75 ,  ///
// 	xtitle("Residual From First Stage") ytitle("Price") yline(0) 
// 	graph export "$FIGURES/first_stage_residuals_by_price_quartile3_fe`count'_$tag.png", replace
//	
//	
// 	graph twoway ///
// 	(scatter $dep_var_level interacted_term_residuals_win) ///
// 	(lfit $dep_var_level interacted_term_residuals_win,  lwidth(thick) lcolor(lavender)) if price >= $p75 ,  ///
// 	xtitle("Residual From First Stage") ytitle("Price") yline(0) 
// 	graph export "$FIGURES/first_stage_residuals_by_price_quartile4_fe`count'_$tag.png", replace
//	
// // 	// Plot residual by price
// // 	local count=1
// // 	graph twoway (scatter $dep_var_level interacted_term_residuals_win if price<1050000) ///
// // 	(lfit $dep_var_level interacted_term_residuals_win if price < $p25 ,  lwidth(thick) lcolor(teal)) ///
// // 	(lfit $dep_var_level interacted_term_residuals_win if price >= $p25 & price < $p50 ,  lwidth(thick) lcolor(maroon)) ///
// // 	(lfit $dep_var_level interacted_term_residuals_win if price >= $p50 & price < $p75 , lwidth(thick) lcolor(lavender)) ///
// // 	(lfit $dep_var_level interacted_term_residuals_win if price >= $p75 , lwidth(thick) lcolor(gray)) ///
// // 	(lfit $dep_var_level interacted_term_residuals_win,  lwidth(thick) lcolor(pink)) if price < 1050000, ///
// // 	legend(order(2 "First Quartile of Prices" ///
// // 	3 "Second Quartile of Prices" ///
// // 	4 "Third Quartile of Prices" ///
// // 	5 "Fourth Quartile of Prices" ///
// // 	6 "All Observations")) ///
// // 	xtitle("Residual From First Stage") ytitle("Price") yline(0)
// // 	graph export "$FIGURES/first_stage_residuals_by_price_fe`count'_$tag.png", replace
// //	
// // 	// Plot residual by log price
// // 	graph twoway ///
// // 	(scatter $dep_var_log interacted_term_residuals_win) ///
// // 	(lfit $dep_var_log interacted_term_residuals_win if price < $p25 ,  lwidth(thick) lcolor(teal)) ///
// // 	(lfit $dep_var_log interacted_term_residuals_win if price >= $p25 & price < $p50 ,  lwidth(thick) lcolor(maroon)) ///
// // 	(lfit $dep_var_log interacted_term_residuals_win if price >= $p50 & price < $p75 , lwidth(thick) lcolor(lavender)) ///
// // 	(lfit $dep_var_log interacted_term_residuals_win if price >= $p75 , lwidth(thick) lcolor(gray)) ///
// // 	(lfit $dep_var_log interacted_term_residuals_win,  lwidth(thick) lcolor(pink)), ///
// // 	legend(order(2 "First Quartile of Prices" ///
// // 	3 "Second Quartile of Prices" ///
// // 	4 "Third Quartile of Prices" ///
// // 	5 "Fourth Quartile of Prices" ///
// // 	6 "All Observations")) ///
// // 	xtitle("Residual From First Stage") ytitle("Log(Price)") yline(0) 
// // 	graph export "$FIGURES/first_stage_residuals_by_log_price_fe`count'_$tag.png", replace
// //	
// // 	// Plot residuals by fitted values
// // 	graph twoway (scatter interacted_term_residuals_win fitted_values_win), ytitle("Residuals From First Stage") xtitle("Fitted Values") yline(0)
// // 	graph export "$FIGURES/first_stage_residuals_by_fitted_fe`count'_$tag.png", replace
//
// // 	// Plot residuals by lease duration
// // 	graph twoway (scatter interacted_term_residuals_win lease_duration_at_trans_win), ytitle("Residuals From First Stage") xtitle("Lease Duration At Transaction (Winsorized at 0.01 level)") yline(0) 
// // 	graph export "$FIGURES/first_stage_residuals_by_indepvar_fe`count'_$tag.png", replace
// //	
// // 	// Plot residuals by interaction term
// // 	graph twoway (scatter interacted_term_residuals_win interacted_term_win), ytitle("Residuals From First Stage") xtitle("Lease Duration At Transaction x Interest Rate (Winsorized at 0.01 level)") yline(0) 
// // 	graph export "$FIGURES/first_stage_residuals_by_depvar_fe`count'_$tag.png", replace
//	
// 	// Now do the second stage regression
// 	cap drop residuals_stage_2* fitted_values*
// 	reghdfe $dep_var_level interacted_term_residuals, noabsorb cluster($cluster) residuals(residuals_stage_2_levels)
// 	predict fitted_values_levels, xb
//	
// 	graph twoway (scatter residuals_stage_2_levels fitted_values_levels), ytitle("Residuals From First Stage") xtitle("Fitted Values (No Log)") yline(0)
// 	graph export "$FIGURES/second_stage_residuals_by_fitted_levels_fe`count'_$tag.png", replace
//	
// 	reghdfe $dep_var_log interacted_term_residuals, noabsorb cluster($cluster) residuals(residuals_stage_2_log)
// 	predict fitted_values_log, xb
//	
// 	graph twoway (scatter residuals_stage_2_log fitted_values_log), ytitle("Residuals From First Stage") xtitle("Fitted Values (Log)") yline(0)
// 	graph export "$FIGURES/second_stage_residuals_by_fitted_logs_fe`count'_$tag.png", replace
//
// }


// Get results for price quartiles

local count = 0
foreach depvar of varlist $dep_var_level $dep_var_log {
	
	local count = `count' + 1
	
	if `count'==1 {
		global dep_var_label $dep_var_level_label
	}
	else {
		global dep_var_label $dep_var_log_label
	}
	
	di "`depvar'"
	di "$dep_var_label"
	
	// First quartile
	eststo clear 
	foreach fe of global fes  {
		di "`fe'"
		eststo: reghdfe `depvar' i.$bucket_name##c.$indep_var if price < $p25, absorb(`fe') cluster($cluster)
	}
	esttab using "$TABLES/first_quartile_`depvar'_$tag.tex", ///
		se title("Results for First Quartile of Prices \label{tab: first quartile $dep_var $tag}") ///
		keep(2.$bucket_name#c.$indep_var ///
			 3.$bucket_name#c.$indep_var) ///
		varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
				  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _)
		
	// Second quartile
	eststo clear 
	foreach fe of global fes  {
		di "`fe'"
		eststo: reghdfe `depvar' i.$bucket_name##c.$indep_var if price >= $p25 & price < $p50, absorb(`fe') cluster($cluster)
	}
	esttab using "$TABLES/second_quartile_`depvar'_$tag.tex", ///
		se title("Results for Second Quartile of Prices \label{tab: second quartile $dep_var $tag}") ///
		keep(2.$bucket_name#c.$indep_var ///
			 3.$bucket_name#c.$indep_var) ///
		varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
				  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _)
		
	di "`depvar'"
	// Third quartile
	eststo clear 
	foreach fe of global fes  {
		di "`fe'"
		eststo: reghdfe `depvar' i.$bucket_name##c.$indep_var if price >= $p50 & price < $p75, absorb(`fe') cluster($cluster)
	}
	esttab using "$TABLES/third_quartile_`depvar'_$tag.tex", ///
		se title("Results for Third Quartile of Prices \label{tab: third quartile $dep_var $tag}") ///
		keep(2.$bucket_name#c.$indep_var ///
			 3.$bucket_name#c.$indep_var) ///
		varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
				  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _)
	
	// Fourth quartile
	eststo clear 
	foreach fe of global fes  {
		di "`fe'"
		eststo: reghdfe `depvar' i.$bucket_name##c.$indep_var if price >= $p75, absorb(`fe') cluster($cluster)
	}
	esttab using "$TABLES/fourth_quartile_`depvar'_$tag.tex", ///
		se title("Results for Fourth Quartile of Prices \label{tab: fourth quartile $dep_var $tag}") ///
		keep(2.$bucket_name#c.$indep_var ///
			 3.$bucket_name#c.$indep_var) ///
		varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
				  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _)
}

