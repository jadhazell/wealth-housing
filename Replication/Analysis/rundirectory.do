cd "/Users/vbp/Dropbox (Personal)/Mac/Documents/Princeton/wealth-housing/Replication/Analysis"

// Parameter 1: Differenced (vs. levels)
// Parameter 2: Restricted (to sample from differenced)
// Parameter 3: Use logs (only applies to levels)
// do main_regression 1 0 0
// do main_regression 0 0 0
// do main_regression 0 1 0

// do more_lease_variation 1 0 0
do more_lease_variation 0 0 0
do more_lease_variation 0 1 0

do snowballing 1 0 0
do snowballing 0 0 0
do snowballing 0 1 0
 
// do snowballing
// do lease_extensions
