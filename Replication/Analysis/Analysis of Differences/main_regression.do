global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Main Regression"


local bucket_name bucket_3_sale

eststo clear 
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans) cluster(date_trans L_date_trans location_n)
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) cluster(date_trans L_date_trans location_n)
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.price_quintile##i.type_n) cluster(date_trans L_date_trans location_n)
quietly eststo: reghdfe d_log_price i.`bucket_name'##c.d_interest_rate, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n i.location_n##i.`bucket_name') cluster(date_trans L_date_trans location_n)


esttab using "$RESULTS/main_regression.tex", ///
	se title("Baseline Regression Results, `bucket_name'") ///
	keep(2.`bucket_name'#c.d_interest_rate ///
		 3.`bucket_name'#c.d_interest_rate) ///
	varlabels(2.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{High Duration Leasehold x $\Delta$ Interest Rate}" ///
			  3.`bucket_name'#c.d_interest_rate "\multirow{2}{4cm}{Freehold x $\Delta$ Interest Rate}") ///
	gaps replace

