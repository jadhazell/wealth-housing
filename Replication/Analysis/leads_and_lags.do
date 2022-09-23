
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
	local restricted = `3'
}

if !missing(`"`4'"') {
	local drop_under_80 = `4'
}

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Robustness Checks"
global FIGURES "$RESULTS/Figures/Robustness Checks"


* Get data
do select_sample `differenced' `logs' `restricted' `drop_under_80'

// Merge in leads and lags 
if `differenced'{
	cap drop _merge
	merge m:1 date_trans using "$WORKING/interest_rates_leads.dta"
	keep if _merge==3
	cap drop _merge
	merge m:1 L_date_trans using "$WORKING/interest_rates_lags.dta"
	keep if _merge==3
	cap drop _merge
}

else{
	cap drop _merge
	merge m:1 date_trans using "$WORKING/interest_rates_leads.dta"
	keep if _merge==3
	cap drop _merge
	merge m:1 date_trans using "$WORKING/interest_rates_lags.dta"
	keep if _merge==3
	cap drop _merge
}

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Robustness Checks"
global FIGURES "$RESULTS/Figures/Robustness Checks"

* Run everything only on flats
keep if type=="F"

* Test of Identification Assumption: Pre-Trends and Post-Trends 

* Use leads/lags with window = h 
gen h = (date_trans - L_date_trans)*4

gen interest_rate_lead = .
gen interest_rate_lag = .

forvalues i = 1/110 {
	replace interest_rate_lead = DF`i'_interest_rate if h == `i'
	replace interest_rate_lag = DL`i'_interest_rate if h == `i'
}

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1
	
	di "Count: `count'"
	
	if  `count' != 1 {
		continue
	}
	
	eststo clear
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold), absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold)  c.interest_rate_lag##(c.lease_duration_at_trans i.freehold) , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold)  c.interest_rate_lead##(c.lease_duration_at_trans i.freehold)  , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold)  c.interest_rate_lag##(c.lease_duration_at_trans i.freehold) c.interest_rate_lead##(c.lease_duration_at_trans i.freehold), absorb(`fe') cluster($cluster)
	
	esttab using "$TABLES/pre_and_post_trends_h_window_fe`count'_$tag.tex", ///
	se title("Pre and Post Trends With Window = h \label{tab: pre and post trends window h fe`count' $tag}") ///
	keep(c.$indep_var#c.lease_duration_at_trans ///
		 1.freehold#c.$indep_var ///
		 c.interest_rate_lag#c.lease_duration_at_trans ///
		 1.freehold#c.interest_rate_lag ///
		 c.interest_rate_lead#c.lease_duration_at_trans ///
		 1.freehold#c.interest_rate_lead ) ///
	varlabels(c.$indep_var#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}" ///
			  c.interest_rate_lag#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $indep_var_label Lag}" ///
			  1.freehold#c.interest_rate_lag "\multirow{2}{4cm}{Freehold x $indep_var_label Lag}" ///
			  c.interest_rate_lead#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $indep_var_label Lead}" ///
			  1.freehold#c.interest_rate_lead "\multirow{2}{4cm}{Freehold x $indep_var_label Lead}" ) ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _)
}

* Use leads/lags with window = 1

replace interest_rate_lag = L1_$indep_var
replace interest_rate_lead = F2_$indep_var

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1
	
	di "Count: `count'"
	
	if  `count' != 1 {
		continue
	}
	
	eststo clear
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold), absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold)  c.interest_rate_lag##(c.lease_duration_at_trans i.freehold) , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold)  c.interest_rate_lead##(c.lease_duration_at_trans i.freehold)  , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold)  c.interest_rate_lag##(c.lease_duration_at_trans i.freehold) c.interest_rate_lead##(c.lease_duration_at_trans i.freehold), absorb(`fe') cluster($cluster)
	
	esttab using "$TABLES/pre_and_post_trends_fe`count'_$tag.tex", ///
	se title("Pre and Post Trends With Window = 1 \label{tab: pre and post trends fe`count' $tag}") ///
	keep(c.$indep_var#c.lease_duration_at_trans ///
		 1.freehold#c.$indep_var ///
		 c.interest_rate_lag#c.lease_duration_at_trans ///
		 1.freehold#c.interest_rate_lag ///
		 c.interest_rate_lead#c.lease_duration_at_trans ///
		 1.freehold#c.interest_rate_lead ) ///
	varlabels(c.$indep_var#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}" ///
			  c.interest_rate_lag#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $indep_var_label Lag}" ///
			  1.freehold#c.interest_rate_lag "\multirow{2}{4cm}{Freehold x $indep_var_label Lag}" ///
			  c.interest_rate_lead#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $indep_var_label Lead}" ///
			  1.freehold#c.interest_rate_lead "\multirow{2}{4cm}{Freehold x $indep_var_label Lead}" ) ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _)
}


* Leads and Lags of property sales

sort property_id date_trans
by property_id: gen L_d_log_price = d_log_price[_n-1]
by property_id: gen F_d_log_price = d_log_price[_n+1]

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1
	
	di "Count: `count'"
	
	if  `count' != 1 {
		continue
	}
	
	eststo clear
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold), absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold)  L_d_log_price , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold)  F_d_log_price , absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold)  L_d_log_price F_d_log_price, absorb(`fe') cluster($cluster)
	
	esttab using "$TABLES/pre_and_post_trends_transactions_fe`count'_$tag.tex", ///
	se title("Pre and Post Trends of Transactions \label{tab: pre and post trends transactions fe`count' $tag}") ///
	keep(c.$indep_var#c.lease_duration_at_trans ///
		 1.freehold#c.$indep_var ///
		 L_d_log_price ///
		 F_d_log_price ) ///
	varlabels(c.$indep_var#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}" ///
			  L_d_log_price "\multirow{2}{4cm}{$dep_var_label Lag}" ///
			  F_d_log_price "\multirow{2}{4cm}{$dep_var_label Lead}"  ) ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _)
}


* Leads and Lags of property sales, interacted with interest rate

local count = 0
foreach fe of global fes  {
	di "`fe'"
	
	local count = `count' + 1
	
	di "Count: `count'"
	
	if  `count' != 1 {
		continue
	}
	
	eststo clear
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold), absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold c.L_d_log_price ), absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold  c.F_d_log_price), absorb(`fe') cluster($cluster)
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold  c.L_d_log_price c.F_d_log_price), absorb(`fe') cluster($cluster)
	
	esttab using "$TABLES/pre_and_post_trends_transactions_x_drate_fe`count'_$tag.tex", ///
	se title("Pre and Post Trends of Transactions Interacted With Interest Rate \label{tab: pre and post trends transactions x drate fe`count' $tag}") ///
	keep(c.$indep_var#c.lease_duration_at_trans ///
		 1.freehold#c.$indep_var ///
		 L_d_log_price ///
		 F_d_log_price  ///
		 c.$indep_var#c.L_d_log_price ///
		 c.$indep_var#c.F_d_log_price) ///
	varlabels(c.$indep_var#c.lease_duration_at_trans "\multirow{2}{4cm}{Duration x $indep_var_label}" ///
			  1.freehold#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}" ///
			  L_d_log_price "\multirow{2}{4cm}{$dep_var_label Lag}" ///
			  F_d_log_price "\multirow{2}{4cm}{$dep_var_label Lead}"   ///
			  c.$indep_var#c.L_d_log_price "\multirow{2}{4cm}{$dep_var_label Lag x $indep_var_label}" ///
			  c.$indep_var#c.F_d_log_price "\multirow{2}{4cm}{$dep_var_label Lead x $indep_var_label}"  ) ///
	mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _)
}
