use "$WORKING/full_cleaned_data_diff.dta", clear

// Summarize details about the time during which a property is held
sum years_held, detail
sum d_interest_rate, detail
sum d_log_price, detail
sum number_years_at_trans, detail


// Tabulate proportions of types of properties
tab type if duration == "SL"
tab type if duration == "LL"
tab type if duration == "F"
tab type

tab duration if type == "F"
tab duration if type == "D" | type == "S" | type == "T"
tab duration if type == "D" 
tab duration if type == "S"
tab duration if type == "T"

// Investigate mean change in price of properties by duration
gen mean_d_price = d_price/years_held
sum mean_d_price if duration == "SL"
sum mean_d_price if duration == "LL"
sum mean_d_price if duration == "F"
sum mean_d_price

// Residual price by duration
regress price i.quarter_purchase#i.quarter_sale#i.type#i.post_0
