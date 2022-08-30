global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Lease Extensions"

use "$INPUT/final_data_with_extensions.dta", clear

// Generate summary stats
replace lease_duration_at_trans = 0 if !leasehold // Do this so that freeholds are still counted
eststo clear
estpost tabstat lease_duration_at_trans, by(bucket_3_sale) statistics(mean n) columns(statistics) listwise
esttab using "$RESULTS/duration_by_duration_buckets_3.tex", cells("mean count") aux(sd) nostar unstack label noobs nonote title("Mean Lease Duration by Bucket (2 Buckets) \label{tab: summary}") collabels("Mean" "Count") varlabels(1 "Below Median" 2 "Above Median" 3 "Freehold" 4 "Extended") replace
replace lease_duration_at_trans = . if !leasehold 

// Regression with lease extensions in separate category
eststo clear 
 eststo: reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
 eststo: reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)
 eststo: reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n) cluster(date_trans L_date_trans location_n)
 eststo: reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.bucket_3_sale) cluster(date_trans L_date_trans location_n)


esttab using "$RESULTS/main_regression.tex", ///
	se title("Baseline Regression Results \label{tab: main regression}") ///
	keep(2.bucket_3_sale#c.d_interest_rate ///
	3.bucket_3_sale#c.d_interest_rate ///
	4.bucket_3_sale#c.d_interest_rate) ///
	varlabels( 2.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{High Duration Leasehold x $\Delta$ Interest Rate}" /// 
	3.bucket_3_sale#c.d_interest_rate "\multirow{2}4cm}{Freehold x $\Delta$ Interest Rate}" ///
	4.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{Lease Extended x $\Delta$ Interest Rate}") replace

	
// Divide data by how many years there were between the purchase registration date and the sale registration date if the lease was extended
gen diff = date_registered - L_date_registered
replace diff = . if !lease_was_extended

// Generate summary stats for lease extensions by difference between purchase and sale registration date
eststo clear
estpost tabstat diff, by(ext_bucket) statistics(mean n) columns(statistics) listwise
esttab using "$RESULTS/difference_by_difference.tex", cells("mean count") aux(sd) nostar unstack label noobs nonote title("Mean Difference (Sale Registration Date - Purchase Registration Date) by Difference Quintiles \label{tab: summary diff}") collabels("Mean" "Count") varlabels(1 "First Quintile" 2 "Second Quintile" 3 "Third Qunitile" 4 "Fourth Quintile" 5 "Fifth Quintile") replace

// Generate histogram of lease extension amount
gen number_years_before_renewal = L_number_years - (date_registered - L_date_registered)
gen extension_amt = number_years - number_years_before_renewal
twoway histogram extension_amt if lease_was_extended
graph export "$RESULTS/extension_histogram.png", replace

twoway histogram extension_amt if lease_was_extended & extension_amt > 0
graph export "$RESULTS/non_negative_extension_histogram.png", replace

twoway histogram extension_amt if lease_was_extended & extension_amt > 10
graph export "$RESULTS/greater_than_10_extension_histogram.png", replace

twoway histogram extension_amt if lease_was_extended & diff > 5
graph export "$RESULTS/large_diff_extension_histogram.png", replace

// Generate histogram of lease length right before extension 
twoway histogram number_years_before_renewal if lease_was_extended
graph export "$RESULTS/length_histogram.png", replace

twoway histogram number_years_before_renewal if lease_was_extended & extension_amt > 0
graph export "$RESULTS/non_negative_length_histogram.png", replace

twoway histogram number_years_before_renewal if lease_was_extended & extension_amt > 10
graph export "$RESULTS/greater_than_10_length_histogram.png", replace

// Scatter plot of lease length before and after extensions
label var number_years "Lease Duration After Extension"
label var number_years_before_renewal "Lease Duration Before Extension"
twoway (scatter number_years number_years_before_renewal) (lfit number_years number_years_before_renewal) if lease_was_extended
graph export "$RESULTS/scatter_all.png", replace

twoway (scatter number_years number_years_before_renewal) (lfit number_years number_years_before_renewal) if lease_was_extended & extension_amt > 0
graph export "$RESULTS/scatter_non_negative.png", replace

twoway (scatter number_years number_years_before_renewal) (lfit number_years number_years_before_renewal) if lease_was_extended & extension_amt > 10
graph export "$RESULTS/scatter_greater_than_10.png", replace

// Regression, separating lease extensions by length of extension
gen ext_bucket=1 if lease_was_extended & extension_amt < 0
replace ext_bucket=2 if lease_was_extended & extension_amt >= 0 & extension_amt < 10
replace ext_bucket=3 if lease_was_extended & extension_amt >= 10 & extension_amt < 200
replace ext_bucket=4 if lease_was_extended & extension_amt >= 200
replace bucket_3_sale = ext_bucket + 3 if lease_was_extended

eststo clear 
 eststo: reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
 eststo: reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)
 eststo: reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n) cluster(date_trans L_date_trans location_n)
 eststo: reghdfe d_log_price i.bucket_3_sale##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.bucket_3_sale) cluster(date_trans L_date_trans location_n)


esttab using "$RESULTS/main_regression_divided.tex", ///
	se title("Baseline Regression Results \label{tab: main regression divided}") ///
	keep(2.bucket_3_sale#c.d_interest_rate ///
	3.bucket_3_sale#c.d_interest_rate ///
	4.bucket_3_sale#c.d_interest_rate ///
	5.bucket_3_sale#c.d_interest_rate ///
	6.bucket_3_sale#c.d_interest_rate ///
	7.bucket_3_sale#c.d_interest_rate) ///
	varlabels( ///
	2.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{High Duration Leasehold x $\Delta$ Interest Rate}" /// 
	3.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{Freehold x $\Delta$ Interest Rate}" ///
	4.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{Negative Extensions x $\Delta$ Interest Rate}" ///
	5.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{Near Zero Extensions x $\Delta$ Interest Rate}" ///
	6.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{Short Extensions (10-200 years) x $\Delta$ Interest Rate}" ///
	7.bucket_3_sale#c.d_interest_rate "\multirow{2}{4cm}{Long Extensions (200+ years) x $\Delta$ Interest Rate}") ///
	gaps replace
