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

do select_sample `differenced' `restricted' `logs' `duplicate_registration' `flats' `windsor' `under_80' `post_2004' `below_median_price' `above_median_price'

// Merge in leads and lags 
if `differenced'{
	cap drop _merge
	merge m:1 date_trans using "$WORKING/interest_rates_leads.dta"
	keep if _merge==3
	cap drop _merge
	merge m:1 L_date_trans using "$WORKING/interest_rates_lags.dta"
	keep if _merge==3
	cap drop _merge
}

else{
	cap drop _merge
	merge m:1 date_trans using "$WORKING/interest_rates_leads.dta"
	keep if _merge==3
	cap drop _merge
	merge m:1 date_trans using "$WORKING/interest_rates_lags.dta"
	keep if _merge==3
	cap drop _merge
}

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Robustness Checks"
global FIGURES "$RESULTS/Figures/Robustness Checks"

* Test of Identification Assumption: Pre-Trends and Post-Trends 

* Use leads/lags with window = h 
gen h = (date_trans - L_date_trans)*4

gen interest_rate_lead = .
gen interest_rate_lag = .

forvalues i = 1/110 {
	cap replace interest_rate_lead = DF`i'_$indep_var if h == `i'
	cap replace interest_rate_lag = DL`i'_$indep_var if h == `i'
}

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1
	
	if  `count' != 2 {
		continue
	}
	
	eststo clear
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var i.$bucket_name##c.interest_rate_lag , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var i.$bucket_name##c.interest_rate_lead , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var i.$bucket_name##c.interest_rate_lag i.$bucket_name##c.interest_rate_lead, absorb(`fe') cluster($cluster)
	
	esttab using "$TABLES/pre_and_post_trends_h_window_fe`count'_$tag.tex", ///
	se title("Pre and Post Trends With Window = h \label{tab: pre and post trends window h fe`count' $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var ///
		 2.$bucket_name#c.interest_rate_lag ///
		 3.$bucket_name#c.interest_rate_lag ///
		 2.$bucket_name#c.interest_rate_lead ///
		 3.$bucket_name#c.interest_rate_lead ) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}" ///
			  2.$bucket_name#c.interest_rate_lag "\multirow{2}{4cm}{High Duration x Lag $indep_var_label}" ///
			  3.$bucket_name#c.interest_rate_lag "\multirow{2}{4cm}{Freehold x Lag $indep_var_label}" ///
			  2.$bucket_name#c.interest_rate_lead "\multirow{2}{4cm}{High Duration x Lead $indep_var_label}" ///
			  3.$bucket_name#c.interest_rate_lead "\multirow{2}{4cm}{Freehold x Lead $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
}

* Use leads/lags with window = 1
local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1
	
	if  `count' != 2 {
		continue
	}
	
	eststo clear
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var i.$bucket_name##c.L1_$indep_var , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var i.$bucket_name##c.F2_$indep_var , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var i.$bucket_name##c.L1_$indep_var i.$bucket_name##c.F2_$indep_var , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var ///
				    i.$bucket_name##c.L1_$indep_var ///
					i.$bucket_name##c.L2_$indep_var ///
					i.$bucket_name##c.L3_$indep_var ///
					i.$bucket_name##c.L4_$indep_var ///
					i.$bucket_name##c.L5_$indep_var ///
					i.$bucket_name##c.L6_$indep_var ///
					i.$bucket_name##c.L7_$indep_var ///
					i.$bucket_name##c.L8_$indep_var , ///
					absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var ///
					i.$bucket_name##c.F2_$indep_var ///
					i.$bucket_name##c.F3_$indep_var ///
					i.$bucket_name##c.F4_$indep_var ///
					i.$bucket_name##c.F5_$indep_var ///
					i.$bucket_name##c.F6_$indep_var ///
					i.$bucket_name##c.F7_$indep_var ///
					i.$bucket_name##c.F8_$indep_var , ///
					absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var ///
				    i.$bucket_name##c.L1_$indep_var ///
					i.$bucket_name##c.L2_$indep_var ///
					i.$bucket_name##c.L3_$indep_var ///
					i.$bucket_name##c.L4_$indep_var ///
					i.$bucket_name##c.L5_$indep_var ///
					i.$bucket_name##c.L6_$indep_var ///
					i.$bucket_name##c.L7_$indep_var ///
					i.$bucket_name##c.L8_$indep_var ///
					i.$bucket_name##c.F2_$indep_var ///
					i.$bucket_name##c.F3_$indep_var ///
					i.$bucket_name##c.F4_$indep_var ///
					i.$bucket_name##c.F5_$indep_var ///
					i.$bucket_name##c.F6_$indep_var ///
					i.$bucket_name##c.F7_$indep_var ///
					i.$bucket_name##c.F8_$indep_var , ///
					absorb(`fe') cluster($cluster)
	
	esttab using "$TABLES/pre_and_post_trends_fe`count'_$tag.tex", ///
	se title("Pre and Post Trends \label{tab: pre and post trends fe`count' $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var ///
		 2.$bucket_name#c.L1_$indep_var ///
		 3.$bucket_name#c.L1_$indep_var ///
		 2.$bucket_name#c.F2_$indep_var ///
		 3.$bucket_name#c.F2_$indep_var ) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}" ///
			  2.$bucket_name#c.L1_$indep_var "\multirow{2}{4cm}{High Duration x Lag $indep_var_label}" ///
			  3.$bucket_name#c.L1_$indep_var "\multirow{2}{4cm}{Freehold x Lag $indep_var_label}" ///
			  2.$bucket_name#c.F2_$indep_var "\multirow{2}{4cm}{High Duration x Lead $indep_var_label}" ///
			  3.$bucket_name#c.F2_$indep_var "\multirow{2}{4cm}{Freehold x Lead $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
}
