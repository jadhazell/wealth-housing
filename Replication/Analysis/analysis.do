use "$WORKING/full_cleaned_data_diff.dta", clear


// First stage regression
// Dependent variable: log change in property price between date of purchase and date of sale
// Independent variables: 
	// duration ## change in interest rate
// Fixed effects: 3 digit postcode X quarter of purchase X quarter of sale

foreach var of varlist duration_at_sale_n duration_at_purchase_n {
	eststo clear
	quietly eststo: reghdfe d_log_price i.`var'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
	quietly eststo: reghdfe d_log_price i.`var'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)
	quietly eststo: reghdfe d_log_price i.`var'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n) cluster(date_trans L_date_trans location_n)
	quietly eststo: reghdfe d_log_price i.`var'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.price_ventile##i.type_n) cluster(date_trans L_date_trans location_n)
	quietly eststo: reghdfe d_log_price i.`var'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.`var') cluster(date_trans L_date_trans location_n)


	esttab using "$RESULTS/main_regression_`var'_full.tex", se title("Baseline Regression Results, `var'") keep(2.`var'#c.d_interest_rate 3.`var'#c.d_interest_rate) varlabels(2.`var'#c.d_interest_rate "\multirow{2}{4cm}{High Duration Leasehold x $\Delta$ Interest Rate}"  3.`var'#c.d_interest_rate "\multirow{2}{4cm}{Freehold x $\Delta$ Interest Rate}") replace

	esttab, se title("Baseline Regression Results, `var'") keep(2.`var'#c.d_interest_rate 3.`var'#c.d_interest_rate) varlabels(2.`var'#c.d_interest_rate "High Duration Leasehold x $\Delta$ Interest Rate"  3.`var'#c.d_interest_rate "Freehold x $\Delta$ Interest Rate") replace
}
