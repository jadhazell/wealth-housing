
global INTEREST_RATES "`1'"
global WORKING "`2'"

di "Interest rates data folder: $INTEREST_RATES"
di "Working folder: $WORKING"

// Monetary rates
import delimited "$INTEREST_RATES/CTV_MonPolTransmission.csv", clear
drop if missing(cesa_bianchi) & missing(cloyne_hurtgen)

gen year = real(substr(v1, 1, 4))
gen month = real(substr(v1, 6, .))
egen date_str = concat(year month), punct("-")
gen date = date(date_str, "YM")
format date %td
drop v1 date_str month year

// Cumulate series
sort date
gen cesa_bianchi_cum = cesa_bianchi if _n == 1
gen cloyne_hurtgen_cum = cloyne_hurtgen if _n == 1

replace cesa_bianchi_cum = cesa_bianchi[_n] + cesa_bianchi_cum[_n-1] if _n>1
replace cloyne_hurtgen_cum = cloyne_hurtgen[_n] + cloyne_hurtgen_cum[_n-1] if _n>1

save "$WORKING/monetary_rates.dta", replace

// Bond rates
import delimited "$INTEREST_RATES/IRLTLT01GBM156N.csv", clear

gen date_interest_rates = date(date, "YMD")
drop date
rename date_interest_rates date
format date %td
rename irltlt01gbm156n interest_rate

merge 1:1 date using "$WORKING/monetary_rates.dta"

gen year = year(date)
gen month = month(date)
gen quarter = quarter(date)

// Aggregate at quarter level
collapse (mean) interest_rate cloyne_hurtgen_cum cesa_bianchi_cum, by(year quarter)

// Generate leads/lags
gen rate_date = year + (quarter-1)/4
replace rate_date = rate_date*4
tsset rate_date

gen d_rate = D.interest_rate

sort rate_date
forvalues i = 1/8 {
	gen L`i'_d_interest_rate = L`i'.d_rate
}

forvalues i = 2/8 {
	gen F`i'_d_interest_rate = F`i'.d_rate
}

forvalues i = 1/8 {
	gen L`i'_interest_rate = L`i'.interest_rate
}

forvalues i = 2/8 {
	gen F`i'_interest_rate = F`i'.interest_rate
}

drop d_rate rate_date

save "$WORKING/interest_rates.dta", replace
