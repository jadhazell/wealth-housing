local differenced = `1'
local restricted = `2'
local logs = `3'
local duplicate_registration = `4'
local flats = `5'
local windsor = `6'
local under_80 = `7'
local post_2004 = `8'
local below_median_price = `9'
local above_median_price = `10'

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Main Regression"
global TABLES "$RESULTS/Tables"
global FIGURES "$RESULTS/Figures"

// Select correct sample according to parameters
do select_sample `differenced' `restricted' `logs' `duplicate_registration' `flats' `windsor' `under_80' `post_2004' `below_median_price' `above_median_price'

di "Fixed effects:"
di $fes

cap drop restricted_obs_to_use*
local count = 1
eststo clear 
foreach fe of global fes  {
	di "`fe'"
	di "reghdfe $dep_var i.$bucket_name##c.$indep_var, absorb(`fe') cluster($cluster)"
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
	gen restricted_obs_to_use_`count' = e(sample)
	local count = `count'+1
}
esttab using "$TABLES/main_regression_$tag.tex", ///
	se title("Baseline Regression Results \label{tab: main $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _)
//	
// Repeat column 1 using observations from column 2

eststo clear
local fe1 : word 1 of $fes
di "First fixed effect: `fe1'"
di "reghdfe $dep_var i.$bucket_name##c.$indep_var if restricted_obs_to_use, absorb(`fe1') cluster($cluster)"
eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if restricted_obs_to_use_2, absorb(`fe1') cluster($cluster)
esttab using "$TABLES/main_regression_restricted_to_col_2_$tag.tex", ///
	se title("Baseline Regression Results, Without Singleton Observations \label{tab: main $tag restricted col2}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" ) ///
	gaps replace substitute(\_ _)
// Repeat all using same observations for all columns
keep if restricted_obs_to_use_1 & restricted_obs_to_use_2 & restricted_obs_to_use_3 & restricted_obs_to_use_4

eststo clear 
foreach fe of global fes  {
	di "`fe'"
	di "reghdfe $dep_var i.$bucket_name##c.$indep_var, absorb(`fe') cluster($cluster)"
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var, absorb(`fe') cluster($cluster)
}
esttab using "$TABLES/main_regression_fully_restricted_$tag.tex", ///
	se title("Baseline Regression Results \label{tab: main $tag fully restricted}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") ///
	gaps replace substitute(\_ _)
