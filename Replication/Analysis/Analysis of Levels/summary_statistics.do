global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Summary Statistics"

use "$INPUT/final_data.dta", clear

// Label variables
label var years_held "Years Held"
label var d_interest_rate "$\Delta$ interest rate"
label var d_log_price "$\Delta$ log(house price)"
label var lease_duration_at_trans "Lease duration"

label var price "Sale Price"
label var L_price "Purchase Price"

replace type = "Detached House" if type == "D"
replace type = "Flat" if type == "F"
replace type = "Unclassified" if type == "O"
replace type = "Semi-Detached House" if type == "S"
replace type = "Terraced House" if type == "T"

label define bucket_3_sale 1 "Below Median Leasehold" 2 "Above Median Leasehold" 3 "Freehold", modify
label define bucket_3_purchase 1 "Below Median Leasehold" 2 "Above Median Leasehold" 3 "Freehold", modify

// Check and see how many observations are missing purchase lease info by year bucket
gen no_purchase_lease_info = !has_purchase_lease
eststo clear
estpost tabstat no_purchase_lease_info, by(year_bucket_sale) statistics(mean sum) columns(statistics) listwise
esttab using "$RESULTS/number_missing_by_year.tex", cells("mean sum") nostar nonumber unstack label noobs nonote title("Observations Missing Purchase Lease Data by Year Bucket") collabels("Percent" "Number") replace

// Check and see how many observations have lease extensions by year bucket
eststo clear
estpost tabstat lease_was_extended, by(year_bucket_sale) statistics(mean sum) columns(statistics) listwise
esttab using "$RESULTS/number_extended_by_year.tex", cells("mean sum") nostar nonumber unstack label noobs nonote title("Observations With Extended Leases by Sale Year Bucket") collabels("Percent" "Number") replace

// Summarize mean property lease for each x-tile
replace lease_duration_at_trans = 0 if !leasehold // Do this so that freeholds are still counted
eststo clear
estpost tabstat lease_duration_at_trans, by(bucket_3_sale) statistics(mean n) columns(statistics) listwise
esttab using "$RESULTS/duration_by_duration_buckets_3.tex", cells("mean count") aux(sd) nostar unstack label noobs nonote title("Mean Lease Duration by Bucket (2 Buckets)") collabels("Mean" "Count") varlabels(1 "Below Median" 2 "Above Median" 3 "Freehold" 4 "Extended") replace

eststo clear
estpost tabstat lease_duration_at_trans, by(bucket_6_sale) statistics(mean n) columns(statistics) listwise
esttab using "$RESULTS/duration_by_duration_buckets_6.tex", cells("mean count") aux(sd) nostar unstack label noobs nonote title("Mean Lease Duration by Bucket (2 Buckets)") collabels("Mean" "Count") varlabels(1 "Quintile 1" 2 "Quintile 2" 3 "Quintile 3" 4 "Quintile 4" 5 "Quintile 5" 6 "Freehold" 7 "Extended") nonumber replace

eststo clear
estpost tabstat lease_duration_at_trans, by(bucket_11_sale) statistics(mean n) columns(statistics) listwise
esttab using "$RESULTS/duration_by_duration_buckets_11.tex", cells("mean count") aux(sd) nostar unstack label noobs nonote title("Mean Lease Duration by Bucket (11 Buckets) \label{tab:means_by_bucket_deciles}") collabels("Mean" "Count") varlabels(1 "Quintile 1" 2 "Quintile 2" 3 "Quintile 3" 4 "Quintile 4" 5 "Quintile 5" 6 "Quintile 6" 7 "Quintile 7" 8 "Quintile 8" 9 "Quintile 9" 10 "Quintile 10" 11 "Freehold" 12 "Extended") nonumber replace

// Summarize details about the time during which a property is held
eststo clear
replace lease_duration_at_trans = . if !leasehold
estpost sum years_held d_interest_rate d_log_price lease_duration_at_trans, detail
esttab using "$RESULTS/summary_stats.tex", cells("count(fmt(a0)) mean(fmt(a0)) sd(fmt(a0)) p1(fmt(a0)) p10(fmt(a0)) p50(fmt(a0)) p90(fmt(a0)) p99(fmt(a0))") nonumber not label title("Summary Statistics") replace

// Tabulate proportions of types of properties
eststo clear
estpost tabulate type bucket_3_sale, label
esttab using "$RESULTS/properties_by_duration.tex", unstack nonumber label title("Properties by Duration") replace

// Investigate mean change in price of properties by duration
eststo clear
estpost tabstat price L_price, by(bucket_3_sale) statistics(mean sd) columns(statistics) listwise
esttab using "$RESULTS/price_by_duration.tex", main(mean) aux(sd) nostar unstack label noobs nonote title("Price by Duration") replace

// Residual price by duration
eststo clear
eststo: reghdfe L_price i.bucket_3_sale, absorb(i.date_trans##i.L_date_trans##i.type_n##i.location_n) cluster(date_trans L_date_trans location)
eststo: reghdfe d_log_price i.bucket_3_sale, absorb(i.date_trans##i.L_date_trans##i.type_n##i.location_n) cluster(date_trans L_date_trans location)
esttab using "$RESULTS/residual_price_by_duration.tex", title("Residualized Price by Duration") replace

// Normalized annual growth by duration
eststo clear
cap gen mean_d_price = d_log_price/years_held
estpost tabstat mean_d_price, by(bucket_3_sale) statistics(mean sd)
esttab using "$RESULTS/change_in_price_by_duration.tex", main(mean) aux(sd) nostar unstack nonumber label title("Average change in log price (normalized by years held) by duration") replace
