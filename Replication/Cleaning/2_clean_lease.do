global DATA "`1'"
global WORKING "`2'"

di "Data folder: $DATA"
di "Working folder: $WORKING"

// import delimited "$DATA/LEASES_FULL_2022_06.csv", clear
// rename uniqueidentifier unique_id 
// rename dateoflease date
// rename term lease_details
// rename associatedpropertydescription description
// keep unique_id date lease_details description
//
// // Clean date
//
// replace date = substr(date,4,7)
// gen date_registered = date(date,"MY")
// gen  year = year(date_registered)
// gen quarter = quarter(date_registered)
// gen date_registered2 = year + (quarter-1)/4
// drop date_registered date
// rename date_registered2 date_registered
//
// ////////////////////////////////////////////
// // Clean lease term based on GMS code
// ////////////////////////////////////////////
//
// * Lease details hold information on lease length, generally a textual description.
// drop if lease_details == "No information available"
// drop if lease_details == ""
// drop if lease_details == "-"
//
// compress
//
// ********************************************************************
// * TYPOS - The textual description of in the "Lease Details" field
// *         contains a number of typos, that are dealt with here
// ********************************************************************
//
// gen jan = regexs(0) if (regexm(lease_details,"Jan[a-z][a-z][a-z]y"))
// replace lease_details = subinstr(lease_details,jan,"January",.)
// drop jan
//
// gen jan = regexs(0) if (regexm(lease_details,"Jan[a-z][a-z][a-z][a-z]y"))
// replace lease_details = subinstr(lease_details,jan,"January",.)
// drop jan
//
// gen sept = regexs(0) if (regexm(lease_details,"Sep[a-z][a-z][a-z][a-z][a-z][a-z]"))
// replace lease_details = subinstr(lease_details,sept,"September",.)
// drop sept
//
// gen oct = regexs(0) if (regexm(lease_details,"Oct[a-z][a-z][a-z][a-z]"))
// replace lease_details = subinstr(lease_details,oct,"October",.)
// drop oct
//
// gen year_w = regexs(0) if (regexm(lease_details,"y[a-z][a-z][a-z]s"))
// replace lease_details = subinstr(lease_details,year_w,"years",.)
// drop year_w
//
// gen year_w = regexs(0) if (regexm(lease_details,"Y[a-z][a-z][a-z]s"))
// replace lease_details = subinstr(lease_details,year_w,"years",.)
// drop year_w
//
// ********************************************************************************************
// * More typos we discovered through manually inspecting files 
// ********************************************************************************************
//
// replace lease_details = subinstr(lease_details,"Janaury","January",.)
// replace lease_details = subinstr(lease_details,"Janusary","January",.)
// replace lease_details = subinstr(lease_details,"Janauary","January",.)
// replace lease_details = subinstr(lease_details,"Janury","January",.)
// replace lease_details = subinstr(lease_details," anuary"," January",.)
//
// replace lease_details = subinstr(lease_details,"Febraury","February",.)
//
// replace lease_details = subinstr(lease_details,"Mrch","March",.)
// replace lease_details = subinstr(lease_details,"Mrach","March",.)
//
// replace lease_details = subinstr(lease_details,"Deptember","December",.)
// replace lease_details = subinstr(lease_details,"Decemer","December",.)
//
// replace lease_details = subinstr(lease_details,"Augsut","August",.)
//
// replace lease_details = subinstr(lease_details,"Sepember","September",.)
// replace lease_details = subinstr(lease_details,"Setpember","September",.)
// replace lease_details = subinstr(lease_details,"Septembeer","September",.)
// replace lease_details = subinstr(lease_details,"Setpembr","September",.)
//
// replace lease_details = subinstr(lease_details,"Ocober","October",.)
// replace lease_details = subinstr(lease_details,"Ocotber","October",.)
// replace lease_details = subinstr(lease_details," ctober"," October",.)
//
// * Fix spelling of "Year"
// replace lease_details = subinstr(lease_details,"yeas","years",.)
// replace lease_details = subinstr(lease_details,"YEARS","years",.)
// replace lease_details = subinstr(lease_details,"Years","years",.)
// replace lease_details = subinstr(lease_details,"yers","years",.)
// replace lease_details = subinstr(lease_details,"yeard","years",.)
// replace lease_details = subinstr(lease_details,"Yers","years",.)
// replace lease_details = subinstr(lease_details,"tears","years",.)
// replace lease_details = subinstr(lease_details,"eyars","years",.)
//
// * Fix spelling of other common words in lease details data field
// replace lease_details = subinstr(lease_details,"unitl","until",.)
// replace lease_details = subinstr(lease_details,"util","until",.)
//
// replace lease_details = subinstr(lease_details,"frm","from",.)
// replace lease_details = subinstr(lease_details,"fron","from",.)
// replace lease_details = subinstr(lease_details,"frorm","from",.)
// replace lease_details = subinstr(lease_details," rom "," from ",.)
//
// replace lease_details = subinstr(lease_details,"( hereof)","",.)
//
// replace lease_details = subinstr(lease_details,"commending","commencing",.)
//
// replace lease_details = subinstr(lease_details," fro "," for ",.)
//
// replace lease_details = subinstr(lease_details,"incuding","including",.)
// replace lease_details = subinstr(lease_details,"working","",.)
//
// foreach yyy in "99" "125" "250" "999" "189" "199" "200" "800" "155" "990" "120" "1000" "998" "900" "100" {
//     replace lease_details = subinstr(lease_details,"`yyy' year ","`yyy' years ",.)
// }
//
// replace lease_details = trim(lease_details)
// replace lease_details = itrim(lease_details)
//
// ***********************************************************
// * Fix missing "years", e.g., "125 from 12 December...."
// ***********************************************************
//
// * CASE 1
// gen h1 = regexs(0) if (regexm(lease_details,"^[1-9][0-9][0-9] "))
// gen h2 = regexs(0) if (regexm(lease_details,"^[1-9][0-9][0-9] y"))
//
// gen action = 1 if h1 != "" & h2 == ""
// gen new    = h1 + "years "
// replace lease_details = subinstr(lease_details,h1,new,.) if action == 1
//
// drop h1 h2 action new
//
// * CASE 2
// gen h1 = regexs(0) if (regexm(lease_details,"^[1-9][0-9][0-9][0-9] "))
// gen h2 = regexs(0) if (regexm(lease_details,"^[1-9][0-9][0-9][0-9] y"))
//
// gen action = 1 if h1 != "" & h2 == ""
// gen new    = h1 + "years "
// replace lease_details = subinstr(lease_details,h1,new,.) if action == 1
//
// drop h1 h2 action new
//
// * CASE 3
// gen h1 = regexs(0) if (regexm(lease_details,"^[1-9],[0-9][0-9][0-9] "))
// gen h2 = regexs(0) if (regexm(lease_details,"^[1-9],[0-9][0-9][0-9] y"))
//
// gen action = 1 if h1 != "" & h2 == ""
// gen new    = h1 + "years "
// replace lease_details = subinstr(lease_details,h1,new,.) if action == 1
//
// drop h1 h2 action new
//
// * CASE 4
// gen h1 = regexs(0) if (regexm(lease_details,"^[1-9][1-9] "))
// gen h2 = regexs(0) if (regexm(lease_details,"^[1-9][1-9] y"))
//
// gen action = 1 if h1 != "" & h2 == ""
// gen new    = h1 + "years "
// replace lease_details = subinstr(lease_details,h1,new,.) if action == 1
//
// drop h1 h2 action new
//
// **********************************************************************
// * Remove "Day" Transaction Details
// * - Some lease details state, for example, "999 years (less 2 days)"
// * - We want to focus on the important part of years.
// **********************************************************************
//
// foreach k in "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" ///
//              "two" "three" "four" "five" "six" "seven" "eight" "nine" "ten" "eleven" "twelve" "thirteen" ///
// 			 "fourteen" "fiveteen" "sixteen" "seventeen" "eighteen" "nineteen" "twenty" {
//			 
// 	replace lease_details= subinstr(lease_details,"(less `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"less `k' days","",.)
// 	replace lease_details= subinstr(lease_details,"(Less `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"Less `k' days","",.)
//	
// 	replace lease_details= subinstr(lease_details,"(less `k' months)","",.)
// 	replace lease_details= subinstr(lease_details,"less `k' months","",.)
// 	replace lease_details= subinstr(lease_details,"(Less `k' months)","",.)
// 	replace lease_details= subinstr(lease_details,"Less `k' months","",.)
//	
// 	replace lease_details= subinstr(lease_details,"(less last `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"less last `k' days","",.)
// 	replace lease_details= subinstr(lease_details,"(Less last `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"Less last `k' days","",.)
//	
// 	replace lease_details= subinstr(lease_details,"(minus last `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"minus last `k' days","",.)
// 	replace lease_details= subinstr(lease_details,"(minus last `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"minus last `k' days","",.)
//	
// 	replace lease_details= subinstr(lease_details,"(minus `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"minus `k' days","",.)
// 	replace lease_details= subinstr(lease_details,"(minus `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"minus `k' days","",.)
//	
// 	replace lease_details= subinstr(lease_details,"(less the last `k' days thereof)","",.)
// 	replace lease_details= subinstr(lease_details,"less the last`k' days thereof","",.)
// 	replace lease_details= subinstr(lease_details,"(Less the last`k' days thereof)","",.)
// 	replace lease_details= subinstr(lease_details,"Less the last `k' days thereof","",.)
//	
// 	replace lease_details= subinstr(lease_details,"(less last `k' days thereof)","",.)
// 	replace lease_details= subinstr(lease_details,"less last`k' days thereof","",.)
// 	replace lease_details= subinstr(lease_details,"(Less last`k' days thereof)","",.)
// 	replace lease_details= subinstr(lease_details,"Less last `k' days thereof","",.)
//	
// 	replace lease_details= subinstr(lease_details,"(less the last `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"less the last`k' days","",.)
// 	replace lease_details= subinstr(lease_details,"(Less the last`k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"Less the last `k' days","",.)	
//	
// 	replace lease_details= subinstr(lease_details,"(except the last `k' days thereof)","",.)
// 	replace lease_details= subinstr(lease_details,"except the last`k' days thereof","",.)
// 	replace lease_details= subinstr(lease_details,"(except the last`k' days thereof)","",.)
// 	replace lease_details= subinstr(lease_details,"except the last `k' days thereof","",.)
//	
// 	replace lease_details= subinstr(lease_details,"(except the last `k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"except the last`k' days","",.)
// 	replace lease_details= subinstr(lease_details,"(except the last`k' days)","",.)
// 	replace lease_details= subinstr(lease_details,"except the last `k' days","",.)	
// }
//
// replace lease_details = subinstr(lease_details,"(less 1 day)","",.)
// replace lease_details = subinstr(lease_details,"(less one day)","",.)
// replace lease_details = subinstr(lease_details,"(Less one day)","",.)
// replace lease_details = subinstr(lease_details,"less 1 day","",.)
// replace lease_details = subinstr(lease_details,"less one day","",.)
// replace lease_details = subinstr(lease_details,"less a day","",.)
// replace lease_details = subinstr(lease_details,"(except the last day)","",.)
// replace lease_details = subinstr(lease_details,"(except the last day thereof)","",.)
// replace lease_details = subinstr(lease_details,"(except last day)","",.)
// replace lease_details = subinstr(lease_details,"except last day","",.)
// replace lease_details = subinstr(lease_details,"determinable","",.)
//
// replace lease_details = subinstr(lease_details,"1st","1",.)
// replace lease_details = subinstr(lease_details,"2nd","2",.)
// replace lease_details = subinstr(lease_details,"3rd","3",.)
//
// replace lease_details = subinstr(lease_details,"as therein mentioned","",.)
// replace lease_details = subinstr(lease_details,"as therein entioned","",.)
// replace lease_details = subinstr(lease_details,"()","",.)
//
// replace lease_details = trim(lease_details)
// replace lease_details = itrim(lease_details)
//
// replace lease_details = subinstr(lease_details,"FROM:","from",.)
// replace lease_details = subinstr(lease_details,"From:","from",.)
// replace lease_details = subinstr(lease_details,"From","from",.)
//
// replace lease_details = subinstr(lease_details,"TO:","to",.)
// replace lease_details = subinstr(lease_details,"To:","to",.)
// replace lease_details = subinstr(lease_details,"To ","to ",.)
//
// **************************************************************************************
// * EXTRACT INFO
// * - Now we process the cleaned string to extract the actual lease length information
// * - This cycles through a number of approaches of how lease length is recorded
// **************************************************************************************
//
// * YEARS 
// gen year_pos     = strpos(lease_details,"years")
// gen number_years = substr(lease_details,1,year_pos-2)
//
// * "FROM" POSITION
// cap drop from from_pos
// gen     from_pos = strpos(lease_details,"from and including") if number_years != ""
// replace from_pos = strpos(lease_details,"from & including")   if number_years != "" & from_pos == .
// replace from_pos = strpos(lease_details,"commencing on")      if number_years != "" & from_pos == .
// replace from_pos = strpos(lease_details,"commencing in")      if number_years != "" & from_pos == .
// replace from_pos = strpos(lease_details,"from")               if number_years != "" & from_pos == .
//
// gen from            = substr(lease_details,from_pos + 19,.) if number_years != "" & from_pos != 0
// gen has_toincluding = strpos(from,"to and") 
// replace from        = substr(from,1,has_toincluding-2) if has_toincluding != 0
//
// cap drop from_pos
// gen from_pos = strpos(lease_details,"from") if number_years != ""
// replace from = substr(lease_details,from_pos + 5,.) if number_years != "" & from == ""
//
// replace from = subinstr(from,"years commencing on and including","",.)
// replace from = subinstr(from,"years commencing on","",.)
// replace from = subinstr(from,"years commencing","",.)
// replace from = subinstr(from,"commencement date of","",.)
//
// replace from = subinstr(from,"years From","",.)
// replace from = subinstr(from,"form","",.)
// replace from = subinstr(from,"years fron","",.)
// replace from = subinstr(from,"and including","",.)
// replace from = subinstr(from,"and includng","",.)
//
// replace from = trim(from)
// replace from = itrim(from)
//
// replace from = subinstr(from,"commencing on","",.)
// replace from = subinstr(from,"years","",.)
// replace from = subinstr(from,"commencing","",.)
// replace from = subinstr(from,"()","",.)
//
// replace from = trim(from)
// replace from = itrim(from)
//
// replace from = subinstr(from,"first day of","1",.)
// replace from = subinstr(from,"first day","1",.)
//
// replace from = subinstr(from,"second day of","2",.)
// replace from = subinstr(from,"second day","2",.)
//
// foreach part in "Beginning on and including" "beginning on and including" "Beginning on" "beginning on" "starting on" "starting of" "ears" "From" "FROM" "from" "fom" ///
//                 "term of" "including" "frin" "less" "day" "of" "subject" "(" ")" "on " "beginning" "thereof" "the " "staring on" "except" {				
// 	replace from = subinstr(from,"`part'","",.)
// }
//
// forval n = 4(1)31 {
// 	replace from = subinstr(from,"`n'th","`n'",.)
// }
//
// foreach ending in "until"  "to " "deter" "Deter" "and" "To " "expir" "up" "ending" "ETER" "last" {
// 	replace from = substr(from,1,strpos(from,"`ending'")-1) if strpos(from,"`ending'") != 0
// }
//
// *************************************************
// * Some more String Tricks
// *************************************************
//
// gen help1     = regexs(0) if (regexm(from,"for [0-9][0-9][0-9]"))
// replace from  = subinstr(from,help1,"",.)
// replace help1 = subinstr(help1,"for","",.)
// replace number_years = help1 if help1 != ""
// cap drop help1
//
// gen help2            = regexs(0) if (regexm(lease_details,"[0-9][0-9][0-9] from and including"))
// replace from         = substr(lease_details,length(help2)+1,.) if length(help2) > 1
// replace number_years = substr(lease_details,1,3) if length(help2) > 1
// cap drop help2
//
// gen help3            = regexs(0) if (regexm(lease_details,"[0-9][0-9][0-9] from"))
// replace from         = substr(lease_details,length(help3)+1,.) if length(help3) > 1
// replace number_years = substr(lease_details,1,3) if length(help3) > 1
// cap drop help3
//
// gen help3            = regexs(0) if (regexm(lease_details,"[0-9][0-9][0-9] commencing on"))
// replace from         = substr(lease_details,length(help3)+1,.) if length(help3) > 1
// replace number_years = substr(lease_details,1,3) if length(help3) > 1
// cap drop help3
//
// gen help3            = regexs(0) if (regexm(lease_details,"[0-9][0-9][0-9] commencing"))
// replace from         = substr(lease_details,length(help3)+1,.) if length(help3) > 1
// replace number_years = substr(lease_details,1,3) if length(help3) > 1
// cap drop help3
//
// gen help1            = regexs(0) if (regexm(from,"for [0-9][0-9]"))
// replace from 		 = subinstr(from,help1,"",.)
// replace help1 		 = subinstr(help1,"for","",.)
// replace number_years = help1 if help1 != ""
// cap drop help1
//
// gen help2            = regexs(0) if (regexm(lease_details,"[0-9][0-9] from and including"))
// replace from         = substr(lease_details,length(help2)+1,.) if length(help2) > 1
// replace number_years = substr(lease_details,1,2) if length(help2) > 1
// cap drop help2
//
// gen help3            = regexs(0) if (regexm(lease_details,"[0-9][0-9] from"))
// replace from         = substr(lease_details,length(help3)+1,.) if length(help3) > 1
// replace number_years = substr(lease_details,1,2) if length(help3) > 1
// cap drop help3
//
// gen help3            = regexs(0) if (regexm(lease_details,"[0-9][0-9] commencing on"))
// replace from         = substr(lease_details,length(help3)+1,.) if length(help3) > 1
// replace number_years = substr(lease_details,1,2) if length(help3) > 1
// cap drop help3
//
// gen help3            = regexs(0) if (regexm(lease_details,"[0-9][0-9] commencing"))
// replace from         = substr(lease_details,length(help3)+1,.) if length(help3) > 1
// replace number_years = substr(lease_details,1,2) if length(help3) > 1
// cap drop help3
//
// ************************
// * Get Date for "FROM"
// ************************
//
// replace from = trim(from)
// replace from = itrim(from)
//
// gen date_from     = date(from,"DMY")
// gen date_new1     = date(from,"MDY")
// gen date_new2     = date(from,"Y")
// gen date_new3     = date(from,"MY")
// replace date_from = date_new1 if date_new1 != . & date_from == .
// replace date_from = date_new2 if date_new2 != . & date_from == .
// replace date_from = date_new3 if date_new3 != . & date_from == .
//
// foreach dofl in "date of Lease"  "date of lease" "commencement date" {
// 	replace date_from = date_registered if from == "`dofl'"
// }
//
// format date_from %td
// destring(number_years), replace force
//
// **********************************
// * "From - To" Formulation
// **********************************
//
// cap drop to_place
// gen      to_place = strpos(lease_details,"to ")
// replace  to_place = strpos(lease_details,"To ")           if to_place == 0
// replace  to_place = strpos(lease_details,"until ")        if to_place == 0
// replace  to_place = strpos(lease_details,"TO ")           if to_place == 0
// replace  to_place = strpos(lease_details,"and expiring ") if to_place == 0
// replace  to_place = strpos(lease_details,"expiring ")     if to_place == 0
// replace  to_place = strpos(lease_details,"and ending")    if to_place == 0
// replace  to_place = strpos(lease_details,"ending")        if to_place == 0
// replace  to_place = strpos(lease_details,"and ends")      if to_place == 0
//
// cap drop part*
// gen part1 = substr(lease_details,1,to_place-1) if to_place > 3 & number_years == .
// gen part2 = substr(lease_details,to_place,.) if to_place > 3 & number_years == .
//
// replace part1 = subinstr(part1,"Commencing on and including","",.)
// replace part1 = subinstr(part1,"commencing on and including","",.)
// replace part1 = subinstr(part1,"commencing on","",.)
// replace part1 = subinstr(part1,"Commencing on","",.)
// replace part1 = subinstr(part1,"from and including","",.)
// replace part1 = subinstr(part1,"from","",.)
// replace part1 = subinstr(part1,"From and including","",.)
// replace part1 = subinstr(part1,"From","",.)
// replace part1 = subinstr(part1,"Form","",.)
// replace part1 = subinstr(part1,"FROM","",.)
// replace part1 = subinstr(part1,"form","",.)
// replace part1 = subinstr(part1,"For a term","",.)
// replace part1 = subinstr(part1,"Beginning on and including","",.)
// replace part1 = subinstr(part1,"beginning on and including","",.)
// replace part1 = subinstr(part1,"Beginning on","",.)
// replace part1 = subinstr(part1,"beginning on","",.)
// replace part1 = subinstr(part1,":","",.)
// replace part1 = subinstr(part1,"the ","",.)
// replace part1 = subinstr(part1,"and ","",.)
// replace part1 = subinstr(part1,"first day of","",.)
// replace part1 = subinstr(part1,"a term of years","",.)
// replace part1 = subinstr(part1,"A term of years","",.)
// replace part1 = subinstr(part1,"& including","",.)
// replace part1 = subinstr(part1,"Including","",.)
// replace part1 = subinstr(part1,"including","",.)
// replace part1 = subinstr(part1,"th ","",.)
// replace part1 = subinstr(part1,"fom ","",.)
// replace part1 = subinstr(part1,"A term","",.)
//
// foreach ending in "for"  {
// 	replace part1 = substr(part1,1,strpos(part1,"`ending'")-1) if strpos(part1,"`ending'") != 0
// }
//
// cap drop date_start
// gen date_start    = date(part1,"DMY")
// format date_start %td
//
// replace part2 = subinstr(part2,"to and including","",.)
// replace part2 = subinstr(part2,"To and including","",.)
// replace part2 = subinstr(part2,"and expiring on but not including","",.)
// replace part2 = subinstr(part2,"expiring on but not including","",.)
// replace part2 = subinstr(part2,"and expiring on","",.)
// replace part2 = subinstr(part2,"expiring on","",.)
// replace part2 = subinstr(part2,"and expiring","",.)
// replace part2 = subinstr(part2,"expiring","",.)
// replace part2 = subinstr(part2,"to ","",.)
// replace part2 = subinstr(part2,"an including","",.)
// replace part2 = subinstr(part2,"expire upon the","",.)
// replace part2 = subinstr(part2,"expire upon","",.)
// replace part2 = subinstr(part2,"expire on the","",.)
// replace part2 = subinstr(part2,"expire on","",.)
// replace part2 = subinstr(part2,"expire","",.)
// replace part2 = subinstr(part2,"inclusive","",.)
// replace part2 = subinstr(part2,"the first day of","1",.)
// replace part2 = subinstr(part2,"the ","",.)
// replace part2 = subinstr(part2,"and ","",.)
// replace part2 = subinstr(part2,"an ","",.)
// replace part2 = subinstr(part2,"including","",.)
// replace part2 = subinstr(part2,"(determinable)","",.)
// replace part2 = subinstr(part2,"12 noon","",.)
// replace part2 = subinstr(part2,"midnight","",.)
// replace part2 = subinstr(part2,"determinable as therein mentioned","",.)
// replace part2 = subinstr(part2,"th ","",.)
// replace part2 = subinstr(part2,"until","",.)
//
// cap drop date_end
// gen date_end = date(part2,"DMY")
// format date_end %td
//
// gen length = round((date_end - date_start) / 365)
//
// replace number_years = length      if number_years == .
// replace date_from    = date_start  if date_from == .
//
// compress
//
// save "$WORKING/full_lease_data_cleaned_term.dta", replace
//
// ********************************************************************************************************************************************** 
// * Drop the (small) number of leases of which we cannot extract lease details from the textual description
// * --> This number is small, given our extensive textual cleaning
// * --> Less than 0.2% of all lease details
// ********************************************************************************************************************************************** 

use "$WORKING/full_lease_data_cleaned_term.dta", clear

// drop if date_from    == .
drop if number_years == .

////////////////////////////////////////////
// Make merge key
////////////////////////////////////////////

gen merge_key = strtrim(stritrim(upper(description)))

//Remove commas/periods
replace merge_key = subinstr(merge_key,".","",.)
replace merge_key = subinstr(merge_key,",","",.)
replace merge_key = subinstr(merge_key,"'","",.)
// replace merge_key = subinstr(merge_key," ","",.)

//Drop missing entries
drop if missing(merge_key)

// Change date_from to MONTH-YEAR format
gen month_from = month(date_from)
gen year_from = year(date_from)
egen date_from_str = concat(year month), punct("-")
gen date_from_num = date(date_from_str, "YM")
format date_from_num %td
replace date_from = date_from_num
drop month year date_from_str date_from_num

drop if missing(date_registered)

///////////////////////////////////
// Deal with duplicates
///////////////////////////////////
duplicates drop
// Drop in terms of all variables
duplicates drop merge_key date_registered number_years date_from, force
keep description merge_key date_registered number_years date_from

// A couple ways to deal with remaining duplicates...
by date_registered merge_key, sort: egen mean_years = mean(number_years)
by date_registered merge_key, sort: egen mean_from = mean(date_from)
gen diff_from_mean_years = number_years - mean_years
gen diff_from_mean_from = date_from - mean_from

// Option 1: set duplicates as missing
duplicates tag merge_key date_registered, gen(dup)
gen number_years_missing = number_years
replace number_years_missing = . if dup > 0 & diff_from_mean_years!=0

count if missing(number_years_missing)

// Option 2: take mean of duplicates
replace number_years = mean_years
replace date_from = mean_from
format mean_from %td

// Option 3: take mean of duplicates that are close together, set others as missing
gen number_years_partial_missing = number_years if dup==0
replace number_years_partial_missing = mean_years if dup>0 & abs(diff_from_mean_years) < 50

count if missing(number_years_partial_missing)

duplicates drop merge_key date_registered number_years date_from, force

save "$WORKING/lease_data.dta", replace

// For merge:

keep merge_key description
duplicates drop merge_key, force
save "$WORKING/lease_data_for_merge.dta", replace
