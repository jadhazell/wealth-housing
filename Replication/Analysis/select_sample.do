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

di "differenced = `differenced'"
di "restricted = `restricted'"
di "logs = `logs'"

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"

// First: select data file
if `differenced' {
	use "$INPUT/final_data.dta", clear
	global tag "differences"
}
else {
	use "$INPUT/full_cleaned_data_with_lags.dta", clear
	global tag "levels"	
}

// Next: drop observations depending on parameters
	
if `under_80' {
	global tag "drop_under_80_$tag"
	drop if lease_duration_at_trans < 80
}

if `duplicate_registration' {
	drop if leasehold & missing(number_years_missing)
	if `differenced' {
		drop if leasehold & missing(L_number_years_missing)
	}
	global tag "missing_$tag"
}

if `flats' {
	drop if type != "F"
	global tag "flats_$tag"
}

if `post_2004' {
	drop if date_trans < 2004
	if `differenced' {
		drop if L_date_trans < 2004
	}
	global tag "post_2004_$tag"
}

if `below_median_price' {
	sum price, detail
	keep if price < r(p50)
	global tag "cheap_$tag"
}

if `above_median_price' {
	sum price, detail
	keep if price >= r(p50)
	global tag "expensive_$tag"
}
	
if `differenced' {
	// We are not restricting the sample, so use all observations
	gen obs_to_use1 = 1
	gen obs_to_use2 = 1
	gen obs_to_use3 = 1
	gen obs_to_use4 = 1
	gen obs_to_use5 = 1
	
	global bucket_name bucket_3_restricted
	global bucket_11_name bucket_11_sale
	global indep_var d_interest_rate
	global indep_var_label "$\Delta$ Interest Rate"
	global fes `" "i.location_n##i.date_trans##i.L_date_trans" "i.location_n##i.date_trans##i.L_date_trans##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.$bucket_name"  "'
	global cluster "date_trans L_date_trans location_n"
	global fe_vars "location_n date_trans L_date_trans type_n price_quintile"
	
	global iv_var d_cesa_bianchi
	global iv_var_label "$\Delta$ Monetary Shock"
	
	global title "Differences"
	
	// We want to look at the effect on both price and log_price
	if `logs' {
		global tag "logs_$tag"
		global dep_var d_log_price
		global dep_var_label "$\Delta$ log(price)"
	}
	else {
		global tag "no_logs_$tag"
		global dep_var d_price
		global dep_var_label "$\Delta$ price"
	}
	
}
else {
	// We are also interested in recording results restricting the data set only to those observations that would be in the differences set
	if `restricted' {
		global tag "restrictedobs_$tag"
		
		// Drop properties with only one date or no registration information
		drop if missing(L_date_trans)
		
		// Drop lease extensions
		drop if leasehold & date_registered != L_date_registered
		
		// Generate keys for fixed effects
		egen id1 = group(date_trans L_date_trans location_n)
		duplicates tag id1, gen(dup1)
		gen obs_to_use1 = 0 if dup1==0
		replace obs_to_use1 = 1 if dup1 > 0
		count if obs_to_use1
		
		egen id2 = group(date_trans L_date_trans location_n type_n)
		duplicates tag id2, gen(dup2)
		gen obs_to_use2 = 0 if dup2==0
		replace obs_to_use2 = 1 if dup2 > 0
		count if obs_to_use2
		
		egen id3 = group(date_trans L_date_trans location_n type_n price_quintile_restricted)
		duplicates tag id3, gen(dup3)
		gen obs_to_use3 = 0 if dup3==0
		replace obs_to_use3 = 1 if dup3 > 0
		count if obs_to_use3
		
		egen id4_1 = group(location_n bucket_3_restricted)
		gen id4_2 = id2
		duplicates tag id4_1, gen(dup4_1)
		duplicates tag id4_2, gen(dup4_2)
		gen obs_to_use4 = 0 if dup4_1==0 | dup4_2==0
		replace obs_to_use4 = 1 if dup4_1 > 0 & dup4_2 > 0
		count if obs_to_use4
		
		gen obs_to_use5 = obs_to_use2
		
		
		global bucket_name bucket_3_restricted
	}
	
	else {
		
		gen obs_to_use1 = 1
		gen obs_to_use2 = 1
		gen obs_to_use3 = 1
		gen obs_to_use4 = 1
		gen obs_to_use5 = 1
		
		global bucket_name bucket_3
	}
	
	// Save relevant variable names
	global bucket_11_name bucket_11
	global indep_var interest_rate
	global indep_var_label "Interest Rate"
	global fes `" "i.location_n##i.date_trans" "i.location_n##i.date_trans##i.type_n"  "i.location_n##i.date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.type_n i.location_n##i.$bucket_name" "i.location_n##i.date_trans##i.type_n i.property_id_n" "'
	global cluster "date_trans location_n"
	global fe_vars "location_n date_trans type_n price_quintile"
	
	global iv_var cesa_bianchi_cum
	global iv_var_label "Monetary Shock"
	
	global title "Levels"
	
	// We want to look at the effect on both price and log_price
	if `logs' {
		global tag "logs_$tag"
		global dep_var log_price
		global dep_var_label "log(price)"
	}
	else {
		global tag "no_logs_$tag"
		global dep_var price
		global dep_var_label "price"
	}
}

if `windsor' {
	global win "_win"
	global dep_var "$dep_var$win"
	global tag "winsor_$tag"
}

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

di "==================================================="
di "Tag: $tag"
di "Dependent variable: $dep_var"
di "Independent variable: $indep_var"
di "==================================================="
