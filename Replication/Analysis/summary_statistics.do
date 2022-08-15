use "$WORKING/full_cleaned_data_diff.dta", clear

// Label variables
label var years_held "Years Held"
label var d_interest_rate "$\Delta$ interest rate"
label var d_log_price "$\Delta$ log(house price)"
label var number_years_at_trans "Lease duration"

label var price "Sale Price"
label var L_price "Purchase Price"

replace type = "Detached House" if type == "D"
replace type = "Flat" if type == "F"
replace type = "Unclassified" if type == "O"
replace type = "Semi-Detached House" if type == "S"
replace type = "Terraced House" if type == "T"

replace duration = "Below Median Leasehold" if duration == "SL"
replace duration = "Above Median Leasehold" if duration == "LL"
replace duration = "Freehold" if duration == "F"

label define duration_n 1 "Below Median Leasehold" 2 "Above Median Leasehold" 3 "Freehold", modify
// encode duration, gen(duration_n)

// Summarize details about the time during which a property is held
eststo clear
estpost sum years_held d_interest_rate d_log_price number_years_at_trans, detail
esttab using "$RESULTS/summary_stats.tex", cells("count(fmt(a0)) mean(fmt(a0)) sd(fmt(a0)) p1(fmt(a0)) p10(fmt(a0)) p50(fmt(a0)) p90(fmt(a0)) p99(fmt(a0))") nonumber not label title("Summary Statistics") replace

// Tabulate proportions of types of properties
eststo clear
estpost tabulate type duration_n, label
esttab using "$RESULTS/properties_by_duration.tex", unstack nonumber label title("Properties by Duration") replace

// Investigate mean change in price of properties by duration
eststo clear
estpost tabstat price L_price, by(duration_n) statistics(mean sd) columns(statistics) listwise
esttab using "$RESULTS/price_by_duration.tex", main(mean) aux(sd) nostar unstack label noobs nonote title("Price by Duration") replace

// Residual price by duration
eststo clear
eststo: reghdfe L_price i.duration_n, absorb(i.quarter_purchase##i.quarter_sale##i.type_n##i.location_n)
eststo: reghdfe d_log_price i.duration_n, absorb(i.quarter_purchase##i.quarter_sale##i.type_n##i.location_n)
esttab using "$RESULTS/residual_price_by_duration.tex", title("Residualized Price by Duration") replace

// Normalized annual growth by duration
eststo clear
cap gen mean_d_price = d_log_price/years_held
estpost tabstat mean_d_price, by(duration_n) statistics(mean sd)
esttab using "$RESULTS/change_in_price_by_duration.tex", main(mean) aux(sd) nostar unstack nonumber label title("Average change in log price (normalized by years held) by duration") replace
