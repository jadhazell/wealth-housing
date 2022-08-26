local differenced = `1'
local restricted = `2'
local logs = `3'

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/More Lease Variation"

global TABLES "$RESULTS/Tables"
global FIGURES "$RESULTS/Figures"

// Select correct sample according to parameters
do select_sample `differenced' `restricted' `logs'

di "Fixed effects:"
di $fes

/////////////////////////////////////////////////////
// Create histogram of lease duration
/////////////////////////////////////////////////////
// twoway histogram lease_duration_at_trans if leasehold & lease_duration_at_trans <= 1000
// graph export "$FIGURES/duration_histogram_$tag.png", replace

// Do everything on first and second regression

local count=0
foreach fe of global fes  {
	
	local count = `count'+1
	di "`fe'"
	di "$tag"
	
	// Skip lasted column of main table because it takes too long
	if `count'==4 {
		continue
	}

	/////////////////////////////////////////////////////
	// Split data by 100-year duration blocks 
	/////////////////////////////////////////////////////
	cap drop bucket
	gen bucket = .
	forvalues i=0(100)900 {
		replace bucket = (`i'+100)/100 if lease_duration_at_trans > `i' & lease_duration_at_trans <= `i'+100
	}
	replace bucket=11 if leasehold & lease_duration_at_trans > 1000
	replace bucket=12 if !leasehold


	// Summary stats
	eststo clear
	estpost tabstat lease_duration_at_trans, by(bucket) statistics(mean count) columns(statistics) listwise
	esttab using "$TABLES/summary_100_year_blocks_$tag.tex", cells("mean count") nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary 100 year blocks $tag}") varlabels(1 "0-100" 2 "100-200" 3 "200-300" 4 "300-400" 5 "400-500" 6 "500-600" 7 "600-700" 8 "700-800" 9 "800-900" 10 "900-1000" 11 "1000+" 12 "Freehold") replace substitute(\_ _)

	local bucket_name bucket

	eststo clear 
	eststo: reghdfe $dep_var i.`bucket_name'##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)

	esttab using "$TABLES/main_regression_separated_by_100_year_blocks_$tag.tex", ///
		se title("Regression Results by 100 Year Lease Duration Blocks \label{tab: regression 100 year blocks $tag}") ///
		keep(2.`bucket_name'#c.$indep_var ///
		3.`bucket_name'#c.$indep_var ///
		4.`bucket_name'#c.$indep_var ///
		5.`bucket_name'#c.$indep_var ///
		6.`bucket_name'#c.$indep_var ///
		7.`bucket_name'#c.$indep_var ///
		8.`bucket_name'#c.$indep_var ///
		9.`bucket_name'#c.$indep_var ///
		10.`bucket_name'#c.$indep_var ///
		11.`bucket_name'#c.$indep_var ///
		12.`bucket_name'#c.$indep_var) ///
		varlabels( ///
		2.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{100-200 Years x $indep_var_label}" ///
		3.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{200-300 Years x $indep_var_label}" ///
		4.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{300-400 Years x $indep_var_label}" ///
		5.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{400-500 Years x $indep_var_label}" ///
		6.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{500-600 Years x $indep_var_label}" ///
		7.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{600-700 Years x $indep_var_label}" ///
		8.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{700-800 Years x $indep_var_label}" ///
		9.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{800-900 Years x $indep_var_label}" ///
		10.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{900-1000 Years x $indep_var_label}" ///
		11.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{1000+ Years x $indep_var_label}" ///
		12.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
		gaps replace substitute(\_ _)

	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n <= 12
	gen coeff = .
	gen sd = .

	local bucket_name bucket
	forvalues n = 2/12 {
		replace coeff = _b[`n'.`bucket_name'#c.$indep_var] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.$indep_var] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "100-200" 3 "200-300" 4 "300-400" 5 "400-500" 6 "500-600" 7 "600-700" 8 "700-800" 9 "800-900" 10 "900-1000" 11 "1000+" 12 "Freehold", angle(45)) yline(0)
	graph export "$FIGURES/100_year_bucket_results_fe`count'_$tag.png", replace

	/////////////////////////////////////////////////////
	// Split data into more specific blocks
	/////////////////////////////////////////////////////


	// 1
	cap drop bucket 
	gen bucket = 1 if leasehold & lease_duration_at_trans > 0 & lease_duration_at_trans <= 100
	replace bucket = 2 if leasehold & lease_duration_at_trans > 100 & lease_duration_at_trans <= 500
	replace bucket = 3 if leasehold & lease_duration_at_trans > 500 & lease_duration_at_trans <= 1000
	replace bucket = 4 if (leasehold & lease_duration_at_trans > 1000) | !leasehold

	local bucket_name bucket

	eststo clear 
	eststo: reghdfe $dep_var i.`bucket_name'##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)

	esttab using "$TABLES/results_by_bucket1_fe`count'_$tag.tex", ///
		se title("Regression Results by 100 Year Lease Duration Blocks \label{tab: regression 100 year blocks fe`count'_$tag}") ///
		keep(2.`bucket_name'#c.$indep_var ///
		3.`bucket_name'#c.$indep_var ///
		4.`bucket_name'#c.$indep_var) ///
		varlabels( ///
		2.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{100-500 Years x }" ///
		3.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{500-1000 Years x `interest_rate_label'}" ///
		4.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{1000+ and Freehoolds x `interest_rate_label'}") ///
		gaps replace substitute(\_ _)

	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n > 1 & _n <= 4
	gen coeff = .
	gen sd = .

	local bucket_name bucket
	forvalues n = 2/4 {
		replace coeff = _b[`n'.`bucket_name'#c.$indep_var] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.$indep_var] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "100-500" 3 "500-1000" 4 "1000+ & Freehold", angle(45)) yline(0)
	graph export "$FIGURES/results_by_bucket1_fe`count'_$tag.png", replace

	// Focus on long leases
	cap drop bucket 
	gen bucket = 1 if leasehold & lease_duration_at_trans > 0 & lease_duration_at_trans <= 100
	replace bucket = 2 if leasehold & lease_duration_at_trans > 100 & lease_duration_at_trans <= 200
	replace bucket = 3 if leasehold & lease_duration_at_trans > 200 & lease_duration_at_trans <= 900
	replace bucket = 4 if leasehold & lease_duration_at_trans > 900 & lease_duration_at_trans <= 970
	replace bucket = 5 if leasehold & lease_duration_at_trans > 970 & lease_duration_at_trans <= 980
	replace bucket = 6 if leasehold & lease_duration_at_trans > 980 & lease_duration_at_trans <= 990
	replace bucket = 7 if leasehold & lease_duration_at_trans > 990 & lease_duration_at_trans <= 1000
	replace bucket = 8 if (leasehold & lease_duration_at_trans > 1000) | !leasehold

	// Summary stats
	eststo clear
	estpost tabstat lease_duration_at_trans $dep_var $indep_var, by(bucket) statistics(mean sd) columns(statistics) listwise
	esttab using "$TABLES/summary_long_leases_$tag.tex", main(mean) aux(sd) nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary focus on long leases $tag}") varlabels(1 "0-100" 2 "100-200" 3 "200-900" 4 "900-970" 5 " 970-980" 6 "980-990" 7 "990-1000" 8 "1000+") replace substitute(\_ _)

	local bucket_name bucket

	eststo clear 
	eststo: reghdfe $dep_var i.`bucket_name'##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)

	esttab using "$TABLES/results_long_leases_fe`count'_$tag.tex", ///
		se title("Regression Results, Focusing on Long Leases \label{tab: regression focus on long leases fe`count'_$tag}") ///
		keep(2.`bucket_name'#c.$indep_var ///
		3.`bucket_name'#c.$indep_var ///
		4.`bucket_name'#c.$indep_var ///
		5.`bucket_name'#c.$indep_var ///
		6.`bucket_name'#c.$indep_var ///
		7.`bucket_name'#c.$indep_var ///
		8.`bucket_name'#c.$indep_var) ///
		varlabels( ///
		2.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{100-200 Years x $indep_var_label}" ///
		3.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{200-900 Years x $indep_var_label}" ///
		4.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{900-950 Years x $indep_var_label}" ///
		5.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{950-970 Years x $indep_var_label}" ///
		6.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{970-990 Years x $indep_var_label}" ///
		7.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{990-1000 Years x $indep_var_label}" ///
		8.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{1000+ and Freehoolds x $indep_var_label}") ///
		gaps replace substitute(\_ _)

	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n > 1 & _n <= 8
	gen coeff = .
	gen sd = .

	local bucket_name bucket
	forvalues n = 2/8 {
		replace coeff = _b[`n'.`bucket_name'#c.$indep_var] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.$indep_var] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "100-200" 3 "200-900" 4 "900-970" 5 " 970-980" 6 "980-990" 7 "990-1000" 8 "1000+ & Freehold", angle(45)) yline(0)
	graph export "$FIGURES/results_long_leases_fe`count'_$tag.png", replace


	// Focus on short leases
	cap drop bucket 
	gen bucket = 1 if leasehold & lease_duration_at_trans > 0 & lease_duration_at_trans <= 70
	replace bucket = 2 if leasehold & lease_duration_at_trans > 70 & lease_duration_at_trans <= 80
	replace bucket = 3 if leasehold & lease_duration_at_trans > 80 & lease_duration_at_trans <= 90
	replace bucket = 4 if leasehold & lease_duration_at_trans > 90 & lease_duration_at_trans <= 100
	replace bucket = 5 if leasehold & lease_duration_at_trans > 100 & lease_duration_at_trans <= 110
	replace bucket = 6 if leasehold & lease_duration_at_trans > 110 & lease_duration_at_trans <= 120
	replace bucket = 7 if leasehold & lease_duration_at_trans > 120 & lease_duration_at_trans <= 150
	replace bucket = 8 if leasehold & lease_duration_at_trans > 150 & lease_duration_at_trans <= 1000
	replace bucket = 9 if (leasehold & lease_duration_at_trans > 1000) | !leasehold

	// Summary stats
	eststo clear
	estpost tabstat lease_duration_at_trans $dep_var $indep_var, by(bucket) statistics(mean sd) columns(statistics) listwise
	esttab using "$TABLES/summary_short_leases.tex", main(mean) aux(sd) nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary focus on short leases fe`count'_$tag}") varlabels(1 "0-70" 2 "70-80" 3 "80-90" 4 "90-100" 5 " 100-110" 6 "110-120" 7 "120-150" 8 "150-1000" 9 "1000+") replace substitute(\_ _)

	local bucket_name bucket

	eststo clear 
	eststo: reghdfe $dep_var i.`bucket_name'##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)

	esttab using "$TABLES/results_short_leases_fe`count'_$tag.tex", ///
		se title("Regression Results, Focusing on Short Leases \label{tab: regression focus on short leases fe`count'_$tag}") ///
		keep(2.`bucket_name'#c.$indep_var ///
		3.`bucket_name'#c.$indep_var ///
		4.`bucket_name'#c.$indep_var ///
		5.`bucket_name'#c.$indep_var ///
		6.`bucket_name'#c.$indep_var ///
		7.`bucket_name'#c.$indep_var ///
		8.`bucket_name'#c.$indep_var) ///
		varlabels( ///
		2.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{70-80 Years x $indep_var_label}" ///
		3.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{80-90 Years x $indep_var_label}" ///
		4.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{90-100 Years x $indep_var_label}" ///
		5.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{100-110 Years x $indep_var_label}" ///
		6.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{110-120 Years x $indep_var_label}" ///
		7.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{120-150 Years x $indep_var_label}" ///
		8.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{150-1000 x $indep_var_label}" ///
		9.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{1000+ and Freehoolds x $indep_var_label}") ///
		gaps replace substitute(\_ _)

	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n > 1 & _n <= 9
	gen coeff = .
	gen sd = .

	local bucket_name bucket
	forvalues n = 2/9 {
		replace coeff = _b[`n'.`bucket_name'#c.$indep_var] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.$indep_var] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "70-80" 3 "80-90" 4 "90-100" 5 " 100-110" 6 "110-120" 7 "120-150" 8 "150-1000" 9 "1000+ & Freehold", angle(45)) yline(0)
	graph export "$FIGURES/results_short_leases_fe`count'_$tag.png", replace

	/////////////////////////////////////////////////////
	// Split Data by Deciles:
	/////////////////////////////////////////////////////

	local bucket_name $bucket_11_name

	eststo clear 
	quietly eststo: reghdfe $dep_var i.`bucket_name'##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)

	esttab using "$TABLES/main_regression_`bucket_name'_separating_extended_leases_fe`count'_$tag.tex", ///
		se title("Baseline Regression Results, Including Extended Leases, 5 Lease Buckets \label{tab: bucket 11 $tag}") ///
		keep( ///
		2.`bucket_name'#c.$indep_var ///
		3.`bucket_name'#c.$indep_var ///
		4.`bucket_name'#c.$indep_var ///
		5.`bucket_name'#c.$indep_var ///
		6.`bucket_name'#c.$indep_var ///
		7.`bucket_name'#c.$indep_var ///
		8.`bucket_name'#c.$indep_var ///
		9.`bucket_name'#c.$indep_var ///
		10.`bucket_name'#c.$indep_var ///
		11.`bucket_name'#c.$indep_var) ///
		varlabels( ///
		2.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Leasehold 2 x $indep_var_label}"  ///
		3.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Leasehold 3 x $indep_var_label}"  ///
		4.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Leasehold 4 x $indep_var_label}"  ///
		5.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Leasehold 5 x $indep_var_label}"  ///
		6.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Leasehold 6 x $indep_var_label}"  ///
		7.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Leasehold 7 x $indep_var_label}"  ///
		8.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Leasehold 8 x $indep_var_label}"  ///
		9.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Leasehold 9 x $indep_var_label}" ///
		10.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Leasehold 10 x $indep_var_label}" ///
		11.`bucket_name'#c.$indep_var "\multirow{2}{6cm}{Freehold x $indep_var_label}") gaps replace substitute(\_ _)

	// Plot results
	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n <= 12
	gen coeff = .
	gen sd = .

	forvalues n = 2/11 {
		replace coeff = _b[`n'.`bucket_name'#c.$indep_var] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.$indep_var] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "Freehold", angle(45)) yline(0)
	graph export "$FIGURES/bucket_11_regression_results_fe`count'_$tag.png", replace

}
