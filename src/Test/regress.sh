 
#	Verififer regression test	Version 1.6 of 3/3/86
#
#	The directory REGRESS is created.
#	The test results are in REGRESS/RESULTS
TESTS=../../test/cases
#
set -e
rm -f -r REGRESS
mkdir REGRESS
cd REGRESS
get $TESTS
rm -f msgs
vertestdrive *.pf >> RESULTS 2> RESULTS 
echo "Regression tests complete."
