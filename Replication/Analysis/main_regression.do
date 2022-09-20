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
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Main Regression"
global FIGURES "$RESULTS/Figures/Main Regression"

// // Select correct sample according to parameters
// do select_sample `differenced' `restricted' `logs' `duplicate_registration' `flats' `windsor' `under_80' `post_2004' `below_median_price' `above_median_price'
//
// di "Fixed effects:"
// di $fes
//
// cap drop restricted_obs_to_use*
// local count = 1
// eststo clear 
// foreach fe of global fes  {
//	
// 	di "`fe'"
// 	di "reghdfe $dep_var i.$bucket_name##c.$indep_var, absorb(`fe') cluster($cluster)"
// 	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
// 	gen restricted_obs_to_use_`count' = e(sample)
// 	local count = `count'+1
//	
// 	* Add fixed effect checkmarks
// 	if strpos("`fe'", "location_n") {
// 		estadd local location_fe "$\checkmark$" , replace
// 		di "Added location FE!"
// 	}
// 	if strpos("`fe'", "L_date_trans") {
// 		estadd local purchase_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe'", "date_trans") {
// 		estadd local sale_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe'", "type") {
// 		estadd local type_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe'", "price_quintile") {
// 		estadd local price_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe'", "i.location_n##i.$bucket_name") {
// 		estadd local location_bucket_fe "$\checkmark$" , replace
// 	}
//	
// }
// esttab using "$TABLES/main_regression_$tag.tex", ///
// 	se title("Baseline Regression Results, $title \label{tab: main $tag}") ///
// 	keep(2.$bucket_name#c.$indep_var ///
// 		 3.$bucket_name#c.$indep_var) ///
// 	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
// 			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
// 	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
// 	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
// 		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
// //	
// // Repeat column 1 using observations from column 2
//
// eststo clear
// local fe1 : word 1 of $fes
// di "First fixed effect: `fe1'"
// di "reghdfe $dep_var i.$bucket_name##c.$indep_var if restricted_obs_to_use, absorb(`fe1') cluster($cluster)"
// eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if restricted_obs_to_use_2, absorb(`fe1') cluster($cluster)
// 	if strpos("`fe1'", "location_n") {
// 		estadd local location_fe "$\checkmark$" , replace
// 		di "Added location FE!"
// 	}
// 	if strpos("`fe1'", "L_date_trans") {
// 		estadd local purchase_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe1'", "date_trans") {
// 		estadd local sale_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe1'", "type") {
// 		estadd local type_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe1'", "price_quintile") {
// 		estadd local price_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe1'", "i.location_n##i.$bucket_name") {
// 		estadd local location_bucket_fe "$\checkmark$" , replace
// 	}
// esttab using "$TABLES/main_regression_restricted_to_col_2_$tag.tex", ///
// 	se title("Baseline Regression Results, $title (Restricted to Column 2 Obs) \label{tab: main $tag restricted col2}") ///
// 	keep(2.$bucket_name#c.$indep_var ///
// 		 3.$bucket_name#c.$indep_var) ///
// 	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
// 			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
// 	mlabels("$dep_var_label" ) ///
// 	gaps replace substitute(\_ _) ///
// 	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
// 		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
// // Repeat all using same observations for all columns
// preserve
// keep if restricted_obs_to_use_1 & restricted_obs_to_use_2 & restricted_obs_to_use_3 & restricted_obs_to_use_4
//
// eststo clear 
// local count = 1
// foreach fe of global fes  {
//	
// 	di "`fe'"
// 	di "reghdfe $dep_var i.$bucket_name##c.$indep_var, absorb(`fe') cluster($cluster)"
// 	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var, absorb(`fe') cluster($cluster)
// 	local count = `count' + 1
// 	if strpos("`fe'", "location_n") {
// 		estadd local location_fe "$\checkmark$" , replace
// 		di "Added location FE!"
// 	}
// 	if strpos("`fe'", "L_date_trans") {
// 		estadd local purchase_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe'", "date_trans") {
// 		estadd local sale_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe'", "type") {
// 		estadd local type_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe'", "price_quintile") {
// 		estadd local price_fe "$\checkmark$" , replace
// 	}
// 	if strpos("`fe'", "i.location_n##i.$bucket_name") {
// 		estadd local location_bucket_fe "$\checkmark$" , replace
// 	}
// }
// esttab using "$TABLES/main_regression_fully_restricted_$tag.tex", ///
// 	se title("Baseline Regression Results, $title (Same Observations Across Columns) \label{tab: main $tag fully restricted}") ///
// 	keep(2.$bucket_name#c.$indep_var ///
// 		 3.$bucket_name#c.$indep_var) ///
// 	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
// 			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
// 	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") ///
// 	gaps replace substitute(\_ _) ///
// 	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
// 		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
//  restore
	

* Interact new build with other fixed effects
cap egen new_n = group(new)
local count = 1
eststo clear 
foreach fe of global fes  {
	
	di "i.new_n##``fe'"
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if obs_to_use`count', absorb(i.new_n##`fe') cluster($cluster)
	
	if strpos("`fe'", "location_n") {
		estadd local location_fe "$\checkmark$" , replace
		di "Added location FE!"
	}
	if strpos("`fe'", "L_date_trans") {
		estadd local purchase_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "date_trans") {
		estadd local sale_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "type") {
		estadd local type_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "price_quintile") {
		estadd local price_fe "$\checkmark$" , replace
	}
	estadd local new_fe "$\checkmark$" , replace
	if strpos("`fe'", "i.location_n##i.$bucket_name") {
		estadd local location_bucket_fe "$\checkmark$" , replace
	}
	
}
esttab using "$TABLES/main_regression_with_newfe_$tag.tex", ///
	se title("Baseline Regression Results With New-Build Fixed Effect, $title \label{tab: main new fixed effect $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe new_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "New Build FE" "Location x Bucket FE"))
	
	
* Continuous regression

cap drop restricted_obs_to_use*

* Make indep var smaller so that coefficient is closer to 1
replace lease_duration_at_trans = lease_duration_at_trans / 1000

local count = 1
eststo clear 
foreach fe of global fes  {
	
	di "`fe'"
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
	gen restricted_obs_to_use_`count' = e(sample)
	local count = `count'+1
	if strpos("`fe'", "location_n") {
		estadd local location_fe "$\checkmark$" , replace
		di "Added location FE!"
	}
	if strpos("`fe'", "L_date_trans") {
		estadd local purchase_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "date_trans") {
		estadd local sale_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "type") {
		estadd local type_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "price_quintile") {
		estadd local price_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "i.location_n##i.$bucket_name") {
		estadd local location_bucket_fe "$\checkmark$" , replace
	}
}
esttab using "$TABLES/continuous_regression_$tag.tex", ///
	se title("Continuous Duration Regression Results, $title \label{tab: continuous $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
	
preserve 
	keep if restricted_obs_to_use_1 & restricted_obs_to_use_2 & restricted_obs_to_use_3 & restricted_obs_to_use_4
	
	local count = 1
	eststo clear 
	foreach fe of global fes  {
		
		di "`fe'"
		eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
		local count = `count'+1
		
	if strpos("`fe'", "location_n") {
		estadd local location_fe "$\checkmark$" , replace
		di "Added location FE!"
	}
	if strpos("`fe'", "L_date_trans") {
		estadd local purchase_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "date_trans") {
		estadd local sale_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "type") {
		estadd local type_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "price_quintile") {
		estadd local price_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "i.location_n##i.$bucket_name") {
		estadd local location_bucket_fe "$\checkmark$" , replace
	}
		
	}
	esttab using "$TABLES/continuous_regression_fully_restricted_$tag.tex", ///
		se title("Continuous Duration Regression Results, (Same Observations Across Columns) \label{tab: continuous fully restricted $tag}") ///
		keep(c.lease_duration_at_trans#c.$indep_var) ///
		varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}") ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
		s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
	
restore
	
* Repeat continuous regression, but include freeholds as having lease duration = 1000
replace lease_duration_at_trans = 1 if !leasehold
local count = 1
eststo clear 
foreach fe of global fes  {
	
	di "`fe'"
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
	local count = `count'+1
	
	if strpos("`fe'", "location_n") {
		estadd local location_fe "$\checkmark$" , replace
		di "Added location FE!"
	}
	if strpos("`fe'", "L_date_trans") {
		estadd local purchase_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "date_trans") {
		estadd local sale_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "type") {
		estadd local type_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "price_quintile") {
		estadd local price_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "i.location_n##i.$bucket_name") {
		estadd local location_bucket_fe "$\checkmark$" , replace
	}
	
}
esttab using "$TABLES/continuous_regression_with_freeholds_$tag.tex", ///
	se title("Continuous Duration Regression Results Including Freeholds As Duration=1000 \label{tab: continuous with freeholds $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))

	
* Continuous leasehold + freehold as dummy

gen freehold = !leasehold

local count = 1
eststo clear 
foreach fe of global fes  {
	
	di "`fe'"
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
	local count = `count'+1
	
	if strpos("`fe'", "location_n") {
		estadd local location_fe "$\checkmark$" , replace
		di "Added location FE!"
	}
	if strpos("`fe'", "L_date_trans") {
		estadd local purchase_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "date_trans") {
		estadd local sale_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "type") {
		estadd local type_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "price_quintile") {
		estadd local price_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "i.location_n##i.$bucket_name") {
		estadd local location_bucket_fe "$\checkmark$" , replace
	}
	
}
esttab using "$TABLES/continuous_regression_with_freeholds_as_dummy$tag.tex", ///
	se title("Continuous Duration Regression Results + Freehold Dummy \label{tab: continuous with freeholds dummy $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
		
* Continuous leasehold + freehold as dummy, with baseline freehold duration = 0

replace lease_duration_at_trans = 0 if freehold

local count = 1
eststo clear 
foreach fe of global fes  {
	
	di "`fe'"
	eststo: reghdfe $dep_var c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
	local count = `count'+1
	
	if strpos("`fe'", "location_n") {
		estadd local location_fe "$\checkmark$" , replace
		di "Added location FE!"
	}
	if strpos("`fe'", "L_date_trans") {
		estadd local purchase_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "date_trans") {
		estadd local sale_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "type") {
		estadd local type_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "price_quintile") {
		estadd local price_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "i.location_n##i.$bucket_name") {
		estadd local location_bucket_fe "$\checkmark$" , replace
	}
	
}
esttab using "$TABLES/continuous_regression_with_freeholds_as_dummy_baseline_zero$tag.tex", ///
	se title("Continuous Duration Regression Results + Freehold Dummy (Freehold Duration = 0) \label{tab: continuous with freeholds dummy baseline zero $tag}") ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
	
* Main regression with different types of price quintile fixed effects

global price_quintile_fes `"  "i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.price_quintile_sale##i.type_n" "'

local count = 1
eststo clear 
foreach fe of global price_quintile_fes  {
	
	di "`fe'"
	di "reghdfe $dep_var i.$bucket_name##c.$indep_var, absorb(`fe') cluster($cluster)"
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)
	
	* Add fixed effects check marks
	if strpos("`fe'", "location_n") {
		estadd local location_fe "$\checkmark$" , replace
		di "Added location FE!"
	}
	if strpos("`fe'", "L_date_trans") {
		estadd local purchase_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "date_trans") {
		estadd local sale_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "type") {
		estadd local type_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "i.price_quintile#") {
		estadd local price_fe "$\checkmark$" , replace
	}
	if strpos("`fe'", "price_quintile_sale") {
		estadd local sale_price_fe "$\checkmark$" , replace
	}
	
	local count = `count'+1
}
esttab using "$TABLES/price_quintile_fes_$tag.tex", ///
	se title("Baseline Regression With Different Price Quintile Fixed Effexts \label{tab: main price quintile fes $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe sale_price_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Purchase Price Quintile FE" "Sale Price Quintile FE"))
