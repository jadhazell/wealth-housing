global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/GMS Replication"
global TABLES "$RESULTS/Tables"
global FIGURES "$RESULTS/Figures"

forvalues count = 1/8 {
	
	use "$INPUT/full_cleaned_data_with_lags.dta", clear
	
	gen number_years_before_renewal = L_number_years - (date_registered - L_date_registered)
	gen extension_amt = number_years - number_years_before_renewal
	
	if !(`count'==5 | `count'==8) {
		continue
	}
	
	// Select sample
	// (1) Exact replication
	if `count'==1 {
		drop if type != "F"
		drop if date_trans < 2004 | date_trans > 2013
// 		drop if lease_duration_at_trans < 80
		local tag "exact_replication"
	}
	
	// (2) Sample including years after 2013
	if `count'==2 {
		drop if type != "F"
		drop if date_trans < 2004
// 		drop if lease_duration_at_trans < 80
		local tag "later_years"
	}
	
	// (3) Sample including all years
	if `count'==3 {
		drop if type != "F"
// 		drop if lease_duration_at_trans < 80
		local tag "all_years"
	}
	
	// (4) Sample including all property types
	if `count'==4 {
		drop if date_trans < 2004 | date_trans > 2013
// 		drop if lease_duration_at_trans < 80
		local tag "all_types"
	}
	
	// (5) No extensions
	if `count'==5 {
		drop if type != "F"
		drop if date_trans < 2004 | date_trans > 2013
// 		drop if lease_duration_at_trans < 80
		drop if leasehold & date_registered != L_date_registered & !missing(L_date_registered)
		local tag "no_extensions"
	}
	
	// (6) No long extensions
	if `count'==6 {
		drop if type != "F"
		drop if date_trans < 2004 | date_trans > 2013
// 		drop if lease_duration_at_trans < 80
		drop if (date_registered != L_date_registered) & (extension_amt < 0 | extension_amt > 200)
		local tag "no_extreme_extensions"
	}

	// (7) Include very short leases
	if `count'==7 {
		drop if type != "F"
		drop if date_trans < 2004 | date_trans > 2013
		local tag "very_short_leases"
	}
	
	// (8) Restrict sample to that used in the differences panel
	if `count'==8 {
		drop if type != "F"
		drop if date_trans < 2004 | date_trans > 2013
		drop if missing(L_date_trans)
		local tag "restricted"
	}
	
	// Histograms
	histogram lease_duration_at_trans if lease_duration_at_trans > 0 & lease_duration_at_trans <= 300, width(5) frequency
	graph export "$FIGURES/histogram_short_leases_`tag'.png", replace
	
	histogram lease_duration_at_trans if lease_duration_at_trans > 700 & lease_duration_at_trans <= 1000, width(5) frequency
	graph export "$FIGURES/histogram_long_leases_`tag'.png", replace
	
	// Regression
	
	if `count' != 7 {
		drop if lease_duration_at_trans < 80
	}
	
	gen xaxis = _n+1 if _n <=5
	gen coeff = .
	gen sd = .
	
	gen maturity_group = 1 if !leasehold
	replace maturity_group = 2 if leasehold & lease_duration_at_trans < 100
	replace maturity_group = 3 if leasehold & lease_duration_at_trans >= 100 & lease_duration_at_trans < 125
	replace maturity_group = 4 if leasehold & lease_duration_at_trans >= 125 & lease_duration_at_trans < 150
	replace maturity_group = 5 if leasehold & lease_duration_at_trans >= 150 & lease_duration_at_trans < 300
	replace maturity_group = 6 if leasehold & lease_duration_at_trans >= 700
	
	reghdfe log_price i.maturity_group, absorb(i.location_n##i.date_trans)
	
	forvalues i=2/6 {
		replace coeff = _b[`i'.maturity_group] if xaxis == `i'
		replace sd = _se[`i'.maturity_group] if xaxis == `i'
	}
	
	gen ub = coeff + 1.96*sd
	gen lb = coeff - 1.96*sd
	
	local first_label "80-99"
	
	if `count' == 7 {
		local first_label "0-99"
	}
	
	graph twoway (bar coeff xaxis) (rcap ub lb xaxis), xlabel(2 "`first_label'" 3 "100-124" 4 "125-149" 5 "150-300" 6 "700+") ylabel(0(-0.05)-0.3) legend(off)
	graph export "$FIGURES/regression_results_`tag'.png", replace
	
	
}
