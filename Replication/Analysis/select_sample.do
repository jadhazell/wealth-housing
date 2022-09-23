local differenced = `1'
local logs = `2'
local restricted = `3'
local drop_under_80 = `4'
local only_flats = `5'

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global WORKING "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Working/stata_working"

// First: select data file
if `differenced' {
	use "$INPUT/final_data.dta", clear
	global tag "differences"
}
else {
	use "$INPUT/full_cleaned_data_with_lags.dta", clear
	global tag "levels"	
}

* Drop observations based on arguments

if `drop_under_80' {
	drop if leasehold & lease_duration_at_trans <= 80/1000
	global tag "drop_under_80_$tag"	
}

if `only_flats' {
	drop if type != "F"
	global tag "only_flats_$tag"	
}


* Bucket name is the same for differences and levels
global bucket_name bucket_3
global bucket_11_name bucket_11

if `differenced' {
	*We are not restricting the sample, so use all observations
	gen obs_to_use1 = 1
	gen obs_to_use2 = 1
	gen obs_to_use3 = 1
	gen obs_to_use4 = 1
	gen obs_to_use5 = 1
	
	global indep_var d_interest_rate
	global indep_var_label "$\Delta$ Interest Rate"
	global fes `" "i.district_n##i.year##i.L_year" "i.city_n##i.year##i.L_year" "i.location_n##i.year##i.L_year" "i.postcode_n##i.year##i.L_year" "i.district_n##i.year##i.L_year##i.type_n" "i.district_n##i.year##i.L_year##i.type_n##i.L_price_quint_group" "i.district_n##i.year##i.L_year##i.type_n##i.L_price_dec_group" "'
	
	if `only_flats' {
		global fes `" "i.district_n##i.year##i.L_year" "i.city_n##i.year##i.L_year" "i.location_n##i.year##i.L_year" "i.postcode_n##i.year##i.L_year" "i.district_n##i.year##i.L_year##i.L_price_quint_group" "i.district_n##i.year##i.L_year##i.L_price_dec_group" "'
	}
	
	global cluster "date_trans L_date_trans location_n"
	
	global iv_var d_cesa_bianchi
	global iv_var_label "$\Delta$ Monetary Shock"
	
	global title "Differences"
	
	* Choose dependent variable as log vs non log
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
	* We are also interested in recording results restricting the data set only to those observations that would be in the differences set
	if `restricted' {
		global tag "restrictedobs_$tag"
		
		* Drop properties with only one date or no registration information
		drop if missing(L_date_trans)
		
		* Drop lease extensions
		drop if leasehold & date_registered != L_date_registered
		
		* Generate keys for fixed effects
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
	}
	
	* Save relevant variable names
	global indep_var interest_rate
	global indep_var_label "Interest Rate"
	global fes `" "i.location_n##i.date_trans" "i.location_n##i.date_trans##i.type_n"  "i.location_n##i.date_trans##i.price_quintile##i.type_n" "i.location_n##i.date_trans##i.type_n i.location_n##i.$bucket_name" "i.location_n##i.date_trans##i.type_n i.property_id_n" "'
	global cluster "date_trans location_n"
	global fe_vars "location_n date_trans type_n price_quintile"
	
	global iv_var cesa_bianchi_cum
	global iv_var_label "Monetary Shock"
	
	global title "Levels"
	
	* Choose log vs not log dependent variable
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

* Normalize lease duration
replace lease_duration_at_trans = 0 if freehold

di "==================================================="
di "Tag: $tag"
di "Dependent variable: $dep_var"
di "Independent variable: $indep_var"
di "==================================================="

