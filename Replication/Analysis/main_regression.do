
* Get parameters
local differenced = 1
local logs = 1
local restricted = 0
local drop_under_80 = 0
local only_flats = 1

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

if !missing(`"`5'"') {
	local only_flats = `5'
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
do select_sample `differenced' `logs' `restricted' `drop_under_80' `only_flats'

* Define input and output sources
global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Main Regression"
global FIGURES "$RESULTS/Figures/Main Regression"

* Main specification:
* Δ log(price) [i, t, t+h] = α + duration [i, t] + β1 duration [i, t] * Δ rate [t, t+h] + freehold [i] + β2 freehold [i] * Δ rate [t, t+h] + Γ [i, t, t+h] + ε [i, t, t+h]

* Run with log(duration) instead of duration 
global duration_var "lease_duration_at_trans"
global tag "logduration_$tag"

* Run main specification for multiple fixed effect choices:

cap drop obs_to_use
gen obs_to_use = 1
global restriction ""

forvalues i = 1/3 {
	
	* Run first on all data, then only non flats, then only flats
	if `i' == 2 {
		replace obs_to_use = 1 if type != "F"
		replace obs_to_use = 0 if type == "F"
		global restriction "only_nonflats_"
	}
	if `i' == 3 {
		replace obs_to_use = 1 if type == "F"
		replace obs_to_use = 0 if type != "F"
		global restriction "only_flats_"
		
		* Remove type from fixed effects
		global fes `" "i.district_n##i.year##i.L_year" "i.city_n##i.year##i.L_year" "i.location_n##i.year##i.L_year" "i.postcode_n##i.year##i.L_year" "i.district_n##i.year##i.L_year##i.L_price_quint_group" "i.district_n##i.year##i.L_year##i.L_price_dec_group" "'
	}
	
	local count = 1
	eststo clear
	foreach fe of global fes  {
		eststo: reghdfe $dep_var c.$duration_var##c.$indep_var i.freehold##c.$indep_var if obs_to_use, absorb(`fe') cluster($cluster)
		
		local fe_vars "L_year year district city location postcode type price_quint price_dec"
		foreach var of local fe_vars {
			if strpos("`fe'", "`var'") {
				estadd local `var'_fe "\checkmark", replace
			}
		}
		
		local count = `count'+1
	}

	esttab using "$TABLES/main_continuous_regression_$restriction$tag.tex", ///
		se title("Effect of Interest Rate on Lease Duration and Freeholds \label{tab: main continuous regression $restriction $tag}") ///
		keep(c.$duration_var#c.$indep_var ///
			 1.freehold#c.$indep_var) ///
		varlabels(c.$duration_var#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
				  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
		s(L_year_fe year_fe district_fe city_fe location_fe postcode_fe type_fe price_quint_fe price_dec_fe N, ///
			label("Purchase Year" ///
				  "$\times$ Sale Year" ///
				  "$\times$ District" ///
				  "$\times$ City" ///
				  "$\times$ Location" ///
				  "$\times$ Postcode" ///
				  "$\times$ Type" ///
				  "$\times$ Price Quintile" ///
				  "$\times$ Price Decile" ///
				  ))
}


* Run main specification for each type

eststo clear
eststo: reghdfe $dep_var c.$duration_var##c.$indep_var i.freehold##c.$indep_var, absorb(i.district_n##i.year##i.L_year) cluster($cluster)
forvalues i=1/5 {
	eststo: reghdfe $dep_var c.$duration_var##c.$indep_var i.freehold##c.$indep_var if type_n == `i', absorb(i.district_n##i.year##i.L_year) cluster($cluster)
	local fe_vars "L_year year district"
	foreach var of local fe_vars {
		if strpos("`fe'", "`var'") {
			estadd local `var'_fe "\checkmark", replace
		}
	}	
}
esttab using "$TABLES/main_regression_by_type_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds by Property Type \label{tab: main regression by type $tag}") ///
	keep(c.$duration_var#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.$duration_var#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("All" "Detached" "Flats" "Other" "Semi-Detached" "Terraced") gaps replace substitute(\_ _) ///
	s(L_year_fe year_fe district_fe N, ///
		label("Purchase Year" ///
			  "$\times$ Sale Year" ///
			  "$\times$ District" ///
			  ))

			  
* Run quadratic regression
keep if type == "F"
gen duration_x_drate = $duration_var * d_interest_rate
gen duration_x_drate_2 = duration_x_drate^2
gen duration_2 = $duration_var^2


local count = 1
eststo clear
foreach fe of global fes  {
	eststo: reghdfe $dep_var duration_x_drate_2 duration_x_drate $duration_var if leasehold, absorb(`fe') cluster($cluster)
	
	local fe_vars "L_year year district city location postcode type price_quint price_dec"
	foreach var of local fe_vars {
		if strpos("`fe'", "`var'") {
			estadd local `var'_fe "\checkmark", replace
		}
	}
	
	local count = `count'+1
}

esttab using "$TABLES/quadratic_regression_1_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds \label{tab: quadratic regression 1 $tag}") ///
	keep(duration_x_drate_2 ///
		 duration_x_drate) ///
	varlabels(duration_x_drate_2 "\multirow{2}{3cm}{(Lease Duration x $indep_var_label)^2}" ///
			  duration_x_drate_2 "\multirow{2}{3cm}{Lease Duration x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(L_year_fe year_fe district_fe city_fe location_fe postcode_fe type_fe price_quint_fe price_dec_fe N, ///
		label("Purchase Year" ///
			  "$\times$ Sale Year" ///
			  "$\times$ District" ///
			  "$\times$ City" ///
			  "$\times$ Location" ///
			  "$\times$ Postcode" ///
			  "$\times$ Type" ///
			  "$\times$ Price Quintile" ///
			  "$\times$ Price Decile" ///
			  ))	  
			  
local count = 1
eststo clear
foreach fe of global fes  {
	eststo: reghdfe $dep_var $duration_var c.$indep_var#c.$duration_var c.$indep_var#c.duration_2 if leasehold, absorb(`fe') cluster($cluster)
	
	local fe_vars "L_year year district city location postcode type price_quint price_dec"
	foreach var of local fe_vars {
		if strpos("`fe'", "`var'") {
			estadd local `var'_fe "\checkmark", replace
		}
	}
	
	local count = `count'+1
}

esttab using "$TABLES/quadratic_regression_2_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds \label{tab: quadratic regression 2 $tag}") ///
	keep(c.$indep_var#c.duration_2 ///
		 c.$indep_var#c.$duration_var) ///
	varlabels(c.$indep_var#c.duration_2 "\multirow{2}{3cm}{(Lease Duration)^2 x $indep_var_label}" ///
			  c.$indep_var#c.$duration_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(L_year_fe year_fe district_fe city_fe location_fe postcode_fe type_fe price_quint_fe price_dec_fe N, ///
		label("Purchase Year" ///
			  "$\times$ Sale Year" ///
			  "$\times$ District" ///
			  "$\times$ City" ///
			  "$\times$ Location" ///
			  "$\times$ Postcode" ///
			  "$\times$ Type" ///
			  "$\times$ Price Quintile" ///
			  "$\times$ Price Decile" ///
			  ))

* Implicitely calculate freehold duration

reghdfe $dep_var c.d_interest_rate##(c.$duration_var i.freehold), absorb(i.district_n##i.year##i.L_year) cluster($cluster)

global b1 = _b[c.$duration_var]
global b2 = _b[c.d_interest_rate#c.$duration_var]
global b3 = _b[1.freehold]
global b4 = _b[1.freehold#c.d_interest_rate]

replace $duration_var = $b4/$b2 if freehold
reghdfe $dep_var c.d_interest_rate##(c.$duration_var i.freehold), absorb(i.district_n##i.year##i.L_year) cluster($cluster)

* Saturate regression with dummies
gen bucket = 1  if lease_duration_at_trans <= 100/1000
replace bucket = 2  if lease_duration_at_trans  > 100/1000 & lease_duration_at_trans <= 200/1000
replace bucket = 3  if lease_duration_at_trans  > 200/1000 & lease_duration_at_trans <= 300/1000
replace bucket = 4  if lease_duration_at_trans  > 300/1000 & lease_duration_at_trans <= 400/1000
replace bucket = 5  if lease_duration_at_trans  > 400/1000 & lease_duration_at_trans <= 500/1000
replace bucket = 6  if lease_duration_at_trans  > 500/1000 & lease_duration_at_trans <= 600/1000
replace bucket = 7  if lease_duration_at_trans  > 600/1000 & lease_duration_at_trans <= 700/1000
replace bucket = 8  if lease_duration_at_trans  > 700/1000 & lease_duration_at_trans <= 800/1000
replace bucket = 9  if lease_duration_at_trans  > 800/1000 & lease_duration_at_trans <= 900/1000
replace bucket = 10 if lease_duration_at_trans  > 900/1000
replace bucket = . if lease_duration_at_trans > 1000

replace $duration_var = 0 if freehold
reghdfe $dep_var c.d_interest_rate##(c.$duration_var i.freehold) i.bucket, absorb(i.district_n##i.year##i.L_year) cluster($cluster)

replace $duration_var = $b4/$b2 if freehold
reghdfe $dep_var c.d_interest_rate##(c.$duration_var i.freehold) i.bucket, absorb(i.district_n##i.year##i.L_year) cluster($cluster)

forvalues j = 1/10 {
	reghdfe $dep_var c.d_interest_rate##(c.$duration_var i.freehold) `j'.bucket, absorb(i.district_n##i.year##i.L_year) cluster($cluster)
}


* Run main regression by year
replace $duration_var = $b4/$b2 if freehold

gen coeff = .
gen se = .
gen xaxis = _n + 1994 if _n <= 28

forvalues year = 1995/2022 {
	reghdfe $dep_var c.d_interest_rate##c.$duration_var if year==`year', absorb(i.district_n##i.year##i.L_year) cluster($cluster)
	replace coeff = _b[c.d_interest_rate#c.$duration_var] if xaxis == `year'
	replace se = _se[c.d_interest_rate#c.$duration_var] if xaxis == `year'
}

gen ub = coeff + 1.96*se
gen lb = coeff - 1.96*se

twoway (scatter coeff xaxis) (rcap ub lb xaxis), xtitle("Sale Date") ytitle("Regression Coefficient") legend(off)
graph export "$FIGURES/regression_results_over_time_sale.png", replace

* Again by purchase year 
cap drop coeff se xaxis ub lb
gen coeff = .
gen se = .
gen xaxis = _n + 1994 if _n <= 28

forvalues year = 1995/2022 {
	reghdfe $dep_var c.d_interest_rate##c.$duration_var if L_year==`year', absorb(i.district_n##i.year##i.L_year) cluster($cluster)
	replace coeff = _b[c.d_interest_rate#c.$duration_var] if xaxis == `year'
	replace se = _se[c.d_interest_rate#c.$duration_var] if xaxis == `year'
}

gen ub = coeff + 1.96*se
gen lb = coeff - 1.96*se

twoway (scatter coeff xaxis) (rcap ub lb xaxis), xtitle("Purchase Date") ytitle("Regression Coefficient") legend(off)
graph export "$FIGURES/regression_results_over_time_purchase.png", replace
