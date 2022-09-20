global DATA "`1'"
global WORKING "`2'"

di "Data folder: $DATA"
di "Working folder: $WORKING"

clear
global DATA "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Input/characteristics"
global WORKING "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Working/stata_working"

// Import data

use "$WORKING/hedonic_characteristics.dta", replace
drop if _n>=1
save "$WORKING/hedonic_characteristics.dta", replace

local dirs : dir "$DATA" dirs "domestic*"

local count = 1
foreach folder in `dirs' {
	di " "
	di " "
	di "`folder', `count'"
	local count = `count'+1
	import delimited "$DATA/`folder'/certificates.csv", clear varnames(1)
	gen folder = "`folder'"
	di "Num obs in file:"
	count
	append using "$WORKING/hedonic_characteristics.dta", force
	di "Total num obs:"
	count
	save "$WORKING/hedonic_characteristics.dta", replace 
}

use "$WORKING/hedonic_characteristics.dta", clear
