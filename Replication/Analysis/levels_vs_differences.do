global INPUT "/Users/vbp/Dropbox (Princeton)/wealth-housing/Code/Replication_VBP/Cleaning/Output"
global RESULTS "/Users/vbp/Dropbox (Princeton)/Apps/Overleaf/Levels vs Differences"
global TABLES "$RESULTS/Tables"
global FIGURES "$RESULTS/Figures"

// global fe "i.location_n##i.date_trans##i.type_n"

global fe "i.location_n##i.date_trans##i.type_n i.property_id_n"
global cluster "date_trans location_n"
global tag "pidfe"


// Run main specification on restricted sample + include fixed effects

eststo clear
eststo: reghdfe log_price i.bucket_3##c.interest_rate , absorb($fe) cluster($cluster)

eststo: reghdfe log_price i.bucket_3##c.interest_rate if !missing(L_date_trans), absorb($fe) cluster($cluster)

eststo: reghdfe log_price i.bucket_3##c.interest_rate , absorb($fe i.property_id_n) cluster($cluster)

esttab using "$TABLES/main_regression_with_different_restrictions_$tag.tex", ///
	se title("Main Regression Results on Levels (Variations)  \label{tab: main variations levels }") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("Baseline" "Restricted Sample" "Property FE" ) ///
	gaps replace substitute(\_ _)
	
	
// Compare residual plots

gen interacted_term_level_2 = interest_rate * (bucket_3==2)
gen interacted_term_level_3 = interest_rate * (bucket_3==3)
gen interacted_term_difference_2 = d_interest_rate * (bucket_3_restricted==2)
gen interacted_term_difference_3 = d_interest_rate * (bucket_3_restricted==3)

// 1st stage

// Differences - Long leaseholds:
reghdfe interacted_term_difference_2 interacted_term_difference_3 d_interest_rate i.bucket_3_restricted, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) residuals(differences_2_res_stage1)
predict differences_2_fitted_stage1, xb
predict differences_2_fitted_stage1_d, xbd
 
// Differences - Freeholds:
reghdfe interacted_term_difference_3 interacted_term_difference_2 d_interest_rate i.bucket_3_restricted, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) residuals(differences_3_res_stage1)
predict differences_3_fitted_stage1, xb
predict differences_3_fitted_stage1_d, xbd

// Levels - Long leaseholds:
reghdfe interacted_term_level_2 interacted_term_level_3 interest_rate i.bucket_3, absorb($fe) cluster($cluster) residuals(levels_2_res_stage1)
predict levels_2_fitted_stage1, xb
predict levels_2_fitted_stage1_d, xbd
 
// Levels - Freeholds:
reghdfe interacted_term_level_3 interacted_term_level_2 interest_rate i.bucket_3, absorb($fe) cluster($cluster) residuals(levels_3_res_stage1)
predict levels_3_fitted_stage1, xb
predict levels_3_fitted_stage1_d, xbd

// Levels - Long leaseholds - Restricted:
reghdfe interacted_term_level_2 interacted_term_level_3 interest_rate i.bucket_3 if !missing(L_date_trans), absorb($fe) cluster($cluster) residuals(levels_2_res_stage1_restricted)
predict restricted_2_fitted_stage1, xb
predict restricted_2_fitted_stage1_d, xbd
 
// Levels - Freeholds - Restricted:
reghdfe interacted_term_level_3 interacted_term_level_2 interest_rate i.bucket_3 if !missing(L_date_trans), absorb($fe) cluster($cluster) residuals(levels_3_res_stage1_restricted)
predict restricted_3_fitted_stage1, xb
predict restricted_3_fitted_stage1_d, xbd

// 2nd stage

// Differences - Long leaseholds:
reghdfe d_log_price interacted_term_difference_3 d_interest_rate i.bucket_3_restricted, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) residuals(differences_2_res_stage2)

// Differences - Freeholds:
reghdfe d_log_price interacted_term_difference_2 d_interest_rate i.bucket_3_restricted, absorb(i.location_n##i.date_trans##i.L_date_trans##i.type_n) residuals(differences_3_res_stage2)

// Levels - Long leaseholds
reghdfe log_price interacted_term_level_3 interest_rate i.bucket_3, absorb($fe) cluster($cluster) residuals(levels_2_res_stage2)
 
// Levels - Freeholds:
reghdfe log_price interacted_term_level_2 interest_rate i.bucket_3, absorb($fe) cluster($cluster) residuals(levels_3_res_stage2)

// Levels - Long leaseholds - Restricted:
reghdfe log_price interacted_term_level_3 interest_rate i.bucket_3  if !missing(L_date_trans), absorb($fe) cluster($cluster) residuals(levels_2_res_stage2_restricted)
 
// Levels - Freeholds - Restricted:
reghdfe log_price interacted_term_level_2 interest_rate i.bucket_3  if !missing(L_date_trans), absorb($fe) cluster($cluster) residuals(levels_3_res_stage2_restricted)



// Binscatter

// Differences - Long Leasehold
binscatter2 differences_2_res_stage2 differences_2_res_stage1 if abs(differences_2_res_stage2)>0.001 & abs(differences_2_res_stage1)>0.001, nquantiles(50) xtitle("Long Leasehold x Δ Rate, Residualized") ytitle("Δ Log(Price), Residualized") xscale(range(-1.5(0.5)1.5)) yscale(range(-2(0.5)2)) xlabel(-1.5(0.5)1.5) ylabel(-2(0.5)2)
graph export "$FIGURES/binscatter_differences_longlease_dlogpriceres_$tag.png", replace
binscatter2 d_log_price differences_2_res_stage1 if abs(differences_2_res_stage1)>0.001, nquantiles(50) xtitle("Long Leasehold x Δ Rate, Residualized") ytitle("Δ Log(Price)") xscale(range(-1.5(0.5)1.5)) xlabel(-1.5(0.5)1.5)
graph export "$FIGURES/binscatter_differences_longlease_dlogprice_$tag.png", replace


// Differences - Freehold
binscatter2 differences_3_res_stage2 differences_3_res_stage1 if abs(differences_3_res_stage2)>0.001 & abs(differences_3_res_stage1)>0.001, nquantiles(50) xtitle("Freehold x Δ Rate, Residualized") ytitle("Δ Log(Price), Residualized") xscale(range(-1.5(0.5)1.5)) yscale(range(-2(0.5)2)) xlabel(-1.5(0.5)1.5) ylabel(-2(0.5)2)
graph export "$FIGURES/binscatter_differences_freehold_dlogpriceres_$tag.png", replace
// Zoom in 
binscatter2 differences_3_res_stage2 differences_3_res_stage1 if abs(differences_3_res_stage1)<0.5, nquantiles(50) xtitle("Freehold x Δ Rate, Residualized") ytitle("Δ Log(Price), Residualized")
graph export "$FIGURES/binscatter_differences_freehold_dlogpriceres_zoom_$tag.png", replace
// Non residualized y axis
binscatter2 d_log_price differences_3_res_stage1 if abs(differences_3_res_stage1)>0.001, nquantiles(50) xtitle("Freehold x Δ Rate, Residualized") ytitle("Δ Log(Price)") xscale(range(-1.5(0.5)1.5)) xlabel(-1.5(0.5)1.5)
graph export "$FIGURES/binscatter_differences_freehold_dlogprice_$tag.png", replace


// Level - Long Leasehold
binscatter2 levels_2_res_stage2 levels_2_res_stage1 if abs(levels_2_res_stage2)>0.001 & abs(levels_2_res_stage1)>0.001, nquantiles(50) xtitle("Long Leasehold x Rate, Residualized") ytitle("Log(Price), Residualized") yscale(range(-0.05(0.01)0.05)) ylabel(-0.05(0.01)0.05) xscale(range(-1.5(0.5)1.5)) xlabel(-1.5(0.5)1.5)
graph export "$FIGURES/binscatter_levels_longlease_logpriceres_$tag.png", replace
// Zoom in 
binscatter2 levels_2_res_stage2 levels_2_res_stage1 if abs(levels_2_res_stage2)<0.03, nquantiles(50) xtitle("Long Leasehold x Rate, Residualized") ytitle("Log(Price), Residualized") 
graph export "$FIGURES/binscatter_levels_longlease_logpriceres_zoom_$tag.png", replace
// Non residualized y axis
binscatter2 log_price levels_2_res_stage1 if abs(levels_2_res_stage1)>0.001, nquantiles(50) xtitle("Long Leasehold x Rate, Residualized") ytitle("Log(Price)") xscale(range(-1.5(0.5)1.5)) xlabel(-1.5(0.5)1.5)
graph export "$FIGURES/binscatter_levels_longlease_logprice_$tag.png", replace


// Level - Freehold
binscatter2 levels_3_res_stage2 levels_3_res_stage1 if abs(levels_3_res_stage2)>0.001 & abs(levels_3_res_stage1)>0.001, nquantiles(50) xtitle("Freehold x Rate, Residualized") ytitle("Log(Price), Residualized") xscale(range(-1(0.5)1)) xlabel(-1(0.25)1)
graph export "$FIGURES/binscatter_levels_freehold_logpriceres_$tag.png", replace
// Zoom in 
binscatter2 levels_3_res_stage2 levels_3_res_stage1 if abs(levels_3_res_stage2)<0.05, nquantiles(50) xtitle("Freehold x Rate, Residualized") ytitle("Log(Price), Residualized") xscale(range(-1(0.5)1)) xlabel(-1(0.25)1)
graph export "$FIGURES/binscatter_levels_freehold_logpriceres_zoom_$tag.png", replace
// Non residualized y axis
binscatter2 log_price levels_3_res_stage1 if abs(levels_2_res_stage1)>0.001, nquantiles(50) xtitle("Long Leasehold x Rate, Residualized") ytitle("Log(Price)") xscale(range(-1.5(0.5)1.5)) xlabel(-1.5(0.5)1.5)
graph export "$FIGURES/binscatter_levels_freehold_logprice_$tag.png", replace


// Level - Long Leasehold - Restricted
binscatter2 levels_2_res_stage2_restricted levels_2_res_stage1_restricted if abs(levels_2_res_stage2_restricted)>0.001 & abs(levels_2_res_stage1_restricted)>0.001, nquantiles(50) xtitle("Long Leasehold x Rate, Residualized") ytitle("Log(Price), Residualized") yscale(range(-0.05(0.01)0.05)) ylabel(-0.05(0.01)0.05) xscale(range(-1.5(0.5)1.5)) xlabel(-1.5(0.5)1.5)
graph export "$FIGURES/binscatter_levels_longlease_logpriceres_restricted_$tag.png", replace
// Zoom in 
binscatter2 levels_2_res_stage2_restricted levels_2_res_stage1_restricted if abs(levels_2_res_stage2_restricted)>0.001 & abs(levels_2_res_stage2_restricted)<0.05, nquantiles(50) xtitle("Freehold x Rate, Residualized") ytitle("Log(Price), Residualized") xscale(range(-1(0.5)1)) xlabel(-1(0.25)1)
graph export "$FIGURES/binscatter_levels_longlease_logpriceres_restricted_zoom_$tag.png", replace
// Non residualized y axis
binscatter2 log_price levels_2_res_stage1_restricted if abs(levels_2_res_stage1_restricted)>0.001, nquantiles(50) xtitle("Long Leasehold x Rate, Residualized") ytitle("Log(Price)") xscale(range(-1.5(0.5)1.5)) xlabel(-1.5(0.5)1.5)
graph export "$FIGURES/binscatter_levels_longlease_logprice_restricted_$tag.png", replace


// Level - Freehold - Restricted
binscatter2 levels_3_res_stage2_restricted levels_3_res_stage1_restricted if abs(levels_3_res_stage2_restricted)>0.001 & abs(levels_3_res_stage1_restricted)>0.001, nquantiles(50) xtitle("Freehold x Rate, Residualized") ytitle("Log(Price), Residualized") xscale(range(-1(0.5)1)) xlabel(-1(0.25)1)
graph export "$FIGURES/binscatter_levels_freehold_logpriceres_restricted_$tag.png", replace
// Zoom in 
binscatter2 levels_3_res_stage2_restricted levels_3_res_stage1_restricted if abs(levels_3_res_stage2_restricted)>0.001 & abs(levels_3_res_stage2_restricted)<0.05, nquantiles(50) xtitle("Freehold x Rate, Residualized") ytitle("Log(Price), Residualized") xscale(range(-1(0.5)1)) xlabel(-1(0.25)1)
graph export "$FIGURES/binscatter_levels_freehold_logpriceres_restricted_zoom_$tag.png", replace
// Non residualized y axis
binscatter2 log_price levels_3_res_stage1_restricted if abs(levels_2_res_stage1_restricted)>0.001, nquantiles(50) xtitle("Long Leasehold x Rate, Residualized") ytitle("Log(Price)") xscale(range(-1.5(0.5)1.5)) xlabel(-1.5(0.5)1.5)
graph export "$FIGURES/binscatter_levels_freehold_logprice_restricted_$tag.png", replace


//////////////////////////////////////////////////////////////////////////////////////
// Compare fitted values and residuals for logs and levels equation
//////////////////////////////////////////////////////////////////////////////////////

reghdfe log_price levels_2_res_stage1, noabsorb cluster(date_trans location_n) residuals(levels_2_res)
predict levels_2_fitted, xb
predict levels_2_fitted_d, xbd

reghdfe log_price levels_3_res_stage1, noabsorb cluster(date_trans location_n) residuals(levels_3_res)
predict levels_3_fitted, xb
predict levels_3_fitted_d, xbd

reghdfe d_log_price differences_2_res_stage1, noabsorb cluster(date_trans L_date_trans location_n) residuals(differences_2_res)
predict differences_2_fitted, xb
predict differences_2_fitted_d, xbd

reghdfe d_log_price differences_3_res_stage1, noabsorb cluster(date_trans L_date_trans location_n) residuals(differences_3_res)
predict differences_3_fitted, xb
predict differences_3_fitted_d, xbd

binscatter2 levels_2_fitted differences_2_fitted, nquantiles(50) 
graph export "$FIGURES/levels_vs_differences_longleasehold_fitted.png", replace

binscatter2 levels_3_fitted differences_3_fitted, nquantiles(50) 
graph export "$FIGURES/levels_vs_differences_freehold_fitted.png", replace

// Normalize fitted values
egen mean_levels_2 = mean(levels_2_fitted)
egen mean_levels_3 = mean(levels_3_fitted)

egen mean_differences_2 = mean(differences_2_fitted)
egen mean_differences_3 = mean(differences_3_fitted)

gen norm_levels_2 = levels_2_fitted/mean_levels_2
gen norm_levels_3 = levels_2_fitted/mean_levels_3
gen norm_differences_2 = differences_2_fitted/mean_differences_2
gen norm_differences_3 = differences_3_fitted/mean_differences_3

gen diff_2 = norm_differences_2 - norm_levels_2
gen diff_3 = norm_differences_3 - norm_levels_3


gen fitted_diff_2 = differences_2_fitted - levels_3_fitted
binscatter2 log_price fitted_diff_2, nquantiles(50) 
graph export "$FIGURES/log_price_by_fit_difference_2.png", replace

gen fitted_diff_3 = differences_3_fitted - levels_3_fitted
binscatter2 log_price fitted_diff_3, nquantiles(50) 
graph export "$FIGURES/log_price_by_fit_difference_3.png", replace



//////////////////////////////////////////////////////////////////////////////////////
// Rerun analysis for each price quartile 
//////////////////////////////////////////////////////////////////////////////////////

xtile price_quartiles = price, nq(4)
xtile price_quartiles_restricted = price if !missing(L_date_trans), nq(4)

// Differences
// global dep_var d_log_price
// global indep_var d_interest_rate 
// global bucket_name bucket_3_restricted 
// global price_bucket price_quartiles_restricted
// global fe "i.location_n##i.date_trans##i.L_date_trans##i.type_n"
// global cluster "location_n date_trans L_date_trans"
// global title "Regression Results by Price Quartile, Differences"
// global indep_var_label "$\Delta$ Interest Rate"
// global tag "differences"

// // Levels
global dep_var log_price
global indep_var interest_rate 
global bucket_name bucket_3
global price_bucket price_quartiles
global fe "$fe"
global cluster "location_n date_trans"
global title "Regression Results by Price Quartile, Levels"
global indep_var_label "Interest Rate"
global tag "levels"
// // Restricted
global bucket_name bucket_3_restricted
global title "Regression Results by Price Quartile, Levels (Restricted to Differences Sample)"
global tag "levels_restricted"

eststo clear
forvalues i = 1/4 {
	eststo: reghdfe $dep_var i.$bucket_name##c.$indep_var if $price_bucket == `i' & !missing($bucket_name), absorb($fe) cluster($cluster)
}
esttab using "$TABLES/main_regression_by_price_quartiles_$tag.tex", ///
	se title("$title \label{tab: main by price quartiles $tag}") ///
	keep(2.$bucket_name#c.$indep_var ///
		 3.$bucket_name#c.$indep_var) ///
	varlabels(2.$bucket_name#c.$indep_var "\multirow{2}{4cm}{High Duration Leasehold x $indep_var_label}" ///
			  3.$bucket_name#c.$indep_var "\multirow{2}{4cm}{Freehold x $indep_var_label}") ///
	mlabels("First Quartile" "Second Quartile" "Third Quartile" "Fourth Quartile") gaps replace substitute(\_ _)


