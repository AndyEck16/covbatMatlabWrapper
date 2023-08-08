# covbatMatlabWrapper
Wrapper for covbat

Wrapper to run execute the covbat.py script in MATLAB



## Setup:
Install python3 on your machine (tested with Python 3.8)
pip install pandas (if necessary)
pip install -U scikit-learn (if necessary)
pip install patsy (if necessary)

## Contents:
covbat.py: Modified version of covbat python library
covbatScript.py: Python wrapper script that is called from MATLAB
runCovbatWrapper.m: MATLAB function that takes in FC data and covariates table and runs covbat on it
testCovbatWrapper.m: Example script on running the covbat wrapper on random junk data

## Notes:
Note: covbat.py has been modified from original to replace deprecated 'iteritems' method

Note: The wrapper will generate temporary text data files in a new folder called 'tempCovbatFiles'. You shouldn't need to open or modify these files, they are only for passing data between python and matlab
