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

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Robustness Checks"
global FIGURES "$RESULTS/Figures/Robustness Checks"

// Variation within a Street or Building
local count = 0
foreach fe of global fes  {
	
	local count = `count' + 1
	
	if  `count' != 2 {
		continue
	}
	
	local postcode_fe = subinstr("`fe'","i.location_n","i.postcode_n",.)
	di "`postcode_fe'"
	
	
	eststo clear
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var , absorb(`postcode_fe') cluster($cluster)
	
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if type!="F", absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if type!="F", absorb(`postcode_fe') cluster($cluster)
	
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if type=="F", absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if type=="F", absorb(`postcode_fe') cluster($cluster)

	esttab using "$TABLES/continuous_postcode_fixed_effect_fe`count'_$tag.tex", ///
	se title("Variation Within Building \label{tab: postcodefe fe`count' $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("All" "All" "Only Houses" "Only Houses" "Only Flats" "Only Flats") gaps replace substitute(\_ _)
}

* Heterogeneity

xtile years_held_bucket = years_held, nq(2)

egen price_bucket_sale=xtile(price), n(2) by(date_trans)
egen price_bucket_purchase=xtile(L_price), n(2) by(L_date_trans)
egen price_bucket_purchase_loc=xtile(L_price), n(2) by(L_date_trans district)

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1

	if  `count' != 2 {
		continue
	}
	
	eststo clear
	
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if price_bucket_purchase==1, absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if price_bucket_purchase==2, absorb(`fe') cluster($cluster)
	
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if price_bucket_sale==1, absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if price_bucket_sale==2, absorb(`fe') cluster($cluster)
	
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if price_bucket_purchase_loc==1, absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if price_bucket_purchase_loc==2, absorb(`fe') cluster($cluster)
	
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if date_trans < 2007, absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if date_trans >= 2007, absorb(`fe') cluster($cluster)

	esttab using "$TABLES/heterogeneity_fe`count'_$tag.tex", ///
	se title("Heterogeneity \label{tab: heterogeneity fe`count' $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _) ///
	stats(N r2_within, fmt(%9.0fc %9.4fc) labels("N" "Partial R2"))
}

* Check whether years held is correlated with time of sale
binscatter2 years_held date_trans, xtitle("Date of Sale") ytitle("Years Held")
graph export "$FIGURES/years_held_date_trans_scatter.png", replace

* Heterogeneity in years held
cap drop bucket 
gen bucket = 1 if years_held <= 1
replace bucket = 2 if years_held > 1 & years_held <= 3
replace bucket = 3 if years_held > 3 & years_held <= 5
replace bucket = 4 if years_held > 5 & years_held <= 7
replace bucket = 5 if years_held > 7 & years_held <= 9
replace bucket = 6 if years_held > 9 & years_held <= 11
replace bucket = 7 if years_held > 11


foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1

	if  `count' != 2 {
		continue
	}
	
	eststo clear
	forvalues i = 1/7 {
		eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if bucket==`i, absorb(`fe') cluster($cluster)
	}
	
	esttab using "$TABLES/heterogeneity_fe`count'_$tag.tex", ///
	se title("Heterogeneity In Years Held \label{tab: heterogeneity fe`count' $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _) 
	
}

* Minor Robustness Checks

gegen ub = pctile($dep_var), p(97.5)
gegen lb = pctile($dep_var), p(2.5)
gen trim_$dep_var = $dep_var if ($dep_var >= lb & $dep_var <= ub)

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1

	if  `count' != 2 {
		continue
	}
	
	eststo clear
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var, absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if !missing(number_years_missing), absorb(`fe') cluster($cluster)
	eststo: reghdfe trim_$dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var, absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if new=="N", absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if city != "LONDON", absorb(`fe') cluster($cluster)
	

	esttab using "$TABLES/robustness_fe`count'_$tag.tex", ///
	se title("More Robustness Checks \label{tab: heterogeneity fe`count' $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("Baseline" "\shortstack{Drop Multiple \\ Leases}" "\shortstack{Trim House \\ Price Growth}" "\shortstack{Drop New \\ Builds}" "\shortstack{Drop \\ London}") collabels(none) gaps replace substitute(\_ _)
}

*Instrument with monetary shocks

* First stage:

preserve
	use "$WORKING/interest_rates.dta", clear
	
	gen rate_date = year + (quarter-1)/4
	
	twoway (line interest_rate rate_date, yaxis(1)) ///
		   (line cloyne_hurtgen_cum rate_date, yaxis(2))  ///
		   (line cesa_bianchi_cum rate_date, yaxis(2)) if rate_date >= 1995 & rate_date <= 2015, ///
		   xtitle("Quarter") ytitle("Interest Rate") ytitle("Monetary Shock", axis(2)) ///
		   legend(order(1 "Interest Rate" 2 "Cloyne Hurtgen Cumulated Shocks" 3 "Cesa Bianchi Cumulated Shocks") position(6))
	graph export "$FIGURES/interest_rate_monetary_shocks_plot.png", replace
	
	replace rate_date = rate_date * 4
	tsset rate_date
	
	gen d_interest_rate = D.interest_rate 
	gen d_cesa_bianchi_cum = D.cesa_bianchi_cum
	
	eststo clear
	eststo: reghdfe interest_rate cesa_bianchi_cum, cluster($cluster) noabsorb // first stage
	esttab using "$TABLES/iv_first_stage_levels.tex", ///
		se title("IV First Stage \label{tab: iv first stage levels}") ///
		keep(cesa_bianchi_cum) ///
		varlabels(cesa_bianchi_cum "\multirow{2}{4cm}{Cesa Bianchi Monetary Shocks}") ///
		replace substitute(\_ _) mlabels("Interest Rate")
	
	eststo clear
	eststo: reghdfe d_interest_rate d_cesa_bianchi_cum, cluster($cluster) noabsorb // first stage
	esttab using "$TABLES/iv_first_stage_differences.tex", ///
		se title("IV First Stage \label{tab: iv first stage differences}") ///
		keep(cesa_bianchi_cum) ///
		varlabels(cesa_bianchi_cum "\multirow{2}{4cm}{CΔ esa Bianchi Monetary Shocks}") ///
		replace substitute(\_ _) mlabels("Δ Interest Rate")
	
restore

* Second stage:

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1
	
	if  `count' != 2 {
		continue
	}
	
	eststo clear
	
	// Reduced form
	eststo: reghdfe $dep_var i.$bucket_name##c.$iv_var , absorb(`fe') cluster($cluster)
	
	// Structural equation
	eststo: ivreghdfe $dep_var (2.$bucket_name#c.$indep_var 3.$bucket_name#c.$indep_var = 2.$bucket_name#c.$iv_var 3.$bucket_name#c.$iv_var), absorb(i.$bucket_name `fe') cluster($cluster)
estadd scalar KP_stat = e(rkf)

	esttab using "$TABLES/monetary_shock_fe`count'_$tag.tex", ///
	se title("Monetary Shock Specification \label{tab: monetary shock fe`count' $tag}") ///
	keep(2.$bucket_name#c.$iv_var ///
		 3.$bucket_name#c.$iv_var ///
		 2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$iv_var "\multirow{2}{4cm}{High Duration x $iv_var_label}" ///
			  3.$bucket_name#c.$iv_var "\multirow{2}{4cm}{Freehold x $iv_var_label}" ///
			  2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("Reduced Form" "IV") gaps replace substitute(\_ _)
	
	esttab, ///
	se title("Monetary Shock Specification \label{tab: monetary shock fe`count' $tag}") ///
	keep(2.$bucket_name#c.$iv_var ///
		 3.$bucket_name#c.$iv_var ///
		 2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$iv_var "\multirow{2}{4cm}{High Duration x $iv_var_label}" ///
			  3.$bucket_name#c.$iv_var "\multirow{2}{4cm}{Freehold x $iv_var_label}" ///
			  2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("Reduced Form" "IV") gaps replace substitute(\_ _)
}
