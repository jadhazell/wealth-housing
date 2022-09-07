global tag `1'

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Robustness Checks"
global TABLES "$RESULTS/Tables"
global FIGURES "$RESULTS/Figures"

// use "$WORKING/interest_rates.dta", clear
// keep year quarter L*
// gen L_date_trans = year + (quarter-1)/4
// gen date_trans = L_date_trans
// save "$WORKING/interest_rates_lags.dta", replace
//
// use "$WORKING/interest_rates.dta", clear
// keep year quarter F*
// gen date_trans = year + (quarter-1)/4
// save "$WORKING/interest_rates_leads.dta", replace

///////////////////////////////////////////////////////////////////////////
// Replicate using Joe's data
///////////////////////////////////////////////////////////////////////////
// use "$WORKING/jad_quarterly_data.dta", clear
// global tag "jh_data"
//
// global bucket_name bucket_3
//
// global dep_var d_log_price
// global dep_var_label "$\Delta$ Log(Price)"
//
// global indep_var d_interest_rate
// global indep_var_label "$\Delta$ Interest Rate"
//
// global iv_var d_cesa_bianchi
// global iv_var_label "$\Delta$ Monetary Shock"
//
// global fes `" "i.location_n##i.date_trans##i.L_date_trans" "i.location_n##i.date_trans##i.L_date_trans##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.$bucket_name"  "'
// global cluster "date_trans L_date_trans location_n"

///////////////////////////////////////////////////////////////////////////
// Replicate using differenced data (raw)
///////////////////////////////////////////////////////////////////////////
// use "$OUTPUT/full_cleaned_data_with_lags.dta", clear
//
// xtile bucket_3 = L_lease_duration_at_trans, nq(2)
// replace bucket_3 = 3 if !leasehold
//
// cap egen postcode_n = group(postcode)
// gen years_held = date_trans - L_date_trans
//
// global tag "differences_full"
//
// cap gen d_cesa_bianchi = cesa_bianchi_cum - L_cesa_bianchi_cum
// global iv_var d_cesa_bianchi
// global iv_var_label "$\Delta$ Monetary Shock"

///////////////////////////////////////////////////////////////////////////
// Replicate using level data
///////////////////////////////////////////////////////////////////////////
if "$tag" == "levels" {
	do select_sample 0 0 1 0 0 0 0 0 0 0
}

if "$tag" == "differences" {
	do select_sample 1 0 1 0 0 0 0 0 0 0
}

di "TAG: $tag"
// 

// Non Parametric Variation

// Test of Identification Assumption: Pre-Trends and Post-Trends

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1
	
	if  `count' != 2 {
		continue
	}
	
	eststo clear
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var i.$bucket_name##c.L1_$indep_var i.$bucket_name##c.F2_$indep_var , absorb(`fe') cluster($cluster)
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
	
	esttab, ///
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
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) nolabel
}

// Variation within a Street or Building
local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1
	
	if  `count' != 5 {
		continue
	}
	
	local postcode_fe = subinstr("`fe'","i.location_n","i.postcode_n",.)
	di "`postcode_fe'"
	
	
	eststo clear
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var , absorb(`postcode_fe') cluster($cluster)
	
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if type!="F", absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if type!="F", absorb(`postcode_fe') cluster($cluster)
	
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if type=="F", absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if type=="F", absorb(`postcode_fe') cluster($cluster)

	esttab using "$TABLES/postcode_fixed_effect_fe`count'_$tag.tex", ///
	se title("Variation Within Building \label{tab: postcodefe fe`count' $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{3cm}{High Duration x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("All" "All" "Only Houses" "Only Houses" "Only Flats" "Only Flats") gaps replace substitute(\_ _)
	
	esttab, ///
	se title("Variation Within Building \label{tab: postcodefe fe`count' $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{3cm}{High Duration x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("All" "All" "Only Houses" "Only Houses" "Only Flats" "Only Flats") gaps replace substitute(\_ _)
}

// Heterogeneity

xtile years_held_bucket = years_held, nq(2)
xtile price_bucket = price, nq(2)

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1

	if  `count' != 5 {
		continue
	}
	
	eststo clear
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if years_held_bucket==1 & !missing(years_held), absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if years_held_bucket==2 & !missing(years_held), absorb(`fe') cluster($cluster)
	
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if price_bucket==1, absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if price_bucket==2, absorb(`fe') cluster($cluster)
	
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if date_trans < 2007, absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if date_trans >= 2007, absorb(`fe') cluster($cluster)

	esttab using "$TABLES/heterogeneity_fe`count'_$tag.tex", ///
	se title("Heterogeneity \label{tab: heterogeneity fe`count' $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{3cm}{High Duration x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _) ///
	stats(N r2_within, fmt(%9.0fc %9.4fc) labels("N (excl. singletons)" "Partial R2"))
	
	esttab, ///
	se title("Heterogeneity \label{tab: heterogeneity fe`count' $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _) 
}

// Minor Robustness Checks
gen lease_duration_missing = lease_duration_at_trans if !missing(number_years_missing)
xtile bucket_3_missing = lease_duration_missing, nq(2)
replace bucket_3_missing = 3 if !leasehold 

gegen ub = pctile($dep_var), p(97.5)
gegen lb = pctile($dep_var), p(2.5)
gen trim_$dep_var = $dep_var if ($dep_var >= lb & $dep_var <= ub)

xtile bucket_3_old = lease_duration_at_trans if new=="N", nq(2)
replace bucket_3_old = 3 if !leasehold & new=="N"

xtile bucket_3_80_plus = lease_duration_at_trans if lease_duration_at_trans >= 80, nq(2)
replace bucket_3_80_plus = 3 if !leasehold 

xtile bucket_3_no_london = lease_duration_at_trans if city != "LONDON", nq(2)
replace bucket_3_no_london = 3 if !leasehold & city != "LONDON"

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1

	if  `count' != 5 {
		continue
	}
	
	eststo clear
	cap drop bucket
	gen bucket = $bucket_name
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_3_missing
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = $bucket_name
	eststo: reghdfe trim_$dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_3_old
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_3_80_plus
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_3_no_london
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	

	esttab using "$TABLES/robustness_fe`count'_$tag.tex", ///
	se title("More Robustness Checks \label{tab: heterogeneity fe`count' $tag}") ///
	keep(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var) ///
	varlabels(2.bucket#c.$indep_var "\multirow{2}{3cm}{High Duration x $indep_var_label}" ///
			  3.bucket#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("Baseline" "\shortstack{Drop Multiple \\ Leases}" "\shortstack{Trim House \\ Price Growth}" "\shortstack{Drop New \\ Builds}" "\shortstack{Drop Leases \\ Less Than \\ 80 Years}" "\shortstack{Drop \\ London}") collabels(none) gaps replace substitute(\_ _)
}


// More lease variation

cap drop bucket_4 bucket_5 bucket_6 bucket_7 bucket_8

xtile bucket_4 = lease_duration_at_trans, nq(3)
replace bucket_4 = 4 if !leasehold

xtile bucket_5 = lease_duration_at_trans, nq(4)
replace bucket_5 = 5 if !leasehold

cap xtile bucket_6 = lease_duration_at_trans, nq(5)
replace bucket_6 = 6 if !leasehold

xtile bucket_7 = lease_duration_at_trans, nq(6)
replace bucket_7 = 7 if !leasehold

xtile bucket_8 = lease_duration_at_trans, nq(7)
replace bucket_8 = 8 if !leasehold

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1

	if  `count' != 5 {
		continue
	}
	
	eststo clear
	cap drop bucket
	gen bucket = $bucket_name
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_4
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_5
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_6
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_7
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_8
	eststo: reghdfe $dep_var i.bucket##c.$indep_var, absorb(`fe') cluster($cluster)

	esttab using "$TABLES/more_variation_fe`count'_$tag.tex", ///
	se title("More Lease Variation \label{tab: more variation fe`count' $tag}") ///
	keep(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var ///
		 7.bucket#c.$indep_var ///
		 8.bucket#c.$indep_var) ///
	varlabels(2.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 2 x $indep_var_label}" ///
			  3.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 3 x $indep_var_label}" ///
			  4.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 4 x $indep_var_label}" ///
			  5.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 5 x $indep_var_label}" ///
			  6.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 6 x $indep_var_label}" ///
			  7.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 7 x $indep_var_label}" ///
			  8.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 8 x $indep_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _)
	
	esttab , ///
	se title("More Lease Variation \label{tab: more variation fe`count' $tag}") ///
	keep(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var ///
		 7.bucket#c.$indep_var ///
		 8.bucket#c.$indep_var) ///
	varlabels(2.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 2 x $indep_var_label}" ///
			  3.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 3 x $indep_var_label}" ///
			  4.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 4 x $indep_var_label}" ///
			  5.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 5 x $indep_var_label}" ///
			  6.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 6 x $indep_var_label}" ///
			  7.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 7 x $indep_var_label}" ///
			  8.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 8 x $indep_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _)
}

// Repeat with shocks as indepvar 

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1

	if  `count' != 5 {
		continue
	}
	
	eststo clear
	cap drop bucket
	gen bucket = bucket_3
	eststo: reghdfe $dep_var i.bucket##c.$iv_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_4
	eststo: reghdfe $dep_var i.bucket##c.$iv_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_5
	eststo: reghdfe $dep_var i.bucket##c.$iv_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_6
	eststo: reghdfe $dep_var i.bucket##c.$iv_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_7
	eststo: reghdfe $dep_var i.bucket##c.$iv_var, absorb(`fe') cluster($cluster)
	replace bucket = bucket_8
	eststo: reghdfe $dep_var i.bucket##c.$iv_var, absorb(`fe') cluster($cluster)

	esttab using "$TABLES/more_variation_with_shocks_fe`count'_$tag.tex", ///
	se title("More Lease Variation, Monetary Shocks \label{tab: more variation monetary shocks fe`count' $tag}") ///
	keep(2.bucket#c.$iv_var ///
		 3.bucket#c.$iv_var ///
		 4.bucket#c.$iv_var ///
		 5.bucket#c.$iv_var ///
		 6.bucket#c.$iv_var ///
		 7.bucket#c.$iv_var ///
		 8.bucket#c.$iv_var) ///
	varlabels(2.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 2 x $iv_var_label}" ///
			  3.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 3 x $iv_var_label}" ///
			  4.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 4 x $iv_var_label}" ///
			  5.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 5 x $iv_var_label}" ///
			  6.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 6 x $iv_var_label}" ///
			  7.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 7 x $iv_var_label}" ///
			  8.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 8 x $iv_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _)
	
	esttab, ///
	se title("More Lease Variation, Monetary Shocks \label{tab: more variation monetary shocks fe`count' $tag}") ///
	keep(2.bucket#c.$iv_var ///
		 3.bucket#c.$iv_var ///
		 4.bucket#c.$iv_var ///
		 5.bucket#c.$iv_var ///
		 6.bucket#c.$iv_var ///
		 7.bucket#c.$iv_var ///
		 8.bucket#c.$iv_var) ///
	varlabels(2.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 2 x $iv_var_label}" ///
			  3.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 3 x $iv_var_label}" ///
			  4.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 4 x $iv_var_label}" ///
			  5.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 5 x $iv_var_label}" ///
			  6.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 6 x $iv_var_label}" ///
			  7.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 7 x $iv_var_label}" ///
			  8.bucket#c.$iv_var "\multirow{2}{4cm}{Duration Bucket 8 x $iv_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _)
}


// Instrument with monetary shocks

// local count = 0
// foreach fe of global fes  {
// 	di "`fe'"
//	
// 	local count = `count' + 1
//	
// 	if  `count' != 5 {
// 		continue
// 	}
//	
// 	eststo clear
//	
// 	// Reduced form
// 	eststo: reghdfe $dep_var i.$bucket_name##c.$iv_var , absorb(`fe') cluster($cluster)
//	
// 	// Structural equation
// 	reghdfe $indep_var $iv_var, cluster($cluster) noabsorb // first stage
// 	eststo: ivreghdfe $dep_var (2.$bucket_name#c.$indep_var 3.$bucket_name#c.$indep_var = 2.$bucket_name#c.$iv_var 3.$bucket_name#c.$iv_var), absorb(i.$bucket_name `fe') cluster($cluster)
// estadd scalar KP_stat = e(rkf)
//
// 	esttab using "$TABLES/monetary_shock_fe`count'_$tag.tex", ///
// 	se title("Monetary Shock Specification \label{tab: monetary shock fe`count' $tag}") ///
// 	keep(2.$bucket_name#c.$iv_var ///
// 		 3.$bucket_name#c.$iv_var ///
// 		 2.$bucket_name#c.$indep_var ///
// 		 3.$bucket_name#c.$indep_var) ///
// 	varlabels(2.$bucket_name#c.$iv_var "\multirow{2}{4cm}{High Duration x $iv_var_label}" ///
// 			  3.$bucket_name#c.$iv_var "\multirow{2}{4cm}{Freehold x $iv_var_label}" ///
// 			  2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration x $indep_var_label}" ///
// 			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
// 	mlabels("Reduced Form" "IV") gaps replace substitute(\_ _)
//	
// 	esttab, ///
// 	se title("Monetary Shock Specification \label{tab: monetary shock fe`count' $tag}") ///
// 	keep(2.$bucket_name#c.$iv_var ///
// 		 3.$bucket_name#c.$iv_var ///
// 		 2.$bucket_name#c.$indep_var ///
// 		 3.$bucket_name#c.$indep_var) ///
// 	varlabels(2.$bucket_name#c.$iv_var "\multirow{2}{4cm}{High Duration x $iv_var_label}" ///
// 			  3.$bucket_name#c.$iv_var "\multirow{2}{4cm}{Freehold x $iv_var_label}" ///
// 			  2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration x $indep_var_label}" ///
// 			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
// 	mlabels("Reduced Form" "IV") gaps replace substitute(\_ _)
// }


// More variation with IV

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1

	if   `count' != 5 {
		continue
	}
	
	eststo clear
	cap drop bucket
	gen bucket = bucket_3
	eststo: ivreghdfe $dep_var ///
		(2.bucket#c.$indep_var 3.bucket#c.$indep_var = 2.bucket#c.$iv_var 3.bucket#c.$iv_var) , ///
		absorb(i.bucket `fe') cluster($cluster)
	
	di "Bucket 4"
	replace bucket = bucket_4
	eststo: ivreghdfe $dep_var ///
		(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var = ///
		 2.bucket#c.$iv_var ///
		 3.bucket#c.$iv_var ///
		 4.bucket#c.$iv_var) , ///
		absorb(i.bucket `fe') cluster($cluster)
		
	di "Bucket 5"
	replace bucket = bucket_5
	eststo: ivreghdfe $dep_var ///
		(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var = ///
		 2.bucket#c.$iv_var ///
		 3.bucket#c.$iv_var ///
		 4.bucket#c.$iv_var ///
		 5.bucket#c.$iv_var ) , ///
		absorb(i.bucket `fe') cluster($cluster)
		
	di "Bucket 6"
	replace bucket = bucket_6
	eststo: ivreghdfe $dep_var ///
		(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var = ///
		 2.bucket#c.$iv_var ///
		 3.bucket#c.$iv_var ///
		 4.bucket#c.$iv_var ///
		 5.bucket#c.$iv_var ///
		 6.bucket#c.$iv_var ) , ///
		absorb(i.bucket `fe') cluster($cluster)
		
	di "Bucket 7"
	replace bucket = bucket_7
	eststo: ivreghdfe $dep_var ///
		(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var ///
		 7.bucket#c.$indep_var = ///
		 2.bucket#c.$iv_var ///
		 3.bucket#c.$iv_var ///
		 4.bucket#c.$iv_var ///
		 5.bucket#c.$iv_var ///
		 6.bucket#c.$iv_var ///
		 7.bucket#c.$iv_var ) , ///
		absorb(i.bucket `fe') cluster($cluster)
	
	local fe "i.location_n##i.date_trans##i.L_date_trans##i.type_n"
	di "Bucket 8"
	replace bucket = bucket_8
	eststo: ivreghdfe $dep_var ///
		(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var ///
		 7.bucket#c.$indep_var ///
		 8.bucket#c.$indep_var = ///
		 2.bucket#c.$iv_var ///
		 3.bucket#c.$iv_var ///
		 4.bucket#c.$iv_var ///
		 5.bucket#c.$iv_var ///
		 6.bucket#c.$iv_var ///
		 7.bucket#c.$iv_var ///
		 8.bucket#c.$iv_var ) , ///
		absorb(i.bucket `fe') cluster($cluster)

	esttab using "$TABLES/more_variation_iv_fe`count'_$tag.tex", ///
	se title("More Lease Variation, IV \label{tab: more variation iv fe`count' $tag}") ///
	keep(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var ///
		 7.bucket#c.$indep_var ///
		 8.bucket#c.$indep_var) ///
	varlabels(2.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 2 x $indep_var_label}" ///
			  3.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 3 x $indep_var_label}" ///
			  4.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 4 x $indep_var_label}" ///
			  5.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 5 x $indep_var_label}" ///
			  6.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 6 x $indep_var_label}" ///
			  7.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 7 x $indep_var_label}" ///
			  8.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 8 x $indep_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _)
	
	esttab , ///
	se title("More Lease Variation, IV \label{tab: more variation iv fe`count' $tag}") ///
	keep(2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 6.bucket#c.$indep_var ///
		 7.bucket#c.$indep_var ///
		 8.bucket#c.$indep_var) ///
	varlabels(2.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 2 x $indep_var_label}" ///
			  3.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 3 x $indep_var_label}" ///
			  4.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 4 x $indep_var_label}" ///
			  5.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 5 x $indep_var_label}" ///
			  6.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 6 x $indep_var_label}" ///
			  7.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 7 x $indep_var_label}" ///
			  8.bucket#c.$indep_var "\multirow{2}{4cm}{Duration Bucket 8 x $indep_var_label}") ///
	mlabels(none) collabels(none) gaps replace substitute(\_ _)
}
