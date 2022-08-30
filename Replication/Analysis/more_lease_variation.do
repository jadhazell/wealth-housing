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
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/More Lease Variation"

global TABLES "$RESULTS/Tables"
global FIGURES "$RESULTS/Figures"

// Select correct sample according to parameters
do select_sample `differenced' `restricted' `logs' `duplicate_registration' `flats' `windsor' `under_80' `post_2004' `below_median_price' `above_median_price'

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

	// GMS split
	cap drop bucket 
	gen bucket     = 1 if leasehold & lease_duration_at_trans >= 80 < 100
	replace bucket = 2 if leasehold & lease_duration_at_trans >= 100 & lease_duration_at_trans < 125
	replace bucket = 3 if leasehold & lease_duration_at_trans >= 125 & lease_duration_at_trans < 150
	replace bucket = 4 if leasehold & lease_duration_at_trans >= 150 & lease_duration_at_trans <= 300
	replace bucket = 5 if leasehold & lease_duration_at_trans >= 700
	replace bucket = 6 if !leasehold

	// Summary stats
	eststo clear
	estpost tabstat lease_duration_at_trans $dep_var $indep_var, by(bucket) statistics(mean sd) columns(statistics) listwise
	esttab using "$TABLES/summary_gmsbucket_$tag.tex", main(mean) aux(sd) nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary gms fe`count'_$tag}") varlabels(1 "80-100" 2 "100-125" 3 "125-150" 4 "150-300" 5 "700-1000") replace substitute(\_ _)

	local bucket_name bucket
	
	eststo clear 
	eststo: reghdfe $dep_var i.`bucket_name'##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)

	esttab using "$TABLES/results_gmsbucket_fe`count'_$tag.tex", ///
		se title("Regression Results \label{tab: gms fe`count'_$tag}") ///
		keep(2.`bucket_name'#c.$indep_var ///
		3.`bucket_name'#c.$indep_var ///
		4.`bucket_name'#c.$indep_var ///
		5.`bucket_name'#c.$indep_var ///
		6.`bucket_name'#c.$indep_var) ///
		varlabels( ///
		2.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{100-125 Years x $indep_var_label}" ///
		3.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{125-150 Years x $indep_var_label}" ///
		4.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{150-300 Years x $indep_var_label}" ///
		5.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{700-1000 Years x $indep_var_label}" ///
		6.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{Freehoolds x $indep_var_label}") ///
		gaps replace substitute(\_ _)

	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n > 1 & _n <= 6
	gen coeff = .
	gen sd = .

	local bucket_name bucket
	forvalues n = 2/6 {
		replace coeff = _b[`n'.`bucket_name'#c.$indep_var] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.$indep_var] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "100-125" 3 "125-150" 4 "150-300" 5 "700-1000" 6 "Freehold", angle(45)) yline(0)
	graph export "$FIGURES/results_gmsbucket_fe`count'_$tag.png", replace

	// Tighter split (i.e. smaller buckets)
	cap drop bucket 
	gen bucket     = 1 if leasehold & lease_duration_at_trans >= 80 < 100
	replace bucket = 2 if leasehold & lease_duration_at_trans >= 100 & lease_duration_at_trans < 125
	replace bucket = 3 if leasehold & lease_duration_at_trans >= 125 & lease_duration_at_trans < 150
	replace bucket = 4 if leasehold & lease_duration_at_trans >= 150 & lease_duration_at_trans <= 300
	replace bucket = 5 if leasehold & lease_duration_at_trans >= 700 & lease_duration_at_trans < 900
	replace bucket = 6 if leasehold & lease_duration_at_trans >= 900 & lease_duration_at_trans < 950
	replace bucket = 7 if leasehold & lease_duration_at_trans >= 950 & lease_duration_at_trans < 975
	replace bucket = 8 if leasehold & lease_duration_at_trans >= 975 & lease_duration_at_trans < 1000
	replace bucket = 9 if !leasehold

	// Summary stats
	eststo clear
	estpost tabstat lease_duration_at_trans $dep_var $indep_var, by(bucket) statistics(mean sd) columns(statistics) listwise
	esttab using "$TABLES/summary_expanded_bucket_$tag.tex", main(mean) aux(sd) nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary expanded fe`count'_$tag}") varlabels(1 "80-100" 2 "100-125" 3 "125-150" 4 "150-300" 5 "700-900" 6 "900-950" 7 "950-975" 8 "975-1000" 9 "1000+") replace substitute(\_ _)

	local bucket_name bucket
	
	eststo clear 
	eststo: reghdfe $dep_var i.`bucket_name'##c.$indep_var if obs_to_use`count', absorb(`fe') cluster($cluster)

	esttab using "$TABLES/results_expanded_bucket_fe`count'_$tag.tex", ///
		se title("Regression Results \label{tab: regression expanded fe`count'_$tag}") ///
		keep(2.`bucket_name'#c.$indep_var ///
		3.`bucket_name'#c.$indep_var ///
		4.`bucket_name'#c.$indep_var ///
		5.`bucket_name'#c.$indep_var ///
		6.`bucket_name'#c.$indep_var ///
		7.`bucket_name'#c.$indep_var ///
		8.`bucket_name'#c.$indep_var ///
		9.`bucket_name'#c.$indep_var) ///
		varlabels( ///
		2.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{100-125 Years x $indep_var_label}" ///
		3.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{125-150 Years x $indep_var_label}" ///
		4.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{150-300 Years x $indep_var_label}" ///
		5.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{700-900 Years x $indep_var_label}" ///
		6.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{900-950 Years x $indep_var_label}" ///
		7.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{950-975 Years x $indep_var_label}" ///
		8.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{975-1000 Years x $indep_var_label}" ///
		9.`bucket_name'#c.$indep_var "\multirow{2}{4cm}{Freehoolds x $indep_var_label}") ///
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

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "100-125" 3 "125-150" 4 "150-300" 5 "700-900" 6 "900-950" 7 "950-975" 8 "975-1000" 9 "Freehold", angle(45)) yline(0)
	graph export "$FIGURES/results_expanded_bucket_fe`count'_$tag.png", replace

	
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
