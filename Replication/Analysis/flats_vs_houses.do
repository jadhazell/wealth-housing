
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

replace lease_duration_at_trans = 0 if freehold

* Define input and output sources
global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Flats vs Houses"
global FIGURES "$RESULTS/Figures/Flats vs Houses"

replace lease_duration_at_trans = lease_duration_at_trans * 1000

gen type_full = "Flat" if type == "F"
replace type_full = "Terraced" if type == "T"
replace type_full = "Other" if type == "O"
replace type_full = "Semi-Detached" if type == "S"
replace type_full = "Detached" if type == "D"

gen nonflat = type != "F"

* Summarize lease duration by type 
eststo clear
estpost tabstat lease_duration_at_trans if leasehold, by(type_n) statistics(p1 p5 p10 p25 p50 p75 p90 p95 p99) columns(statistics) listwise
esttab using "$TABLES/duration_by_type.tex", cells("p1 p5 p10 p25 p50 p75 p90 p95 p99") varlabels(2 "Flat"  1 "Detached"  4 "Semi-Detached" 5 "Terraced" 3 "Other") title("Lease Duration by Property Type \label{tab: duration by type}") noobs nonumber nomtitle replace

replace lease_duration_at_trans = lease_duration_at_trans / 1000

* Summarize leasehold vs freehold rate by type 
eststo clear
estpost tab freehold type_full
esttab using "$TABLES/freehold_rate_by_type.tex", cell( b(fmt(g)) colpct(fmt(2) par)) collabels(none)  unstack noobs nonumber nomtitle varlabels(0 "Leasehold" 1 "Freehold", blist(Total "\hline")) replace

* Regress duration by type
eststo clear
eststo: reghdfe lease_duration_at_trans ib2.type_n if leasehold, noabsorb cluster($cluster) residuals(res_nofe)
eststo: reghdfe  lease_duration_at_trans ib2.type_n if leasehold, absorb(i.district_n##i.year##i.L_year) cluster($cluster) residuals(res_fe)

esttab using "$TABLES/regress_duration_by_type.tex", keep(1.type_n 3.type_n 4.type_n 5.type_n) varlabels(1.type_n "Detached House" 3.type_n "Other" 4.type_n "Semi-Detached House" 5.type_n "Terraced House")  se

sum lease_duration_at_trans if leasehold, detail
sum res_nofe if leasehold, detail
sum res_fe if leasehold, detail

* Residuals plots by type
gen interaction = lease_duration_at_trans * d_interest_rate
forvalues i = 1/5 {
	reghdfe interaction c.lease_duration_at_trans c.d_interest_rate if leasehold & type_n==`i', absorb(i.district_n##i.year##i.L_year) cluster($cluster) residuals(x_res_`i')
	reghdfe d_log_price c.lease_duration_at_trans c.d_interest_rate if leasehold & type_n==`i', absorb(i.district_n##i.year##i.L_year) cluster($cluster) residuals(y_res_`i')
	
	binscatter2 y_res_`i' x_res_`i', xtitle("Duration x Δ interest rate, residualized") ytitle("Δ log(price), residualized")
	graph export "$FIGURES/residual_plot_type_`i'.png", replace
}

* Run main regression (continuous + non parametric) separately for flats and houses

cap drop bucket
gen     bucket = 1 if leasehold & lease_duration_at_trans < 80/1000
replace bucket = 2 if leasehold & lease_duration_at_trans >= 80/1000  & lease_duration_at_trans <  100/1000
replace bucket = 3 if leasehold & lease_duration_at_trans >= 100/1000 & lease_duration_at_trans <  125/1000
replace bucket = 4 if leasehold & lease_duration_at_trans >= 125/1000 & lease_duration_at_trans <  150/1000
replace bucket = 5 if leasehold & lease_duration_at_trans >= 150/1000 & lease_duration_at_trans <= 300/1000
replace bucket = 6 if leasehold & lease_duration_at_trans >= 700/1000
replace bucket = 7 if !leasehold

eststo clear
eststo: reghdfe d_log_price c.lease_duration_at_trans##c.d_interest_rate i.freehold##c.d_interest_rate, absorb(i.district_n##i.year##i.L_year) cluster($cluster)
eststo: reghdfe d_log_price i.bucket##c.d_interest_rate, absorb(i.district_n##i.year##i.L_year) cluster($cluster)

eststo: reghdfe d_log_price c.lease_duration_at_trans##c.d_interest_rate i.freehold##c.d_interest_rate if !nonflat, absorb(i.district_n##i.year##i.L_year) cluster($cluster)
eststo: reghdfe d_log_price i.bucket##c.d_interest_rate if !nonflat, absorb(i.district_n##i.year##i.L_year) cluster($cluster)

eststo: reghdfe d_log_price c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if nonflat, absorb(i.district_n##i.year##i.L_year) cluster($cluster)
eststo: reghdfe d_log_price i.bucket##c.$indep_var if nonflat, absorb(i.district_n##i.year##i.L_year) cluster($cluster)

esttab using "$TABLES/regression_by_flat_vs_nonflat_$tag.tex", ///
	se title("Effect on Flats vs Non Flats \label{tab: flats vs nonflats $tag}") ///
	rename(6.bucket#c.$indep_var 1.freehold#c.$indep_var) ///
	keep(c.lease_duration_at_trans#c.$indep_var ///
		 2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 1.freehold#c.$indep_var) ///
	order(c.lease_duration_at_trans#c.$indep_var ///
		 2.bucket#c.$indep_var ///
		 3.bucket#c.$indep_var ///
		 4.bucket#c.$indep_var ///
		 5.bucket#c.$indep_var ///
		 1.freehold#c.$indep_var) ///		
	varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
			  2.bucket#c.$indep_var "\multirow{2}{3cm}{100-125 Years x $indep_var_label}" ///
			  3.bucket#c.$indep_var "\multirow{2}{3cm}{125-150 Years x $indep_var_label}" ///
			  4.bucket#c.$indep_var "\multirow{2}{3cm}{150-300 Years x $indep_var_label}" ///
			  5.bucket#c.$indep_var "\multirow{2}{3cm}{700+ Years x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
	mlabels("All" "All" "Only Flats" "Only Flat" "Only Houses" "Only Houses") gaps replace substitute(\_ _) 

* Repeat by type:

global my_fes `" "i.district_n##i.year##i.L_year"  "i.district_n##i.year##i.L_year##i.L_price_quintile_yearly" "i.location_n##i.year##i.L_year" "i.district_n##i.date_trans##i.L_date_trans"  "'

local count = 1
foreach fe of global my_fes {

	eststo clear
	forvalues i=1/5 {
		eststo: reghdfe d_log_price c.lease_duration_at_trans##c.$indep_var i.freehold##c.$indep_var if type_n==`i', absorb(`fe') cluster($cluster)
		eststo: reghdfe d_log_price i.bucket##c.$indep_var if type_n==`i', absorb(`fe') cluster($cluster)
	}

	esttab using "$TABLES/regression_by_type_$tag_fe`count'.tex", ///
		se title("Effect on Flats vs Non Flats \label{tab: flats vs nonflats fe`count' $tag}") ///
		rename(7.bucket#c.$indep_var 1.freehold#c.$indep_var) ///
		keep(c.lease_duration_at_trans#c.$indep_var ///
			 2.bucket#c.$indep_var ///
			 3.bucket#c.$indep_var ///
			 4.bucket#c.$indep_var ///
			 5.bucket#c.$indep_var ///
			 6.bucket#c.$indep_var ///
			 1.freehold#c.$indep_var) ///
		order(c.lease_duration_at_trans#c.$indep_var ///
			 2.bucket#c.$indep_var ///
			 3.bucket#c.$indep_var ///
			 4.bucket#c.$indep_var ///
			 5.bucket#c.$indep_var ///
			 6.bucket#c.$indep_var ///
			 1.freehold#c.$indep_var) ///		
		varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
				  2.bucket#c.$indep_var "\multirow{2}{3cm}{80-100 Years x $indep_var_label}" ///
				  3.bucket#c.$indep_var "\multirow{2}{3cm}{100-125 Years x $indep_var_label}" ///
				  4.bucket#c.$indep_var "\multirow{2}{3cm}{125-150 Years x $indep_var_label}" ///
				  5.bucket#c.$indep_var "\multirow{2}{3cm}{150-300 Years x $indep_var_label}" ///
				  6.bucket#c.$indep_var "\multirow{2}{3cm}{700+ Years x $indep_var_label}" ///
				  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
		mlabels("Detached" "Detached" "Flats" "Flat" "Other" "Other" "Semi-Detached" "Semi-Detached" "Terraced" "Terraced") gaps replace substitute(\_ _) 
		
		local count = `count' + 1
}
