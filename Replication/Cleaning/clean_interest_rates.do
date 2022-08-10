import delimited "$INTEREST_RATES/IRLTLT01GBM156N.csv", clear

gen date_interest_rates = date(date, "YMD")
drop date
rename date_interest_rates date
rename irltlt01gbm156n interest_rate

gen year = year(date)
gen month = month(date)

save "$WORKING/interest_rates.dta", replace
