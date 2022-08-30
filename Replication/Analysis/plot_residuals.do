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

use "$INPUT/full_cleaned_data_with_lags.dta", clear
global tag "levels"	

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Log Transformation and Residuals"

global TABLES "$RESULTS/Tables"
global FIGURES "$RESULTS/Figures"

// Select correct sample according to parameters
do select_sample `differenced' `restricted' `logs' `duplicate_registration' `flats' `windsor' `under_80' `post_2004' `below_median_price' `above_median_price'
drop if !leasehold

// Useful variables for later:
gen interacted_term = lease_duration_at_trans * $indep_var
winsor lease_duration_at_trans, p(0.01) gen(lease_duration_at_trans_win)
winsor interacted_term, p(0.01) gen(interacted_term_win)

/////////////////////////////////////////////////////////////
// First get residuals for conitnuous by continuous regression
////////////////////////////////////////////////////////////

local count=0
foreach fe of global fes  {
	
	local count = `count'+1
	if `count' == 4 {
		continue
	}
	
	local fe = "i.location_n##i.date_trans"
	
	// Get residuals on first stage
	reghdfe interacted_term lease_duration_at_trans $indep_var, absorb(`fe') cluster($cluster) residuals(interacted_term_residuals)
	predict fitted_values, xb
	predict fitted_values_d, xbd
	
	winsor interacted_term_residuals, h(5) gen(interacted_term_residuals_win)
	winsor fitted_values, h(5) gen(fitted_values_win)
	
	// Plot residuals by fitted values
	graph twoway (scatter interacted_term_residuals_win fitted_values_win), ytitle("Residuals From First Stage") xtitle("Fitted Values") yline(0)
	graph export "$FIGURES/first_stage_residuals_by_fitted_fe`count'_$tag.png", replace

	// Plot residuals by lease duration
	graph twoway (scatter interacted_term_residuals_win lease_duration_at_trans_win), ytitle("Residuals From First Stage") xtitle("Lease Duration At Transaction (Winsorized at 0.01 level)") yline(0) 
	graph export "$FIGURES/first_stage_residuals_by_indepvar_fe`count'_$tag.png", replace
	
	// Plot residuals by interaction term
	graph twoway (scatter interacted_term_residuals_win interacted_term_win), ytitle("Residuals From First Stage") xtitle("Lease Duration At Transaction x Interest Rate (Winsorized at 0.01 level)") yline(0) 
	graph export "$FIGURES/first_stage_residuals_by_depvar_fe`count'_$tag.png", replace

	// Plot residual by price
	local count=1
	graph twoway (scatter price_win interacted_term_residuals_win), xtitle("Residual From First Stage") ytitle("Price (Winsorized at 0.01 level)") yline(0)
	graph export "$FIGURES/first_stage_residuals_by_price_fe`count'_$tag.png", replace
}
