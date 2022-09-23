
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
global TABLES "$RESULTS/Tables/More Lease Variation"
global FIGURES "$RESULTS/Figures/More Lease Variation"

* Separate data into finer buckets:
cap drop bucket
gen     bucket = 1 if leasehold & lease_duration_at_trans < 80/1000
replace bucket = 2 if leasehold & lease_duration_at_trans >= 80/1000 & lease_duration_at_trans <  100/1000
replace bucket = 3 if leasehold & lease_duration_at_trans >= 100/1000 & lease_duration_at_trans <  125/1000
replace bucket = 4 if leasehold & lease_duration_at_trans >= 125/1000 & lease_duration_at_trans <  150/1000
replace bucket = 5 if leasehold & lease_duration_at_trans >= 150/1000 & lease_duration_at_trans <= 300/1000
replace bucket = 6 if leasehold & lease_duration_at_trans >= 700/1000
replace bucket = 7 if !leasehold

local count = 1
eststo clear
foreach fe of global fes  {
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	
	* Add FE checkmarks
	local fe_vars "L_year year district city location postcode type price_quint price_dec"
	foreach var of local fe_vars {
		if strpos("`fe'", "`var'") {
			estadd local `var'_fe "$\checkmark", replace
		}
	}

	* Plot results
	cap drop xaxis coeff se ub lb
	gen xaxis = _n if _n <= 7
	gen coeff = .
	gen se = .

	forvalues n=1/7 {
		replace coeff = _b[`n'.bucket#c.$indep_var] if _n == `n'
		replace se = _se[`n'.bucket#c.$indep_var] if _n == `n'
	}

	gen lb = coeff - 1.96*se 
	gen ub = coeff + 1.96*se

	twoway (rarea ub lb xaxis) ///
		   (line coeff xaxis), ///
		   xlabel(1 "Under 80" ///
				  2 "80-100" ///
		   		  3 "100-125" ///
		   		  4 "125-150" ///
		   		  5 "150-300" ///
		   		  6 "700+" ///
		   		  7 "Freehold", angle(45)) ///
		   	yline(0)

	graph export "$FIGURES/non_parametric_variation_fe`count'_$tag.png", replace
	local count = `count' + 1

}

esttab using "$TABLES/non_parametric_variation_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds \label{tab: non parametric variation $tag}") ///
	keep(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var ///
		 7.bucket#c.$indep_var ) ///
	varlabels(2.bucket#c.$indep_var "\multirow{2}{3cm}{80-100 Years x $indep_var_label}" ///
			  3.bucket#c.$indep_var "\multirow{2}{3cm}{100-125 Years x $indep_var_label}" ///
			  4.bucket#c.$indep_var "\multirow{2}{3cm}{125-150 Years x $indep_var_label}" ///
			  5.bucket#c.$indep_var "\multirow{2}{3cm}{150-300 x $indep_var_label}" ///
			  6.bucket#c.$indep_var "\multirow{2}{3cm}{700+ Years x $indep_var_label}" ///
			  7.bucket#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}" ) ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
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
