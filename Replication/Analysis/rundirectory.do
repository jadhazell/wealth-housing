cd "/Users/vbp/Dropbox (Personal)/Mac/Documents/Princeton/wealth-housing/Replication/Analysis"

set scheme plotplainblind

// Parameter 1: Differenced (vs. levels)
// Parameter 2: Restricted (to sample from differenced)
// Parameter 3: Use logs
// Parameter 4: Set properties with duplicate lease durations as missing instead of using mean durations
// Parameter 5: Use only flats
// Parameter 6: Winsorize prices at 1% level 
// Parameter 7: Drop observations with lease length less than 80
// Parameter 8: Remove observations before 2004
// Parameter 9: Only use below median price houses
// Parameter 10: Only use above median price houses

// do main_regression 1 0 0 0 0 0 0 0 0 0
// do main_regression 0 0 0 0 0 0 0 0 0 0

do main_regression 1 0 1 0 0 0 0 0 0 0
do main_regression 0 0 1 0 0 0 0 0 0 0

do main_regression 0 1 0 0 0 0 0 0 0 0
do main_regression 0 1 1 0 0 0 0 0 0 0
// do main_regression 0 1 0 0 0 0 0 0
// do main_regression 1 0 0 0 1 0 0 0
// do main_regression 0 0 0 0 1 0 0 0

// // Main on differences vs levels (logged and no logs)
// do more_lease_variation 1 0 0 0 0 0 0 0 0 0
// do more_lease_variation 0 0 0 0 0 0 0 0 0 0
// do more_lease_variation 1 0 1 0 0 0 0 0 0 0
// do more_lease_variation 0 0 1 0 0 0 0 0 0 0

// // Restrict levels equation
do more_lease_variation 0 1 0 0 0 0 0 0 0 0
do more_lease_variation 0 1 1 0 0 0 0 0 0 0

// // Remove observations with duplicate lease durations
// do more_lease_variation 1 0 0 1 0 0 0 0 0 0
// do more_lease_variation 1 0 1 1 0 0 0 0 0 0
// do more_lease_variation 0 0 0 1 0 0 0 0 0 0
// do more_lease_variation 0 0 1 1 0 0 0 0 0 0

// Remove lease durations under 80
// do more_lease_variation 1 0 0 0 0 0 1 0 0 0
// do more_lease_variation 1 0 1 0 0 0 1 0 0 0
// do more_lease_variation 0 0 0 0 0 0 1 0 0 0
// do more_lease_variation 0 0 1 0 0 0 1 0 0 0

// // Windsorize prices
// do more_lease_variation 1 0 0 0 0 1 0 0 0 0
// do more_lease_variation 1 0 1 0 0 1 0 0 0 0
// do more_lease_variation 0 0 0 0 0 1 0 0 0 0
// do more_lease_variation 0 0 1 0 0 1 0 0 0 0
//
// // Only flats
// do more_lease_variation 1 0 0 0 1 0 0 0 0 0
// do more_lease_variation 1 0 1 0 1 0 0 0 0 0
// do more_lease_variation 0 0 0 0 1 0 0 0 0 0
// do more_lease_variation 0 0 1 0 1 0 0 0 0 0

// Only years post 2004
do more_lease_variation 1 0 0 0 0 0 0 1 0 0
do more_lease_variation 1 0 1 0 0 0 0 1 0 0
do more_lease_variation 0 0 0 0 0 0 0 1 0 0
do more_lease_variation 0 0 1 0 0 0 0 1 0 0

// Only below median price houses
do more_lease_variation 1 0 0 0 0 0 0 0 1 0
do more_lease_variation 1 0 1 0 0 0 0 0 1 0
do more_lease_variation 0 0 0 0 0 0 0 0 1 0
do more_lease_variation 0 0 1 0 0 0 0 0 1 0

// Only above median price houses
do more_lease_variation 1 0 0 0 0 0 0 0 0 1
do more_lease_variation 1 0 1 0 0 0 0 0 0 1
do more_lease_variation 0 0 0 0 0 0 0 0 0 1
do more_lease_variation 0 0 1 0 0 0 0 0 0 1

// do snowballing 1 0 0 0 0 0 0
// do snowballing 1 0 1 0 0 0 0
do snowballing 0 0 0 0 0 0 0 0 0
do snowballing 0 0 1 0 0 0 0 0 0

do plot_residuals 0 0 0 0 0 0 0 0 0 0
do plot_residuals 1 0 0 0 0 0 0 0 0 0
do plot_residuals 0 0 1 0 0 0 0 0 0 0
do plot_residuals 1 0 1 0 0 0 0 0 0 0



histogram log_price_win

reghdfe log_price c.lease_duration_at_trans##c.interest_rate, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)

sum price, detail
global p25 = 84000
global p50 = 147500
global p75 = 244000

reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price < $p25, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)

reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price >= $p25 & price < $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)

reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price >= $p50 & price < $p75, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)

reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price >= $p75, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)

reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price < $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)

reghdfe log_price c.lease_duration_at_trans##c.interest_rate if price >= $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)


reghdfe price c.lease_duration_at_trans##c.interest_rate if price < $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)

reghdfe price c.lease_duration_at_trans##c.interest_rate if price >= $p50, absorb(i.location_n##i.date_trans) cluster(date_trans location_n)
