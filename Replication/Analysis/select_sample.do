local differenced = `1'
local restricted = `2'
local logs = `3'

di "differenced = `differenced'"
di "restricted = `restricted'"
di "logs = `logs'"

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"

// Option 1: Run regression on differences (i.e. change in log price and change in interest rate)
if `differenced' {
	use "$INPUT/final_data.dta", clear
	
	global tag "differences"
	
	// We are not restricting the sample, so use all observations
	gen obs_to_use1 = 1
	gen obs_to_use2 = 1
	gen obs_to_use3 = 1
	gen obs_to_use4 = 1
	
	global bucket_name bucket_3_sale
	global bucket_11_name bucket_11_sale
	global dep_var d_log_price
	global indep_var d_interest_rate
	global indep_var_label "$\Delta$ Interest Rate"
	global fes `" "i.location_n##i.date_trans##i.L_date_trans" "i.location_n##i.date_trans##i.L_date_trans##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.$bucket_name"  "'
	global cluster "date_trans L_date_trans location_n"
	global fe_vars "location_n date_trans L_date_trans type_n price_quintile"
}

// Option 2: Run regression on levels 
else {
	use "$INPUT/full_cleaned_data.dta", clear
	global tag "levels"
	
	// We are also interested in recording results restricting the data set only to those observations that would be in the differences set
	if `restricted' {
		global tag "restricted_$tag"
		sort property_id date_trans
		by property_id: gen L_date_trans = date_trans[_n-1]
		by property_id: gen L_date_registered = date_registered[_n-1]
		
		// Drop properties with only one date or no registration information
		drop if missing(L_date_trans)
		
		// Drop lease extensions
		drop if leasehold & date_registered != L_date_registered
		
		// Generate useful data
		cap drop bucket_3 price_quintile
		xtile bucket_3 = lease_duration_at_trans, nq(2)
		replace bucket_3 = 3 if !leasehold

		xtile price_quintile = price, nq(5)
		
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
		
		egen id3 = group(date_trans L_date_trans location_n type_n price_quintile)
		duplicates tag id3, gen(dup3)
		gen obs_to_use3 = 0 if dup3==0
		replace obs_to_use3 = 1 if dup3 > 0
		count if obs_to_use3
		
		egen id4_1 = group(location_n bucket_3)
		gen id4_2 = id2
		duplicates tag id4_1, gen(dup4_1)
		duplicates tag id4_2, gen(dup4_2)
		gen obs_to_use4 = 0 if dup4_1==0 | dup4_2==0
		replace obs_to_use4 = 1 if dup4_1 > 0 & dup4_2 > 0
		count if obs_to_use4
	}
	
	else {
		// Generate useful data
		cap drop bucket_3 price_quintile
		xtile bucket_3 = lease_duration_at_trans, nq(2)
		replace bucket_3 = 3 if !leasehold

		xtile price_quintile = price, nq(5)
		
		gen obs_to_use1 = 1
		gen obs_to_use2 = 1
		gen obs_to_use3 = 1
		gen obs_to_use4 = 1
	}
	
	xtile bucket_11 = lease_duration_at_trans, nq(10)
	replace bucket_11 = 11 if !leasehold
	
	// Save relevant variable names
	global bucket_name bucket_3
	global bucket_11_name bucket_11
	global indep_var interest_rate
	global indep_var_label "Interest Rate"
	global fes `" "i.location_n##i.date_trans" "i.location_n##i.date_tran##i.type_n" "i.location_n##i.date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.type_n i.location_n##i.$bucket_name" "'
	global cluster "date_trans location_n"
	global fe_vars "location_n date_trans type_n price_quintile"
	
	// We want to look at the effect on both price and log_price
	if `logs' {
		global tag "logs_$tag"
		global dep_var log_price
	}
	else {
		global dep_var price
	}
}

di "Tag: $tag"
