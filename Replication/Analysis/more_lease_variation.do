
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
global TABLES "$RESULTS/Tables/More Lease Variation"
global FIGURES "$RESULTS/Figures/More Lease Variation"

* Separate data into finer buckets:
cap drop bucket
gen     bucket = 1 if leasehold & lease_duration_at_trans < 100
replace bucket = 2 if leasehold & lease_duration_at_trans >= 100 & lease_duration_at_trans <  125
replace bucket = 3 if leasehold & lease_duration_at_trans >= 125 & lease_duration_at_trans <  150
replace bucket = 4 if leasehold & lease_duration_at_trans >= 150 & lease_duration_at_trans <= 300
replace bucket = 5 if leasehold & lease_duration_at_trans >= 700
replace bucket = 6 if !leasehold

cap drop restricted_obs_to_use*
local count = 1
eststo clear
foreach fe of global fes  {
	eststo: reghdfe $dep_var i.bucket##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
	estadd local fe`count' "$\checkmark$" , replace
	local count = `count' + 1
	
	* Keep track of sample that was used for each regression
	gen restricted_obs_to_use_`count' = e(sample)

	* Plot results
	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n <= 6
	gen coeff = .
	gen se = .

	forvalues n=1/6 {
		replace coeff = _b[`n'.bucket#c.$indep_var] if _n == `n'
		replace se = _se[`n'.bucket#c.$indep_var] if _n == `n'
	}

	gen lb = coeff - 1.96*se 
	gen ub = coeff + 1.96*se

	twoway (rarea ub lb xaxis) ///
		   (line coeff xaxis), ///
		   xlabel(1 "Under 100" ///
		   		  2 "100-125" ///
		   		  3 "125-150" ///
		   		  4 "150-300" ///
		   		  5 "700+" ///
		   		  6 "Freehold", angle(45)) ///
		   	yline(0)

	graph export "$FIGURES/non_parametric_variation_fe`count'_$tag.png"

}

esttab using "$TABLES/non_parametric_variation_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds \label{tab: main continuous regression $tag}") ///
	keep(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var ) ///
	varlabels(2.bucket#c.$indep_var "\multirow{2}{3cm}{100-125 Years x $indep_var_label}" ///
			  3.bucket#c.$indep_var "\multirow{2}{3cm}{125-150 Years x $indep_var_label}" ///
			  4.bucket#c.$indep_var "\multirow{2}{3cm}{150-300 Years x $indep_var_label}" ///
			  5.bucket#c.$indep_var "\multirow{2}{3cm}{700+ Years x $indep_var_label}" ///
			  6.bucket#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}" ) ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(fe1 fe2 fe3 fe4 N, ///
		label("\thead{Freehold $\times$ Location // $\times$ Purchase Date $\times$ Sale Date}" ///
			  "\thead{Freehold $\times$ Location // $\times$ Purchase Date $\times$ Sale Date // $\times$ Type}" ///
			  "\thead{Freehold $\times$ Location // $\times$ Purchase Date $\times$ Sale Date // $\times$ Type $\times$ New Build}" ///
			  "\thead{Freehold $\times$ Location // $\times$ Purchase Date $\times$ Sale Date // $\times$ Type $\times$ New Build // $\times$ Price Quintile By Year}" ///
			  ))

* Repeat for restricted sample

local count = 1
eststo clear
foreach fe of global fes  {
	eststo: reghdfe $dep_var i.bucket##c.$indep_var if restricted_obs_to_use1 & restricted_obs_to_use2 & restricted_obs_to_use3 & restricted_obs_to_use4, absorb(`fe') cluster($cluster)
	estadd local fe`count' "$\checkmark$" , replace
	local count = `count' + 1

	* Plot results
	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n <= 6
	gen coeff = .
	gen se = .

	forvalues n=1/6 {
		replace coeff = _b[`n'.bucket#c.$indep_var] if _n == `n'
		replace se = _se[`n'.bucket#c.$indep_var] if _n == `n'
	}

	gen lb = coeff - 1.96*se 
	gen ub = coeff + 1.96*se

	twoway (rarea ub lb xaxis) ///
		   (line coeff xaxis), ///
		   xlabel(1 "Under 100" ///
		   		  2 "100-125" ///
		   		  3 "125-150" ///
		   		  4 "150-300" ///
		   		  5 "700+" ///
		   		  6 "Freehold", angle(45)) ///
		   	yline(0)

	graph export "$FIGURES/non_parametric_variation_fe`count'_restricted_$tag.png"

}

esttab using "$TABLES/non_parametric_variation_restricted_$tag.tex", ///
	se title("Effect of Interest Rate on Lease Duration and Freeholds \label{tab: main continuous regression $tag}") ///
	keep(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var ) ///
	varlabels(2.bucket#c.$indep_var "\multirow{2}{3cm}{100-125 Years x $indep_var_label}" ///
			  3.bucket#c.$indep_var "\multirow{2}{3cm}{125-150 Years x $indep_var_label}" ///
			  4.bucket#c.$indep_var "\multirow{2}{3cm}{150-300 Years x $indep_var_label}" ///
			  5.bucket#c.$indep_var "\multirow{2}{3cm}{700+ Years x $indep_var_label}" ///
			  6.bucket#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}" ) ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(fe1 fe2 fe3 fe4 N, ///
		label("\thead{Freehold $\times$ Location // $\times$ Purchase Date $\times$ Sale Date}" ///
			  "\thead{Freehold $\times$ Location // $\times$ Purchase Date $\times$ Sale Date // $\times$ Type}" ///
			  "\thead{Freehold $\times$ Location // $\times$ Purchase Date $\times$ Sale Date // $\times$ Type $\times$ New Build}" ///
			  "\thead{Freehold $\times$ Location // $\times$ Purchase Date $\times$ Sale Date // $\times$ Type $\times$ New Build // $\times$ Price Quintile By Year}" ///
			  ))