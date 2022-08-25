global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/More Lease Variation"

use "$INPUT/final_data.dta", clear
set scheme plotplainblind

/////////////////////////////////////////////////////
// Create histogram of lease duration
/////////////////////////////////////////////////////
twoway histogram lease_duration_at_trans if leasehold & lease_duration_at_trans <= 1000
graph export "$RESULTS/duration_histogram.png", replace

// Do everything on first and second regression

local tags "_col1 _col2"
local count=0
local fes "i.location_n##i.date_trans##i.L_date_trans i.location_n##i.date_trans##i.L_date_trans##i.type_n"
foreach fe of local fes  {
	
	local count = `count'+1
	local tag : word `count' of `tags'
	di "`fe'"
	di "`tag'"

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
	esttab using "$RESULTS/summary_100_year_blocks.tex", cells("mean count") nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary 100 year blocks}") varlabels(1 "0-100" 2 "100-200" 3 "200-300" 4 "300-400" 5 "400-500" 6 "500-600" 7 "600-700" 8 "700-800" 9 "800-900" 10 "900-1000" 11 "1000+" 12 "Freehold") replace

	local bucket_name bucket

	eststo clear 
	eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(`fe') cluster(date_trans L_date_trans location_n)

	esttab using "$RESULTS/main_regression_separated_by_100_year_blocks`tag'.tex", ///
		se title("Regression Results by 100 Year Lease Duration Blocks \label{tab: regression 100 year blocks}") ///
		keep(2.`bucket_name'#c.d_interest_rate ///
		3.`bucket_name'#c.d_interest_rate ///
		4.`bucket_name'#c.d_interest_rate ///
		5.`bucket_name'#c.d_interest_rate ///
		6.`bucket_name'#c.d_interest_rate ///
		7.`bucket_name'#c.d_interest_rate ///
		8.`bucket_name'#c.d_interest_rate ///
		9.`bucket_name'#c.d_interest_rate ///
		10.`bucket_name'#c.d_interest_rate ///
		11.`bucket_name'#c.d_interest_rate ///
		12.`bucket_name'#c.d_interest_rate) ///
		varlabels( ///
		2.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{100-200 Years x $\Delta$ Interest Rate}" ///
		3.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{200-300 Years x $\Delta$ Interest Rate}" ///
		4.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{300-400 Years x $\Delta$ Interest Rate}" ///
		5.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{400-500 Years x $\Delta$ Interest Rate}" ///
		6.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{500-600 Years x $\Delta$ Interest Rate}" ///
		7.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{600-700 Years x $\Delta$ Interest Rate}" ///
		8.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{700-800 Years x $\Delta$ Interest Rate}" ///
		9.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{800-900 Years x $\Delta$ Interest Rate}" ///
		10.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{900-1000 Years x $\Delta$ Interest Rate}" ///
		11.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{1000+ Years x $\Delta$ Interest Rate}" ///
		12.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Freehold x $\Delta$ Interest Rate}") ///
		gaps replace

	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n <= 12
	gen coeff = .
	gen sd = .

	local bucket_name bucket
	forvalues n = 2/12 {
		replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "100-200" 3 "200-300" 4 "300-400" 5 "400-500" 6 "500-600" 7 "600-700" 8 "700-800" 9 "800-900" 10 "900-1000" 11 "1000+" 12 "Freehold", angle(45)) yline(0)
	graph export "$RESULTS/100_year_bucket_results`tag'.png", replace

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
	eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(`fe') cluster(date_trans L_date_trans location_n)

	esttab using "$RESULTS/results_by_bucket1`tag'.tex", ///
		se title("Regression Results by 100 Year Lease Duration Blocks \label{tab: regression 100 year blocks}") ///
		keep(2.`bucket_name'#c.d_interest_rate ///
		3.`bucket_name'#c.d_interest_rate ///
		4.`bucket_name'#c.d_interest_rate) ///
		varlabels( ///
		2.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{100-500 Years x $\Delta$ Interest Rate}" ///
		3.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{500-1000 Years x $\Delta$ Interest Rate}" ///
		4.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{1000+ and Freehoolds x $\Delta$ Interest Rate}") ///
		gaps replace

	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n > 1 & _n <= 4
	gen coeff = .
	gen sd = .

	local bucket_name bucket
	forvalues n = 2/4 {
		replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "100-500" 3 "500-1000" 4 "1000+ & Freehold", angle(45)) yline(0)
	graph export "$RESULTS/results_by_bucket1`tag'.png", replace

// 	// 2
// 	cap drop bucket 
// 	gen bucket = 1 if leasehold & lease_duration_at_trans > 0 & lease_duration_at_trans <= 50
// 	replace bucket = 2 if leasehold & lease_duration_at_trans > 50 & lease_duration_at_trans <= 100
// 	replace bucket = 3 if leasehold & lease_duration_at_trans > 100 & lease_duration_at_trans <= 150
// 	replace bucket = 4 if leasehold & lease_duration_at_trans > 150 & lease_duration_at_trans <= 200
// 	replace bucket = 5 if leasehold & lease_duration_at_trans > 200 & lease_duration_at_trans <= 900
// 	replace bucket = 6 if leasehold & lease_duration_at_trans > 900 & lease_duration_at_trans <= 950
// 	replace bucket = 7 if leasehold & lease_duration_at_trans > 950 & lease_duration_at_trans <= 1000
// 	replace bucket = 8 if (leasehold & lease_duration_at_trans > 1000) | !leasehold
//
// 	// Summary stats
// 	eststo clear
// 	estpost tabstat lease_duration_at_trans, by(bucket) statistics(mean count) columns(statistics) listwise
// 	esttab using "$RESULTS/summary_bucket2.tex", cells("mean count") nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary 100 year blocks}") varlabels(1 "0-50" 2 "50-100" 3 "100-150" 4 "150-200" 5 " 200-900" 6 "900-950" 7 "950-1000" 8 "1000+ & Freehold") replace
//
// 	local bucket_name bucket
//
// 	eststo clear 
// 	eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(`fe') cluster(date_trans L_date_trans location_n)
//
// 	esttab using "$RESULTS/results_by_bucket2`tag'.tex", ///
// 		se title("Regression Results by 100 Year Lease Duration Blocks \label{tab: regression 100 year blocks}") ///
// 		keep(2.`bucket_name'#c.d_interest_rate ///
// 		3.`bucket_name'#c.d_interest_rate ///
// 		4.`bucket_name'#c.d_interest_rate ///
// 		5.`bucket_name'#c.d_interest_rate ///
// 		6.`bucket_name'#c.d_interest_rate ///
// 		7.`bucket_name'#c.d_interest_rate ///
// 		8.`bucket_name'#c.d_interest_rate) ///
// 		varlabels( ///
// 		2.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{50-100 Years x $\Delta$ Interest Rate}" ///
// 		3.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{100-150 Years x $\Delta$ Interest Rate}" ///
// 		4.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{150-200 Years x $\Delta$ Interest Rate}" ///
// 		5.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{200-900 Years x $\Delta$ Interest Rate}" ///
// 		6.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{900-950 Years x $\Delta$ Interest Rate}" ///
// 		7.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{950-1000 Years x $\Delta$ Interest Rate}" ///
// 		8.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{1000+ and Freehoolds x $\Delta$ Interest Rate}") ///
// 		gaps replace
//
// 	cap drop xaxis coeff sd ub lb
// 	gen xaxis = _n if _n > 1 & _n <= 8
// 	gen coeff = .
// 	gen sd = .
//
// 	local bucket_name bucket
// 	forvalues n = 2/8 {
// 		replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
// 		replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
// 	}
//
// 	gen lb = coeff - 1.96*sd
// 	gen ub = coeff + 1.96*sd
//
// 	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "50-100" 3 "100-150" 4 "150-200" 5 " 200-900" 6 "900-950" 7 "950-1000" 8 "1000+ & Freehold", angle(45)) yline(0)
// 	graph export "$RESULTS/results_by_bucket2`tag'.png", replace
//
// 	// 3
// 	cap drop bucket 
// 	gen bucket = 1 if leasehold & lease_duration_at_trans > 0 & lease_duration_at_trans <= 50
// 	replace bucket = 2 if leasehold & lease_duration_at_trans > 50 & lease_duration_at_trans <= 75
// 	replace bucket = 3 if leasehold & lease_duration_at_trans > 75 & lease_duration_at_trans <= 100
// 	replace bucket = 4 if leasehold & lease_duration_at_trans > 100 & lease_duration_at_trans <= 125
// 	replace bucket = 5 if leasehold & lease_duration_at_trans > 125 & lease_duration_at_trans <= 150
// 	replace bucket = 6 if leasehold & lease_duration_at_trans > 150 & lease_duration_at_trans <= 200
// 	replace bucket = 7 if leasehold & lease_duration_at_trans > 200 & lease_duration_at_trans <= 1000
// 	replace bucket = 8 if (leasehold & lease_duration_at_trans > 1000) | !leasehold
//
// 	// Summary stats
// 	eststo clear
// 	estpost tabstat lease_duration_at_trans, by(bucket) statistics(mean count) columns(statistics) listwise
// 	esttab using "$RESULTS/summary_bucket3.tex", cells("mean count") nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary 100 year blocks}") varlabels(1 "0-50" 2 "50-75" 3 "75-100" 4 "100-125" 5 " 125-150" 6 "150-200" 7 "200-1000" 8 "1000+") replace
//
// 	local bucket_name bucket
//
// 	eststo clear 
// 	eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(`fe') cluster(date_trans L_date_trans location_n)
//
// 	esttab using "$RESULTS/results_by_bucket3`tag'.tex", ///
// 		se title("Regression Results by 100 Year Lease Duration Blocks \label{tab: regression 100 year blocks}") ///
// 		keep(2.`bucket_name'#c.d_interest_rate ///
// 		3.`bucket_name'#c.d_interest_rate ///
// 		4.`bucket_name'#c.d_interest_rate ///
// 		5.`bucket_name'#c.d_interest_rate ///
// 		6.`bucket_name'#c.d_interest_rate ///
// 		7.`bucket_name'#c.d_interest_rate ///
// 		8.`bucket_name'#c.d_interest_rate) ///
// 		varlabels( ///
// 		2.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{50-75 Years x $\Delta$ Interest Rate}" ///
// 		3.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{75-100 Years x $\Delta$ Interest Rate}" ///
// 		4.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{100-125 Years x $\Delta$ Interest Rate}" ///
// 		5.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{125-150 Years x $\Delta$ Interest Rate}" ///
// 		6.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{150-200 Years x $\Delta$ Interest Rate}" ///
// 		7.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{200-1000 Years x $\Delta$ Interest Rate}" ///
// 		8.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{1000+ and Freehoolds x $\Delta$ Interest Rate}") ///
// 		gaps replace
//
// 	cap drop xaxis coeff sd ub lb
// 	gen xaxis = _n if _n > 1 & _n <= 8
// 	gen coeff = .
// 	gen sd = .
//
// 	local bucket_name bucket
// 	forvalues n = 2/8 {
// 		replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
// 		replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
// 	}
//
// 	gen lb = coeff - 1.96*sd
// 	gen ub = coeff + 1.96*sd
//
// 	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "50-75" 3 "75-100" 4 "100-125" 5 " 125-150" 6 "150-200" 7 "200-1000" 8 "1000+ & Freehold", angle(45)) yline(0)
// 	graph export "$RESULTS/results_by_bucket3`tag'.png", replace

	// 4
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
	estpost tabstat lease_duration_at_trans, by(bucket) statistics(mean count) columns(statistics) listwise
	esttab using "$RESULTS/summary_bucket4.tex", cells("mean count") nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary 100 year blocks}") varlabels(1 "0-100" 2 "100-200" 3 "200-900" 4 "900-970" 5 " 970-980" 6 "980-990" 7 "990-1000" 8 "1000+") replace

	local bucket_name bucket

	eststo clear 
	eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(`fe') cluster(date_trans L_date_trans location_n)

	esttab using "$RESULTS/results_by_bucket4`tag'.tex", ///
		se title("Regression Results by 100 Year Lease Duration Blocks \label{tab: regression 100 year blocks}") ///
		keep(2.`bucket_name'#c.d_interest_rate ///
		3.`bucket_name'#c.d_interest_rate ///
		4.`bucket_name'#c.d_interest_rate ///
		5.`bucket_name'#c.d_interest_rate ///
		6.`bucket_name'#c.d_interest_rate ///
		7.`bucket_name'#c.d_interest_rate ///
		8.`bucket_name'#c.d_interest_rate) ///
		varlabels( ///
		2.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{100-200 Years x $\Delta$ Interest Rate}" ///
		3.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{200-900 Years x $\Delta$ Interest Rate}" ///
		4.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{900-950 Years x $\Delta$ Interest Rate}" ///
		5.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{950-970 Years x $\Delta$ Interest Rate}" ///
		6.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{970-990 Years x $\Delta$ Interest Rate}" ///
		7.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{990-1000 Years x $\Delta$ Interest Rate}" ///
		8.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{1000+ and Freehoolds x $\Delta$ Interest Rate}") ///
		gaps replace

	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n > 1 & _n <= 8
	gen coeff = .
	gen sd = .

	local bucket_name bucket
	forvalues n = 2/8 {
		replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "100-200" 3 "200-900" 4 "900-970" 5 " 970-980" 6 "980-990" 7 "990-1000" 8 "1000+ & Freehold", angle(45)) yline(0)
	graph export "$RESULTS/results_by_bucket4`tag'.png", replace


	// 5
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
	estpost tabstat lease_duration_at_trans, by(bucket) statistics(mean count) columns(statistics) listwise
	esttab using "$RESULTS/summary_bucket5.tex", cells("mean count") nonumber nostar unstack label noobs nonote title("Stats By Year of Purchase \label{tab: summary 100 year blocks}") varlabels(1 "0-70" 2 "70-80" 3 "80-90" 4 "90-100" 5 " 100-110" 6 "110-120" 7 "120-150" 8 "150-1000" 9 "1000+") replace

	local bucket_name bucket

	eststo clear 
	eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(`fe') cluster(date_trans L_date_trans location_n)

	esttab using "$RESULTS/results_by_bucket5`tag'.tex", ///
		se title("Regression Results by 100 Year Lease Duration Blocks \label{tab: regression 100 year blocks}") ///
		keep(2.`bucket_name'#c.d_interest_rate ///
		3.`bucket_name'#c.d_interest_rate ///
		4.`bucket_name'#c.d_interest_rate ///
		5.`bucket_name'#c.d_interest_rate ///
		6.`bucket_name'#c.d_interest_rate ///
		7.`bucket_name'#c.d_interest_rate ///
		8.`bucket_name'#c.d_interest_rate) ///
		varlabels( ///
		2.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{70-80 Years x $\Delta$ Interest Rate}" ///
		3.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{80-90 Years x $\Delta$ Interest Rate}" ///
		4.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{90-100 Years x $\Delta$ Interest Rate}" ///
		5.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{100-110 Years x $\Delta$ Interest Rate}" ///
		6.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{110-120 Years x $\Delta$ Interest Rate}" ///
		7.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{120-150 Years x $\Delta$ Interest Rate}" ///
		8.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{150-1000 x $\Delta$ Interest Rate}" ///
		9.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{1000+ and Freehoolds x $\Delta$ Interest Rate}") ///
		gaps replace

	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n > 1 & _n <= 9
	gen coeff = .
	gen sd = .

	local bucket_name bucket
	forvalues n = 2/9 {
		replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "70-80" 3 "80-90" 4 "90-100" 5 " 100-110" 6 "110-120" 7 "120-150" 8 "150-1000" 9 "1000+ & Freehold", angle(45)) yline(0)
	graph export "$RESULTS/results_by_bucket5`tag'.png", replace

	/////////////////////////////////////////////////////
	// Split Data by Deciles:
	/////////////////////////////////////////////////////

	local bucket_name bucket_11_sale

	eststo clear 
	quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(`fe') cluster(date_trans L_date_trans location_n)

	local bucket_name bucket_11_sale
	esttab using "$RESULTS/main_regression_`bucket_name'_separating_extended_leases`tag'.tex", ///
		se title("Baseline Regression Results, Including Extended Leases, 5 Lease Buckets \label{tab: bucket 11}") ///
		keep( ///
		2.`bucket_name'#c.d_interest_rate ///
		3.`bucket_name'#c.d_interest_rate ///
		4.`bucket_name'#c.d_interest_rate ///
		5.`bucket_name'#c.d_interest_rate ///
		6.`bucket_name'#c.d_interest_rate ///
		7.`bucket_name'#c.d_interest_rate ///
		8.`bucket_name'#c.d_interest_rate ///
		9.`bucket_name'#c.d_interest_rate ///
		10.`bucket_name'#c.d_interest_rate ///
		11.`bucket_name'#c.d_interest_rate) ///
		varlabels( ///
		2.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 2 x $\Delta$ Interest Rate}"  ///
		3.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 3 x $\Delta$ Interest Rate}"  ///
		4.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 4 x $\Delta$ Interest Rate}"  ///
		5.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 5 x $\Delta$ Interest Rate}"  ///
		6.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 6 x $\Delta$ Interest Rate}"  ///
		7.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 7 x $\Delta$ Interest Rate}"  ///
		8.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 8 x $\Delta$ Interest Rate}"  ///
		9.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 9 x $\Delta$ Interest Rate}" ///
		10.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Leasehold 10 x $\Delta$ Interest Rate}" ///
		11.`bucket_name'#c.d_interest_rate "\multirow{2}{6cm}{Freehold x $\Delta$ Interest Rate}") gaps replace

	// Plot results
	cap drop xaxis coeff sd ub lb
	gen xaxis = _n if _n <= 12
	gen coeff = .
	gen sd = .

	forvalues n = 2/11 {
		replace coeff = _b[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
		replace sd = _se[`n'.`bucket_name'#c.d_interest_rate] if _n == `n'
	}

	gen lb = coeff - 1.96*sd
	gen ub = coeff + 1.96*sd

	twoway (rarea ub lb xaxis) (line coeff xaxis), xlabel(2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "Freehold", angle(45)) yline(0)
	graph export "$RESULTS/bucket_11_regression_results`tag'.png", replace

}
