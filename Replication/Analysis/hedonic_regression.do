

use "$INPUT/full_cleaned_data_with_lags_hedonic.dta", clear

drop if missing(L_date_trans)

replace lease_duration_at_trans = lease_duration_at_trans/1000
replace lease_duration_at_trans = 0 if freehold

* Run main regression but incorporate hedonic characteristics

gen obs_to_use = 1
gen freehold = !leasehold

gegen district_n = group(district)
gegen city_n = group(city)

gen L_year = int(L_date_trans)

fasterxtile L_price_quint_group = L_price, nq(5)  by(L_date_trans district_n)
fasterxtile L_price_dec_group   = L_price, nq(10) by(L_date_trans district_n)

global restriction ""

forvalues i = 1/3 {
	
	* Run first on all data, then only flats, then only non flats
	if `i' == 2 {
		replace obs_to_use = 1 if type == "F"
		replace obs_to_use = 0 if type != "F"
		global restriction "only_flats_"
	}
	if `i' == 3 {
		replace obs_to_use = 1 if type != "F"
		replace obs_to_use = 0 if type == "F"
		global restriction "only_nonflats_"
	}
	
	global controls "i.total_floor_area_50tiles i.number_habitable_rooms_n i.mainheat_description_n i.construction_age_band_n"
	local fe "i.district_n##i.year##i.L_year"

	local count = 1
	eststo clear
	
	* Run baseline
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold) if obs_to_use, absorb(`fe') cluster($cluster)
	local fe_vars "L_year year district"
	foreach var of local fe_vars {
		if strpos("`fe'", "`var'") {
			estadd local `var'_fe "\checkmark", replace
		}
	}
	
	foreach control of global controls  {
		eststo: reghdfe $dep_var ///
						c.$indep_var##(c.lease_duration_at_trans i.freehold `control') ///
						if obs_to_use, absorb(`fe') cluster($cluster)
		
		local fe_vars "L_year year district"
		foreach var of local fe_vars {
			if strpos("`fe'", "`var'") {
				estadd local `var'_fe "\checkmark", replace
			}
		}
		
		local count = `count'+1
	}
	
	* Run with all controls
	eststo: reghdfe $dep_var c.$indep_var##(c.lease_duration_at_trans i.freehold $controls) if obs_to_use, absorb(`fe') cluster($cluster)
	local fe_vars "L_year year district"
	foreach var of local fe_vars {
		if strpos("`fe'", "`var'") {
			estadd local `var'_fe "\checkmark", replace
		}
	}

	esttab using "$TABLES/hedonic_regression_$restriction$tag.tex", ///
		se title("Hedonic Regression \label{tab: hedonic regression $restriction $tag}") ///
		keep(c.$indep_var#c.lease_duration_at_trans ///
			 1.freehold#c.$indep_var) ///
		varlabels(c.$indep_var#c.lease_duration_at_trans "\multirow{2}{3cm}{Lease Duration x $indep_var_label}" ///
				  1.freehold#c.$indep_var "\multirow{2}{3cm}{Freehold x $indep_var_label}") ///
		mlabels("None" "Floor Area" "Number Rooms" "Heating Type" "Age" "All") gaps replace substitute(\_ _) ///
		s(L_year_fe year_fe district_fe  N, ///
			label("Purchase Year" ///
				  "$\times$ Sale Year" ///
				  "$\times$ District" ///
				  ))
}
