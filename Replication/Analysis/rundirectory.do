

cd "/Users/vbp/Dropbox (Personal)/Mac/Documents/Princeton/wealth-housing/Replication/Analysis"

set scheme plotplainblind


// do snowballing 0 0 0 0 0 0 0 0 0 0
// do snowballing 0 0 1 0 0 0 0 0 0 0

do main_regression 0 0 1 0 0 0 0 0 0 0
do main_regression 0 1 1 0 0 0 0 0 0 0
do main_regression 0 0 0 0 0 0 0 0 0 0

// do robustness_checks "differences"
do robustness_checks "levels"

// do main_regression 1 0 0 0 0 0 0 0 0 0
// do main_regression 1 0 1 0 0 0 0 0 0 0


use "$INPUT/full_cleaned_data_with_lags.dta", clear
eststo clear
eststo: reghdfe log_price i.bucket_3##c.interest_rate , absorb(i.location_n##i.date_trans##i.type_n) cluster(date_trans location_n)

eststo: reghdfe log_price i.bucket_3##c.interest_rate if !missing(L_date_trans), absorb(i.location_n##i.date_trans##i.type_n) cluster(date_trans location_n)

eststo: reghdfe log_price i.bucket_3##c.interest_rate , absorb(i.location_n##i.date_trans##i.type_n i.property_id_n) cluster(date_trans location_n)

esttab using "$TABLES/main_regression_with_property_fixed_effect.tex", ///
	se title("Baseline Regression Results With Property Fixed Effect \label{tab: main $tag pidfe}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" ) ///
	gaps replace substitute(\_ _)
	
esttab, ///
	se title("Baseline Regression Results With Property Fixed Effect \label{tab: main $tag pidfe}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" ) ///
	gaps replace substitute(\_ _)

// Parameter 1: Differenced (vs. levels)
// Parameter 2: Restricted (to sample from differenced)
// Parameter 3: Use logs
// Parameter 4: Set properties with duplicate lease durations as missing instead of using mean durations
// Parameter 5: Use only flats
// Parameter 6: Winsorize prices at 1% level 
// Parameter 7: Drop observations with lease length less than 80
// Parameter 8: Remove observations before 2004
// Parameter 9: Only use below median price houses
// Parameter 10: Only use above median price houses

// do main_regression 1 0 0 0 0 0 0 0 0 0
// do main_regression 0 0 0 0 0 0 0 0 0 0

// do main_regression 1 0 1 0 0 0 0 0 0 0
// do main_regression 0 0 1 0 0 0 0 0 0 0

// do main_regression 0 1 0 0 0 0 0 0 0 0
// do main_regression 0 1 1 0 0 0 0 0 0 0
// do main_regression 0 1 0 0 0 0 0 0
// do main_regression 1 0 0 0 1 0 0 0
// do main_regression 0 0 0 0 1 0 0 0

// // Main on differences vs levels (logged and no logs)
// do more_lease_variation 1 0 0 0 0 0 0 0 0 0
// do more_lease_variation 0 0 0 0 0 0 0 0 0 0
// do more_lease_variation 1 0 1 0 0 0 0 0 0 0
// do more_lease_variation 0 0 1 0 0 0 0 0 0 0

// // Restrict levels equation
// do more_lease_variation 0 1 0 0 0 0 0 0 0 0
// do more_lease_variation 0 1 1 0 0 0 0 0 0 0

// // Remove observations with duplicate lease durations
// do more_lease_variation 1 0 0 1 0 0 0 0 0 0
// do more_lease_variation 1 0 1 1 0 0 0 0 0 0
// do more_lease_variation 0 0 0 1 0 0 0 0 0 0
// do more_lease_variation 0 0 1 1 0 0 0 0 0 0

// Remove lease durations under 80
// do more_lease_variation 1 0 0 0 0 0 1 0 0 0
// do more_lease_variation 1 0 1 0 0 0 1 0 0 0
// do more_lease_variation 0 0 0 0 0 0 1 0 0 0
// do more_lease_variation 0 0 1 0 0 0 1 0 0 0

// // Windsorize prices
// do more_lease_variation 1 0 0 0 0 1 0 0 0 0
// do more_lease_variation 1 0 1 0 0 1 0 0 0 0
// do more_lease_variation 0 0 0 0 0 1 0 0 0 0
// do more_lease_variation 0 0 1 0 0 1 0 0 0 0
//
// // Only flats
// do more_lease_variation 1 0 0 0 1 0 0 0 0 0
// do more_lease_variation 1 0 1 0 1 0 0 0 0 0
// do more_lease_variation 0 0 0 0 1 0 0 0 0 0
// do more_lease_variation 0 0 1 0 1 0 0 0 0 0

// // Only years post 2004
// do more_lease_variation 1 0 0 0 0 0 0 1 0 0
// do more_lease_variation 1 0 1 0 0 0 0 1 0 0
// do more_lease_variation 0 0 0 0 0 0 0 1 0 0
// do more_lease_variation 0 0 1 0 0 0 0 1 0 0

// // Only below median price houses
// do more_lease_variation 1 0 0 0 0 0 0 0 1 0
// do more_lease_variation 1 0 1 0 0 0 0 0 1 0
// do more_lease_variation 0 0 0 0 0 0 0 0 1 0
// do more_lease_variation 0 0 1 0 0 0 0 0 1 0
//
// // Only above median price houses
// do more_lease_variation 1 0 0 0 0 0 0 0 0 1
// do more_lease_variation 1 0 1 0 0 0 0 0 0 1
// do more_lease_variation 0 0 0 0 0 0 0 0 0 1
// do more_lease_variation 0 0 1 0 0 0 0 0 0 1
//
// // do snowballing 1 0 0 0 0 0 0
// // do snowballing 1 0 1 0 0 0 0
// do snowballing 0 0 0 0 0 0 0 0 0
// do snowballing 0 0 1 0 0 0 0 0 0
//
// do plot_residuals "levels"
// do plot_residuals "differences"

// do robustness_checks "levels"
// do robustness_checks "differences"


// histogram log_price, frequency xtitle("log(price)")
//
// reghdfe log_price c.lease_duration_at_trans##c.interest_rate, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
//
// sum price, detail
// global p25 = 84000
// global p50 = 147500
// global p75 = 244000
//
// reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price < $p25, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
//
// reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price >= $p25 & price < $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
//
// reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price >= $p50 & price < $p75, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
//
// reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price >= $p75, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
//
// reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price < $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
//
// reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price >= $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
//
//
// reghdfe price c.lease_duration_at_trans##c.interest_rate if price < $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
//
// reghdfe price c.lease_duration_at_trans##c.interest_rate if price >= $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
