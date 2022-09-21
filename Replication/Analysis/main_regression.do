
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

cap drop restricted_obs_to_use*
local count = 1
eststo clear
foreach fe of global fes  {
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
	estadd local fe`count' "$\checkmark$" , replace
	
	* Keep track of sample that was used for each regression
	gen restricted_obs_to_use_`count' = e(sample)
	local count = `count' + 1
}

esttab using "$TABLES/main_continuous_regression_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds \label{tab: main continuous regression $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(fe1 fe2 fe3 fe4 N, ///
		label("\thead{District // $\times$ Purchase Year $\times$ Sale Year}" ///
			  "\thead{District // $\times$ Purchase Year $\times$ Sale Year // $\times$ Type}" ///
			  "\thead{District // $\times$ Purchase Year $\times$ Sale Year // $\times$ Type $\times$ New Build}" ///
			  "\thead{District // $\times$ Purchase Year $\times$ Sale Year // $\times$ Type $\times$ New Build // $\times$ Price Quintile By Year}" ///
			  ))

* Run main specification on restricted sample:

local count = 1
eststo clear
foreach fe of global fes  {
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if restricted_obs_to_use_1 & restricted_obs_to_use_2 & restricted_obs_to_use_3 & restricted_obs_to_use_4, absorb(`fe') cluster($cluster)
	estadd local fe`count' "$\checkmark$" , replace
	local count = `count' + 1
}

esttab using "$TABLES/main_continuous_regression_restricted_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds, Restricted Sample \label{tab: main continuous regression restricted sample $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(fe1 fe2 fe3 fe4 N, ///
		label("\thead{District // $\times$ Purchase Year $\times$ Sale Year}" ///
			  "\thead{District // $\times$ Purchase Year $\times$ Sale Year // $\times$ Type}" ///
			  "\thead{District // $\times$ Purchase Year $\times$ Sale Year // $\times$ Type $\times$ New Build}" ///
			  "\thead{District // $\times$ Purchase Year $\times$ Sale Year // $\times$ Type $\times$ New Build // $\times$ Price Quintile By Year}" ///
			  ))

* Run main specification, but use less fixed effects:
global limited_fes `" "i.district_n" "i.district_n##i.L_year" "i.district_n##i.year" "i.district_n##i.year##i.L_year" "i.district_n##i.year##i.L_year##i.flat" "'

cap drop restricted_obs_to_use*
local count = 1
eststo clear
eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var, noabsorb cluster($cluster)
foreach fe of global fes  {
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var, absorb(`fe') cluster($cluster)
	estadd local fe`count' "$\checkmark$" , replace
	
	* Keep track of sample that was used for each regression
	gen restricted_obs_to_use_`count' = e(sample)
	
	local count = `count' + 1
}

esttab using "$TABLES/main_continuous_regression_less_fes_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds, Less FEs \label{tab: main continuous regression $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(fe1 fe2 fe3 fe4 N, ///
		label("\thead{District}" ///
			  "\thead{District // $\times$ Purchase Year}" ///
			  "\thead{District // $\times$ Sale Year}" ///
			  "\thead{District // $\times$ Purchase Year $\times$ Sale Year}" ///
			  "\thead{District // $\times$ Purchase Year $\times$ Sale Year // $\times$ Is Flat}" ///
			  ))

* Again restrict sample
local count = 1
eststo clear
eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var, noabsorb cluster($cluster)
foreach fe of global fes  {
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if estricted_obs_to_use_1 & restricted_obs_to_use_2 & restricted_obs_to_use_3 & restricted_obs_to_use_4, absorb(`fe') cluster($cluster)
	estadd local fe`count' "$\checkmark$" , replace
	local count = `count' + 1
	
	* Keep track of sample that was used for each regression
	gen restricted_obs_to_use_`count' = e(sample)
}

esttab using "$TABLES/main_continuous_regression_less_fes_restricted_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds, Less FEs + Restricted Sample \label{tab: main continuous regression $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(fe1 fe2 fe3 fe4 N, ///
		label("\thead{District}" ///
			  "\thead{District // $\times$ Purchase Year}" ///
			  "\thead{District // $\times$ Sale Year}" ///
			  "\thead{District // $\times$ Purchase Year $\times$ Sale Year}" ///
			  ))
