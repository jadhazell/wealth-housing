
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
	local differenced = `3'
}

if !missing(`"`4'"') {
	local differenced = `4'
}

* Get data
do select_sample `differenced' `logs' `restricted' `drop_under_80'

* Define input and output sources
global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Main Regression"
global FIGURES "$RESULTS/Figures/Main Regression"

* Main specification:
* Δ log(price) [i, t, t+h] = α + duration [i, t] + β1 duration [i, t] * Δ rate [t, t+h] + freehold [i] + β2 freehold [i] * Δ rate [t, t+h] + Γ [i, t, t+h] + ε [i, t, t+h]

* Run main specification for multiple fixed effect choices:

gen obs_to_use = 1
global restriction ""

forvalues i = 1/3 {
	
	* Run first on all data, then only flats, then only non flats
	if `i' == 2 {
		replace obs_to_use = 1 if type == "F"
		replace obs_to_use = 0 if type != "F"
		global restriction "_only_flats"
	}
	if `i' == 2 {
		replace obs_to_use = 1 if type != "F"
		replace obs_to_use = 0 if type == "F"
		global restriction "_only_nonflats"
	}

	local count = 1
	eststo clear
	foreach fe of global fes  {
		eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if obs_to_use, absorb(`fe') cluster($cluster)
		
		local fe_vars "L_year year district city location postcode type price_quint price_dec"
		foreach var of local fe_vars {
			if strpost(`fe', "`var'") {
				estadd local `var'_fe "$\checkmark", replace
			}
		}
		
		local count = `count'+1
	}

	esttab using "$TABLES/main_continuous_regression_$restriction$tag.tex", ///
		se title("Effect of Interest Rate on Lease Duration and Freeholds \label{tab: main continuous regression $restriction $tag}") ///
		keep(c.lease_duration_at_trans#c.$indep_var ///
			 1.freehold#c.$indep_var) ///
		varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
				  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
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
eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var, absorb(i.district_n##i.year##i.L_year) cluster($cluster)
forvalues i=1/5 {
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if type_n == `i', absorb(i.district_n##i.year##i.L_year) cluster($cluster)
	local fe_vars "L_year year district"
	foreach var of local fe_vars {
		if strpost(`fe', "`var'") {
			estadd local `var'_fe "$\checkmark", replace
		}
	}	
}
esttab using "$TABLES/main_regression_by_type_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds by Property Type \label{tab: main regression by type $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("All" "Detached" "Flats" "Other" "Semi-Detached" "Terraced") gaps replace substitute(\_ _) ///
	s(L_year_fe year_fe district_fe N, ///
		label("Purchase Year" ///
			  "$\times$ Sale Year" ///
			  "$\times$ District" ///
			  ))
