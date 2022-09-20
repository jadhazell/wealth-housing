global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global FIGURES "$RESULTS/Figures/Lease Extensions"
global TABLES "$RESULTS/Tables/Lease Extensions"

use "$INPUT/full_cleaned_data_with_lags_and_extensions.dta", clear
global dep_var d_log_price
global dep_var_label "$\Delta$ log(price)"
global indep_var d_interest_rate
global indep_var_label "$\Delta$ Interest Rate"
global bucket_name "bucket_3"
global fes `" "i.location_n##i.date_trans##i.L_date_trans" "i.location_n##i.date_trans##i.L_date_trans##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.$bucket_name"  "'
global cluster "date_trans L_date_trans location_n"

*************************************************************
* Generate Useful Variables
*************************************************************

gen number_years_before_renewal = L_number_years - (date_registered - L_date_registered)
gen extension_amt = number_years - number_years_before_renewal

xtile bucket_3 = lease_duration_at_trans, nq(2)
replace bucket_3 = 3 if !leasehold

xtile bucket_5_purchase = L_lease_duration_at_trans, nq(5)

xtile price_quintile = L_price, nq(5)

gen negative_extension = lease_was_extended & extension_amt < 0
gen negligible_extension = lease_was_extended & extension_amt > 0 & extension_amt <= 10
gen short_extension = lease_was_extended & extension_amt > 10 & extension_amt <= 200
gen long_extension = lease_was_extended & extension_amt > 200

gen ext_type = 0 if !lease_was_extended
replace ext_type = 1 if negative_extension 
replace ext_type = 2 if negligible_extension 
replace ext_type = 3 if short_extension 
replace ext_type = 4 if long_extension

gen ext_type_s = "Not Extended" if !lease_was_extended
replace ext_type_s = "Negative Extension" if negative_extension 
replace ext_type_s = "Negligible Extension" if negligible_extension 
replace ext_type_s = "Short Extension" if short_extension 
replace ext_type_s = "Long Extension" if long_extension

*************************************************************
* Summary Statistics
*************************************************************

replace lease_duration_at_trans = 0 if !leasehold // Do this so that freeholds are still counted
eststo clear
estpost tabstat lease_duration_at_trans, by(bucket_3) statistics(mean n) columns(statistics) listwise
esttab using "$TABLES/duration_by_duration_buckets_3.tex", cells("mean count") aux(sd) nostar unstack label noobs nonote title("Mean Lease Duration by Bucket (2 Buckets) \label{tab: summary}") collabels("Mean" "Count") varlabels(1 "Below Median" 2 "Above Median" 3 "Freehold" 4 "Extended") replace
replace lease_duration_at_trans = . if !leasehold 

eststo clear
estpost tabstat extension_amt, by(ext_type) statistics(mean n) columns(statistics) listwise nototal
esttab using "$TABLES/stats_by_ext_type.tex", cells("mean count") aux(sd) nostar unstack label noobs nonote title("Summary Stats by Extension Type  \label{tab: stats by ext type}") collabels("Mean" "Count") varlabels(0 "Not Extended" 1 "Negative Extension" 2 "Negligible Extension" 3 "Short Extension" 4 "Long Extension") replace

*************************************************************
* Histograms
*************************************************************

* Histograms of Lease Extensions
twoway histogram extension_amt if lease_was_extended
graph export "$FIGURES/extension_histogram.png", replace

twoway histogram extension_amt if lease_was_extended & extension_amt > 0
graph export "$FIGURES/non_negative_extension_histogram.png", replace

twoway histogram extension_amt if lease_was_extended & extension_amt > 10
graph export "$FIGURES/greater_than_10_extension_histogram.png", replace

* Generate histogram of lease length right before extension 
twoway histogram number_years_before_renewal if lease_was_extended
graph export "$FIGURES/length_histogram.png", replace

twoway histogram number_years_before_renewal if lease_was_extended & extension_amt > 0
graph export "$FIGURES/non_negative_length_histogram.png", replace

twoway histogram number_years_before_renewal if lease_was_extended & extension_amt > 10
graph export "$FIGURES/greater_than_10_length_histogram.png", replace

* Zoom in to 65-95 range
twoway histogram number_years_before_renewal if lease_was_extended & extension_amt > 0 & number_years_before_renewal >= 65 & number_years_before_renewal <= 95, xtitle("Number of Years Before Renewal") xlabel(65(5)95, angle(45))
graph export "$FIGURES/non_negative_extension_histogram_zoomed.png", replace

*************************************************************
* Hazard Rate
*************************************************************

preserve
	collapse (mean) extension_rate = lease_was_extended (sd) extension_sd = lease_was_extended (count) n = lease_was_extended, by(L_lease_duration_at_trans)
	gen ub = extension_rate + invttail(n-1,0.025)*(extension_sd / sqrt(n))
	gen lb = extension_rate - invttail(n-1,0.025)*(extension_sd / sqrt(n))
	twoway (rcap ub lb L_lease_duration_at_trans, lcolor(gray)) (scatter extension_rate L_lease_duration_at_trans, mcolor(black) msymbol(O)) if L_lease_duration_at_trans > 50 & L_lease_duration_at_trans<=100, legend(off) ytitle("Extension Rate") xtitle("Lease Duration At Purchase")
	graph export "$FIGURES/hazard_plot_every_year_50-100.png",replace
	
	twoway (rcap ub lb L_lease_duration_at_trans, lcolor(gray)) (scatter extension_rate L_lease_duration_at_trans, mcolor(black) msymbol(O)) if L_lease_duration_at_trans<300, legend(off) ytitle("Extension Rate") xtitle("Lease Duration At Purchase")
	graph export "$FIGURES/hazard_plot_every_year_under300.png",replace
restore

// Hazard Plot
cap drop bucket
gen bucket = 1 if L_lease_duration_at_trans < 50
replace bucket = 2 if L_lease_duration_at_trans >= 50 & L_lease_duration_at_trans < 60
replace bucket = 3 if L_lease_duration_at_trans >= 60 & L_lease_duration_at_trans < 70
replace bucket = 4 if L_lease_duration_at_trans >= 70 & L_lease_duration_at_trans < 80
replace bucket = 5 if L_lease_duration_at_trans >= 80 & L_lease_duration_at_trans < 90
replace bucket = 6 if L_lease_duration_at_trans >= 90 & L_lease_duration_at_trans < 100
replace bucket = 7 if L_lease_duration_at_trans >= 100 & L_lease_duration_at_trans < 120
replace bucket = 8 if L_lease_duration_at_trans >= 120 & L_lease_duration_at_trans < 140
replace bucket = 9 if L_lease_duration_at_trans >= 140 & L_lease_duration_at_trans < 160
replace bucket = 10 if L_lease_duration_at_trans >= 160 & L_lease_duration_at_trans < 300
replace bucket = 11 if L_lease_duration_at_trans >= 700
replace bucket = . if !leasehold

preserve
	gcollapse (mean) extension_rate = lease_was_extended (sd) extension_sd = lease_was_extended (count) n = lease_was_extended, by(bucket)
	gen ub = extension_rate + invttail(n-1,0.025)*(extension_sd / sqrt(n))
	gen lb = extension_rate - invttail(n-1,0.025)*(extension_sd / sqrt(n))
	twoway (bar extension_rate bucket) ///
		   (rcap ub lb bucket), ///
		   legend(off) ///
		   ytitle("Extension Rate") ///
		   xtitle("Lease Duration At Purchase") ///
		   xlabel(1 "Less Than 50 Years" 2 "50-60 Years"  3 "60-70 Years" 4 "70-80 Years" 5 "80-90 Years" 6 "90-100 Years" 7 "100-120 Years" 8 "120-140 Years" 9 "140-160 Years" 10 "160-300 Years" 11 "700+ Years", angle(45))

	graph export "$FIGURES/hazard_plot_buckets.png",replace
restore

// Repeat but for each type of lease extension
preserve
	gcollapse (mean) neg_ext_rate = negative_extension ///
			  (sd) neg_ext_sd = negative_extension ///
			  (count) neg_ext_n = negative_extension ///
			  (mean) nearzero_ext_rate = negligible_extension ///
			  (sd) nearzero_ext_sd = negligible_extension ///
			  (count) nearzero_ext_n = negligible_extension ///
			  (mean) small_ext_rate = short_extension ///
			  (sd) small_ext_sd = short_extension ///
			  (count) small_ext_n = short_extension ///
			  (mean) big_ext_rate = long_extension ///
			  (sd) big_ext_sd = long_extension ///
			  (count) big_ext_n = long_extension, by(bucket)
			  
	cap drop ub* lb*
	local types "neg nearzero small big"
	foreach type of local types {
		
		di "`type'"
		
		gen ub_`type' = `type'_ext_rate + invttail(`type'_ext_n-1,0.025)*(`type'_ext_sd / sqrt(`type'_ext_n))
		gen lb_`type' = `type'_ext_rate - invttail(`type'_ext_n-1,0.025)*(`type'_ext_sd / sqrt(`type'_ext_n))
		
		twoway (bar `type'_ext_rate bucket) ///
			   (rcap ub_`type' lb_`type' bucket), ///
			   legend(off) ///
			   ytitle("Extension Rate") ///
			   xtitle("Lease Duration At Purchase") ///
			   xlabel(1 "Less Than 50 Years" 2 "50-60 Years"  3 "60-70 Years" 4 "70-80 Years" 5 "80-90 Years" 6 "90-100 Years" 7 "100-120 Years" 8 "120-140 Years" 9 "140-160 Years" 10 "160-300 Years" 11 "700+ Years", angle(45))

		graph export "$FIGURES/hazard_plot_buckets_`type'_ext.png",replace
		
	}
restore

***********************************************************************************
* Calculate Effect of Interest Rate on Lease Extensions (i.e. "The Stupid Thing")
***********************************************************************************

cap drop small_bucket large_bucket
gen small_bucket=.
forvalues i = 50(5)1000 {
	replace small_bucket = `i'+2.5 if L_lease_duration_at_trans > `i' & L_lease_duration_at_trans <= `i' + 5
}

local bucket "small_bucket"


* Use lease extension dummy
eststo clear 
foreach fe of global fes  {
	di "i.bucket##`fe'"
	eststo: reghdfe $dep_var i.lease_was_extended##c.$indep_var if extension_amt>=0, absorb(i.`bucket'##`fe') cluster($cluster)
	
	* Add fixed effect checkmarks
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
esttab using "$TABLES/lease_extension_`bucket'.tex", ///
	se title("Effect Of Interest Rate by Extension Type \label{tab: lease extensions `bucket'}") ///
	keep(1.lease_was_extended ///
		 1.lease_was_extended#c.$indep_var ) ///
	varlabels(1.lease_was_extended "\multirow{2}{4cm}{Lease Was Extended}" ///
			  1.lease_was_extended#c.$indep_var "\multirow{2}{4cm}{Lease Was Extended x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))

* Use lease extension dummy + only look at short leaseholds
eststo clear 
foreach fe of global fes  {
	di "i.bucket##`fe'"
	eststo: reghdfe $dep_var i.lease_was_extended##c.$indep_var if extension_amt>=0 & L_lease_duration_at_trans<=100, absorb(i.`bucket'##`fe') cluster($cluster)
	
	* Add fixed effect checkmarks
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
esttab using "$TABLES/lease_extension_under100_`bucket'.tex", ///
	se title("Effect Of Interest Rate by Extension Type \label{tab: lease extensions under100 `bucket'}") ///
	keep(1.lease_was_extended ///
		 1.lease_was_extended#c.$indep_var ) ///
	varlabels(1.lease_was_extended "\multirow{2}{4cm}{Lease Was Extended}" ///
			  1.lease_was_extended#c.$indep_var "\multirow{2}{4cm}{Lease Was Extended x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))

* Separate by extension type
eststo clear 
foreach fe of global fes  {
	di "i.`bucket'##`fe'"
	eststo: reghdfe $dep_var i.ext_type##c.$indep_var, absorb(i.`bucket'##`fe') cluster($cluster)
	
	* Add fixed effect checkmarks
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
esttab using "$TABLES/lease_extension_multiple_types_`bucket'.tex", ///
	se title("Effect Of Interest Rate by Extension Type \label{tab: lease extensions multiple types `bucket'}") ///
	keep(1.ext_type#c.$indep_var ///
		 2.ext_type#c.$indep_var ///
		 3.ext_type#c.$indep_var ///
		 4.ext_type#c.$indep_var) ///
	varlabels(1.ext_type#c.$indep_var "\multirow{2}{4cm}{Negative Extension x $indep_var_label}" ///
			  2.ext_type#c.$indep_var "\multirow{2}{4cm}{Negligible Extension x $indep_var_label}" ///
			  3.ext_type#c.$indep_var "\multirow{2}{4cm}{Short Extension x $indep_var_label}" ///
			  4.ext_type#c.$indep_var "\multirow{2}{4cm}{Long Extension x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
	
* Separate by extension type + only look at short leaseholds
eststo clear 
foreach fe of global fes  {
	di "i.`bucket'##`fe'"
	eststo: reghdfe $dep_var i.ext_type##c.$indep_var if L_lease_duration_at_trans <= 100, absorb(i.`bucket'##`fe') cluster($cluster)
	
	* Add fixed effect checkmarks
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
esttab using "$TABLES/lease_extension_multiple_types_under100_`bucket'.tex", ///
	se title("Effect Of Interest Rate by Extension Type \label{tab: lease extensions multiple types under100 `bucket'}") ///
	keep(1.ext_type#c.$indep_var ///
		 2.ext_type#c.$indep_var ///
		 3.ext_type#c.$indep_var ///
		 4.ext_type#c.$indep_var) ///
	varlabels(1.ext_type#c.$indep_var "\multirow{2}{4cm}{Negative Extension x $indep_var_label}" ///
			  2.ext_type#c.$indep_var "\multirow{2}{4cm}{Negligible Extension x $indep_var_label}" ///
			  3.ext_type#c.$indep_var "\multirow{2}{4cm}{Short Extension x $indep_var_label}" ///
			  4.ext_type#c.$indep_var "\multirow{2}{4cm}{Long Extension x $indep_var_label}") ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
	s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
	


* Look at the effect by lease duration 
eststo clear
local count = 1
foreach fe of global fes  {
	eststo: reghdfe $dep_var c.$indep_var##i.lease_was_extended##c.L_lease_duration_at_trans if extension_amt >= 0, absorb(i.small_bucket##`fe') cluster($cluster)	
	local count = `count'+1
	
	* Add fixed effect checkmarks
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
esttab using "$TABLES/lease_extension_by_duration.tex", ///
		se title("Effect Of Interest Rate by Extension Type \label{tab: lease extensions by duration}") ///
		keep(1.lease_was_extended#c.$indep_var ///
			 1.lease_was_extended#c.$indep_var#c.L_lease_duration_at_trans) ///
		varlabels(1.lease_was_extended#c.$indep_var "\multirow{2}{4cm}{Extended x $indep_var_label}" ///
				  1.lease_was_extended#c.$indep_var#c.L_lease_duration_at_trans "\multirow{2}{4cm}{Extended x $indep_var_label x Purchase Duration}") ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
		s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
		
* Again but only under 100 duration leases
eststo clear
local count = 1
foreach fe of global fes  {
	eststo: reghdfe $dep_var c.$indep_var##i.lease_was_extended##c.L_lease_duration_at_trans if extension_amt >= 0 & L_lease_duration_at_trans <= 100, absorb(i.small_bucket##`fe') cluster($cluster)	
	local count = `count'+1
	
	* Add fixed effect checkmarks
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
esttab using "$TABLES/lease_extension_by_duration_under100.tex", ///
		se title("Effect Of Interest Rate by Extension Type \label{tab: lease extensions by duration under 100}") ///
		keep(1.lease_was_extended#c.$indep_var ///
			 1.lease_was_extended#c.$indep_var#c.L_lease_duration_at_trans) ///
		varlabels(1.lease_was_extended#c.$indep_var "\multirow{2}{4cm}{Extended x $indep_var_label}" ///
				  1.lease_was_extended#c.$indep_var#c.L_lease_duration_at_trans "\multirow{2}{4cm}{Extended x $indep_var_label x Purchase Duration}" ) ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
		s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))

* Interact lease extension amount continuously

replace extension_amt = extension_amt / 1000

eststo clear
local count = 1
foreach fe of global fes  {
	eststo: reghdfe $dep_var c.$indep_var##c.extension_amt if extension_amt >= 0, absorb(i.small_bucket##`fe') cluster($cluster)	
	local count = `count'+1
}
esttab using "$TABLES/lease_extension_continuous_regression.tex", ///
		se title("Continuous Lease Extension Regression \label{tab: continuous lease extension}") ///
		keep(extension_amt ///
			 c.$indep_var#c.extension_amt) ///
		varlabels(extension_amt "\multirow{2}{4cm}{Extension Amount}" ///
				  c.$indep_var#c.extension_amt "\multirow{2}{4cm}{Extension Amount x $indep_var_label}" ) ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
		s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))
		
* Again but for duration <= 100
eststo clear
local count = 1
foreach fe of global fes  {
	eststo: reghdfe $dep_var c.$indep_var##c.extension_amt if extension_amt >= 0 & L_lease_duration_at_trans <= 100, absorb(i.small_bucket##`fe') cluster($cluster)	
	local count = `count'+1
	
	* Add fixed effect checkmarks
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
esttab using "$TABLES/lease_extension_continuous_regression_under100.tex", ///
		se title("Continuous Lease Extension Regression \label{tab: continuous lease extension under 100}") ///
		keep(extension_amt ///
			 c.$indep_var#c.extension_amt) ///
		varlabels(extension_amt "\multirow{2}{4cm}{Extension Amount}" ///
				  c.$indep_var#c.extension_amt "\multirow{2}{4cm}{Extension Amount x $indep_var_label}" ) ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
		s(location_fe purchase_fe sale_fe type_fe price_fe location_bucket_fe N, ///
		label("Location FE" "Purchase Date FE" "Sale Date FE" "Type FE" "Price Quintile FE" "Location x Bucket FE"))

