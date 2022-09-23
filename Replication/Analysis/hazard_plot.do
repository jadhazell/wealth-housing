
* Define input and output sources
global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global WORKING "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Working/stata_working"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Lease Extensions"
global FIGURES "$RESULTS/Figures/Lease Extensions"

forvalues i = 1/3 {
	
	* First, run just on flats from final data
	if `i' == 2 {
		use  "$INPUT/full_cleaned_data.dta", clear
		keep if leasehold & type=="F"
		global tag "sample_flats"
	}
	if `i' == 1 {
		use  "$INPUT/full_cleaned_data.dta", clear
		keep if leasehold
		global tag "sample_all_types"
	}
	if `i' == 3 {
		use "$WORKING/lease_data.dta", clear
		global tag "all_leases"
		rename merge_key property_id
	}

	keep property_id date_registered number_years
	
	duplicates drop

	sort property_id date_registered
	by property_id: gen F_date_registered = date_registered[_n+1]
	by property_id: gen F_number_years = number_years[_n+1]

	gen time_elapsed = F_date_registered - date_registered
	gen number_years_at_extension = number_years - time_elapsed
	gen extension_amt = F_number_years - number_years_at_extension
	
	drop if extension_amt < 0
	

	gen duration_in_final_year = number_years - (2022 - date_registered)
	replace duration_in_final_year = number_years_at_extension if !missing(extension_amt)

	forvalues duration = 1/1000 {
		di "`duration'"
		* For each lease, record if the property obtained this duration at some point in its lifetime time
		gen extended_at_`duration' = 0 if `duration' <= number_years & `duration' >= duration_in_final_year
		* Identify leases that were extended in that year 
		replace extended_at_`duration' = 1 if number_years_at_extension == `duration'
	}
	
	* Rerun for each type of lease 
	
	forvalues j=1/3  {
		
		if `j'==2 {
			drop if extension_amt <= 10
			global tag "no_negligible_$tag"
		}
		
		if `j'==3 {
			drop if extension_amt <= 200
			global tag "no_negligible_or_short_$tag"
		}
		
		preserve

			gcollapse (mean) extended_at_*

			gen n = 1

			greshape long extended_at_, i(n) j(duration_at_extension)
			rename extended_at extension_rate

			twoway bar extension_rate duration_at_extension, xtitle("Lease Duration") ytitle("Extension Rate")
			graph export "$FIGURES/hazard_rate_$tag.png", replace

			twoway bar extension_rate duration_at_extension if duration_at_extension<=100, xtitle("Lease Duration") ytitle("Extension Rate")
			graph export "$FIGURES/hazard_rate_zoom_$tag.png", replace
		
		restore
		
	}
	
}
