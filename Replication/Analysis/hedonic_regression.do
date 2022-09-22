

use "$INPUT/full_cleaned_data_with_lags_hedonics.dta", clear

* Run main regression but incorporate hedonic characteristics

gen obs_to_use = 1

global restriction ""

forvalues i = 1/3 {
	
	* Run first on all data, then only flats, then only non flats
	if `i' == 2 {
		replace obs_to_use = 1 if type == "F"
		replace obs_to_use = 0 if type != "F"
		global restriction "_only_flats"
	}
	if `i' == 2 {
		replace obs_to_use = 1 if type != "F"
		replace obs_to_use = 0 if type == "F"
		global restriction "_only_nonflats"
	}

	local count = 1
	eststo clear
	foreach fe of global fes  {
		eststo: reghdfe $dep_var ///
						c.$indep_var##(c.lease_duration_at_trans ///
									   i.freehold ///
									   i.total_floor_area_50tiles ///
									   i.number_habitable_rooms_n ///
									   i.mainheat_description_n ///
									   i.construction_age_band_n) ///
						if obs_to_use, absorb(`fe') cluster($cluster)
		
		local fe_vars "L_year year district city location postcode type price_quint price_dec"
		foreach var of local fe_vars {
			if strpost(`fe', "`var'") {
				estadd local `var'_fe "$\checkmark", replace
			}
		}
		
		local count = `count'+1
	}

	esttab using "$TABLES/hedonic_regression_$restriction$tag.tex", ///
		se title("Hedonic Regression \label{tab: hedonic regression $restriction $tag}") ///
		keep(c.lease_duration_at_trans#c.$indep_var ///
			 1.freehold#c.$indep_var) ///
		varlabels(c.lease_duration_at_trans#c.$indep_var "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
				  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
		mlabels("$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label" "$dep_var_label") gaps replace substitute(\_ _) ///
		s(L_year_fe year_fe district_fe city_fe location_fe postcode_fe type_fe price_quint_fe price_dec_fe N, ///
			label("Purchase Year" ///
				  "$\times$ Sale Year" ///
				  "$\times$ District" ///
				  "$\times$ City" ///
				  "$\times$ Location" ///
				  "$\times$ Postcode" ///
				  "$\times$ Type" ///
				  "$\times$ Price Quintile" ///
				  "$\times$ Price Decile" ///
				  ))
}
