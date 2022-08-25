global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Main Regression"

local differenced = 0
if `differenced' {
	use "$INPUT/final_data.dta", clear
	
	local tag "differences"
	
	local bucket_name bucket_3_sale
	local dep_var d_log_price
	local indep_var d_interest_rate
	local indep_var_label "$\Delta$ Interest Rate"
	local fes "i.location_n##i.date_trans##i.L_date_trans" ///
			  "i.location_n##i.date_trans##i.L_date_trans##i.type_n" ///
			  "i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n" ///
			  "i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.`bucket_name'"
	local cluster "date_trans L_date_trans location_n"
	local fe_vars "location_n date_trans L_date_trans type_n price_quintile"
}
else {
	//use "$INPUT/full_cleaned_data.dta", clear
	local tag "levels"
	
	// Drop leaseholds without registration data
	drop if leasehold & missing(lease_duration_at_trans)
	
	// We are also interested in recording results restricting the data set only to those observations that would be in the differences set
	local restricted = 0
	if `restricted' {
		local tag "levels_restricted"
		duplicates tag property_id, gen(dup)
		drop if dup==0
	}
	
	// Generate useful data
	cap drop bucket_3 price_quintile
	xtile bucket_3 = lease_duration_at_trans, nq(2)
	replace bucket_3 = 3 if !leasehold

	xtile price_quintile = price, nq(5)
	
	// Save relevant variable names
	local bucket_name bucket_3
	local dep_var log_price
	local indep_var interest_rate
	local indep_var_label "Interest Rate"
	local fes `" "i.location_n##i.date_trans" "i.location_n##i.date_tran##i.type_n" "i.location_n##i.date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.type_n i.location_n##i.`bucket_name'" "'
	local cluster "date_trans location_n"
	local fe_vars "location_n date_trans type_n price_quintile"
}

eststo clear 
foreach fe of local fes  {
	di "`fe'"
	di "reghdfe `dep_var' i.`bucket_name'##c.`indep_var', absorb(`fe') cluster(`cluster')"
	eststo: reghdfe `dep_var' i.`bucket_name'##c.`indep_var', absorb(`fe') cluster(`cluster')
}
esttab using "$RESULTS/main_regression_`tag'.tex", ///
	se title("Baseline Regression Results \label{tab: main `tag'}") ///
	keep(2.`bucket_name'#c.`indep_var' ///
		 3.`bucket_name'#c.`indep_var') ///
	varlabels(2.`bucket_name'#c.`indep_var' "\multirow{2}{4cm}{High Duration Leasehold x `indep_var_label'}" ///
			  3.`bucket_name'#c.`indep_var' "\multirow{2}{4cm}{Freehold x `indep_var_label'}") ///
	gaps replace
	
// Repeat column 1 using observations from column 2

eststo clear
local fe1 : word 1 of `fes'
local fe2 : word 2 of `fes'
di "reghdfe `dep_var' i.`bucket_name'##c.`indep_var', absorb(`fe2') cluster(`cluster')"
reghdfe `dep_var' i.`bucket_name'##c.`indep_var', absorb(`fe2') cluster(`cluster')
gen obs_to_use = e(sample)
di "reghdfe `dep_var' i.`bucket_name'##c.`indep_var' if obs_to_use, absorb(`fe1') cluster(`cluster')"
eststo: reghdfe `dep_var' i.`bucket_name'##c.`indep_var' if obs_to_use, absorb(`fe1') cluster(`cluster')
esttab using "$RESULTS/main_regression_restricted_to_col_2_`tag'.tex", ///
	se title("Baseline Regression Results, Without Singleton Observations \label{tab: main `tag' restricted col2}") ///
	keep(2.`bucket_name'#c.`indep_var' ///
		 3.`bucket_name'#c.`indep_var') ///
	varlabels(2.`bucket_name'#c.`indep_var' "\multirow{2}{4cm}{High Duration Leasehold x `indep_var_label'}" ///
			  3.`bucket_name'#c.`indep_var' "\multirow{2}{4cm}{Freehold x `indep_var_label'}") ///
	gaps replace
drop obs_to_use
	
// Repeat all using same observations for all columns
egen id = group(`fe_vars')
duplicates tag id, gen(dup)
keep if dup!=0

local fe4 : word 4 of `fes'
reghdfe `dep_var' i.`bucket_name'##c.`indep_var', absorb(`fe4') cluster(`cluster')
gen obs_to_use = e(sample)
keep if obs_to_use

eststo clear 
foreach fe of local fes  {
	di "`fe'"
	di "reghdfe `dep_var' i.`bucket_name'##c.`indep_var', absorb(`fe') cluster(`cluster')"
	eststo: reghdfe `dep_var' i.`bucket_name'##c.`indep_var', absorb(`fe') cluster(`cluster')
}
esttab using "$RESULTS/main_regression_fully_restricted_`tag'.tex", ///
	se title("Baseline Regression Results \label{tab: main `tag'}") ///
	keep(2.`bucket_name'#c.`indep_var' ///
		 3.`bucket_name'#c.`indep_var') ///
	varlabels(2.`bucket_name'#c.`indep_var' "\multirow{2}{4cm}{High Duration Leasehold x `indep_var_label'}" ///
			  3.`bucket_name'#c.`indep_var' "\multirow{2}{4cm}{Freehold x `indep_var_label'}") ///
	gaps replace
