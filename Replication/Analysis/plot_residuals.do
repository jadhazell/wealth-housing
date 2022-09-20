global tag `1'

global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/UK Duration"
global TABLES "$RESULTS/Tables/Plot Residuals"
global FIGURES "$RESULTS/Figures/Plot Residuals"

* Plot residuals for continuous regression

gen interacted_term = lease_duration_at_trans * $indep_var

reghdfe interacted_term $indep_var lease_duration_at_trans, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) residuals(residuals_stage1)
reghdfe $dep_var $indep_var lease_duration_at_trans, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) residuals(residuals_stage2)

binscatter2 residuals_stage2 residuals_stage1 if abs(residuals_stage2)>0.001 & abs(residuals_stage1)>0.001, nquantiles(50) xtitle("Lease Duration x Δ Rate, Residualized") ytitle("Δ Log(Price), Residualized")
graph export "$FIGURES/continuous_regression_residual_plot.png", replace


* Include freeholds

cap drop interacted_term residual*

replace lease_duration_at_trans = 1000 if !leasehold

gen interacted_term = lease_duration_at_trans * $indep_var

reghdfe interacted_term $indep_var lease_duration_at_trans, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) residuals(residuals_stage1)
reghdfe $dep_var $indep_var lease_duration_at_trans, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) residuals(residuals_stage2)

binscatter2 residuals_stage2 residuals_stage1 if abs(residuals_stage2)>0.001 & abs(residuals_stage1)>0.001, nquantiles(50) xtitle("Lease Duration x Δ Rate, Residualized") ytitle("Δ Log(Price), Residualized")
graph export "$FIGURES/continuous_regression_with_freeholds_residual_plot.png", replace
