import delimited "$WORKING/matched_hedonic_characteristics.csv", clear varnames(1)
duplicates drop
duplicates tag merge_key, gen(dup)
gen first_word_mk = upper(word(merge_key, 1))
gen first_word_pid = word(property_id, 1)
gen first_word_matches = first_word_mk == first_word_pid
drop if dup>0 & !first_word_matches

drop dup
duplicates tag merge_key, gen(dup)
gen second_word_mk = upper(word(merge_key, 2))
gen second_word_pid = word(property_id, 2)
gen second_word_matches = second_word_mk == second_word_pid
drop if dup>0 & !second_word_matches

drop dup 
duplicates tag property_id, gen(dup)
drop if dup>0 & !first_word_matches


gen merge_key_upper = upper(merge_key)
duplicates drop merge_key_upper property_id, force

// For now drop remaining duplicates
duplicates tag property_id, gen(dup_pid)
duplicates tag merge_key, gen(dup_mk)

drop if dup_mk > 0
drop if dup_pid > 0

keep property_id merge_key
save "$WORKING/matched_hedonic_characteristic_keys.dta", replace

import delimited "$WORKING/combined_characteristic_files.csv", clear varnames(1)
gen merge_key = description
replace merge_key = subinstr(merge_key,".","",.)
replace merge_key = subinstr(merge_key,",","",.)
replace merge_key = subinstr(merge_key,"'","",.)
joinby merge_key using "$WORKING/matched_hedonic_characteristic_keys.dta"

// Clean date
gen date_inspect = date(inspection_date, "YMD")
replace date_inspect = year(date_inspect) + (quarter(date_inspect)-1)/4
format date_inspect %9.0g

save "$WORKING/matched_hedonic_characteristics.dta", replace

duplicates drop merge_key property_id inspection_date, force
duplicates drop property_id inspection_date, force

// Keep only instance for which date is closest to transaction date
joinby property_id using "$WORKING/full_price_data.dta"
gen time_from_inspection = abs(date_trans - date_inspect)
by property_id date_trans, sort: egen shortest_diff = min(time_from_inspection)
keep if time_from_inspection == shortest_diff

// When there are two inspection dates equally close to the transaction date, pick the one that most closely precedes the transaction
by property_id date_trans, sort: egen earliest_date = min(date_inspect)
keep if date_inspect == earliest_date

duplicates drop property_id date_trans, force

drop dup* time_from_inspection shortest_diff earliest_date


// Clean data
gen total_floor_area_n = real(total_floor_area)
xtile total_floor_area_50tiles = total_floor_area_n, nq(50)

gen number_habitable_rooms_n = real(number_habitable_rooms)
replace number_habitable_rooms_n = 9 if number_habitable_rooms_n>=9

egen hot_water_energy_eff_n = group(hot_water_energy_eff)


replace mainheat_description = lower(mainheat_description)
replace mainheat_description = "boiler" if strpos(mainheat_description, "boiler") == 1
replace mainheat_description = "electric" if strpos(mainheat_description, "electric") == 1
replace mainheat_description = "no system" if strpos(mainheat_description, "no system") == 1
replace mainheat_description = "room heaters" if strpos(mainheat_description, "room heaters") == 1
replace mainheat_description = "other" if mainheat_description != "boiler" &  mainheat_description != "electric" &  mainheat_description != "no system" & mainheat_description != "room heaters"
egen mainheat_description_n = group(mainheat_description)

replace construction_age_band = "" if construction_age_band == "nan" | construction_age_band == "NO DATA!" || construction_age_band == "INVALID!"
replace construction_age_band = "England and Wales: 2007-2011" if construction_age_band == "England and Wales: 2007 onwards"
replace construction_age_band = "England and Wales: 2012-2022" if construction_age_band == "England and Wales: 2012 onwards" | strpos(construction_age_band, "20") == 1
egen construction_age_band_n = group(construction_age_band)

replace tenure = lower(tenure)
replace tenure = "" if tenure == "NO DATA!" | tenure == "nan" | tenure == "unknown" | tenure == "Not defined - use in the case of a new dwelling for which the intended tenure in not known. It is no"
replace tenure = "rental" if strpos(tenure, "rent") == 1


save "$WORKING/matched_hedonic_characteristics_by_year.dta", replace
