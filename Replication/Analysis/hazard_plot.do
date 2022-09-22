
* Define input and output sources
global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Lease Extensions"
global FIGURES "$RESULTS/Figures/Lease Extensions"

use  "$INPUT/full_cleaned_data.dta", clear

keep if leasehold
keep property_id date_trans year quarter date_registered lease_duration_at_trans number_years

* Make date_trans a date var
gen date = date()

* Set as panel data
xtset property_id date_trans
