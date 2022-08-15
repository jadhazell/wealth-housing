


*** Main specifications
eststo clear
** Only location controls
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3, absorb(i.Date##i.L_Date##i.location_factor years_held) cluster(Date L_Date location)
** Baseline: location controls + property type
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3, absorb(i.Date##i.L_Date##i.location_factor##i.Property_Type_factor) cluster(Date L_Date location)
** Location controls + property type + price quintiles
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3, absorb(i.Date##i.L_Date##i.location_factor##i.Property_Type_factor##i.price_quint) cluster(Date L_Date location)
** Location controls + property type + price ventiles
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3, absorb(i.Date##i.L_Date##i.location_factor##i.Property_Type_factor##i.price_vent) cluster(Date L_Date location)
** Let duration premium vary by area
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3, absorb(i.Date##i.L_Date##i.location_factor##i.Property_Type_factor i.location_factor##i.bucket_3) cluster(Date L_Date location)
** Table
esttab, style(tex) keep(2.bucket_3#c.d_rate 3.bucket_3#c.d_rate) stats(N r2_within, fmt(%9.0fc %9.4fc) labels("N (excl. singletons)" "Partial R2")) cells(b(fmt(%9.2f)) se(par fmt(%9.2f))) nolabel replace mlabels(none) collabels(none) varlabels(2.bucket_3#c.d_rate "High Duration Leasehold x $\Delta$ Interest Rate"  3.bucket_3#c.d_rate "Freehold x $\Delta$ Interest Rate")
estout using "Output/reg_main_purchase_restricted.tex", style(tex) keep(2.bucket_3#c.d_rate 3.bucket_3#c.d_rate) stats(N r2_within, fmt(%9.0fc %9.4fc) labels("N (excl. singletons)" "Partial R2")) cells(b(fmt(%9.2f)) se(par fmt(%9.2f))) nolabel replace mlabels(none) collabels(none) varlabels(2.bucket_3#c.d_rate "\multirow{2}{4cm}{High Duration Leasehold x $\Delta$ Interest Rate}"  3.bucket_3#c.d_rate "\multirow{2}{4cm}{Freehold x $\Delta$ Interest Rate}")

*** Main specifications using median at sale time
eststo clear
** Only location controls
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3_sale, absorb(i.Date##i.L_Date##i.location_factor) cluster(Date L_Date location)
** Baseline: location controls + property type
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3_sale, absorb(i.Date##i.L_Date##i.location_factor##i.Property_Type_factor) cluster(Date L_Date location)
** Location controls + property type + price quintiles
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3_sale, absorb(i.Date##i.L_Date##i.location_factor##i.Property_Type_factor##i.price_quint) cluster(Date L_Date location)
** Location controls + property type + price ventiles
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3_sale, absorb(i.Date##i.L_Date##i.location_factor##i.Property_Type_factor##i.price_vent) cluster(Date L_Date location)
** Let duration premium vary by area
quietly eststo: reghdfe d_log_price c.d_rate##i.bucket_3_sale, absorb(i.Date##i.L_Date##i.location_factor##i.Property_Type_factor i.location_factor##i.bucket_3_sale) cluster(Date L_Date location)
** Table
esttab, style(tex) keep(2.bucket_3_sale#c.d_rate 3.bucket_3_sale#c.d_rate) stats(N r2_within, fmt(%9.0fc %9.4fc) labels("N (excl. singletons)" "Partial R2")) cells(b(fmt(%9.2f)) se(par fmt(%9.2f))) nolabel replace mlabels(none) collabels(none) varlabels(2.bucket_3_sale#c.d_rate "High Duration Leasehold x $\Delta$ Interest Rate"  3.bucket_3_sale#c.d_rate "Freehold x $\Delta$ Interest Rate")
estout using "Output/reg_main_sale_restricted.tex", style(tex) keep(2.bucket_3_sale#c.d_rate 3.bucket_3_sale#c.d_rate) stats(N r2_within, fmt(%9.0fc %9.4fc) labels("N (excl. singletons)" "Partial R2")) cells(b(fmt(%9.2f)) se(par fmt(%9.2f))) nolabel replace mlabels(none) collabels(none) varlabels(2.bucket_3_sale#c.d_rate "\multirow{2}{4cm}{High Duration Leasehold x $\Delta$ Interest Rate}"  3.bucket_3_sale#c.d_rate "\multirow{2}{4cm}{Freehold x $\Delta$ Interest Rate}")
