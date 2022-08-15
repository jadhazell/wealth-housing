// Monetary rates
import delimited "$INTEREST_RATES/CTV_MonPolTransmission.csv", clear
rename v1 date
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

save "$WORKING/interest_rates.dta", replace
