

cd "/Users/vbp/Dropbox (Personal)/Mac/Documents/Princeton/wealth-housing/Replication/Analysis"

set scheme plotplainblind

do main_regression 1 1 0 1
do more_lease_variation 1 1 0 1
do robustness_checks 1 1 0 1


do leads_and_lags 1 
do lease_extensions
