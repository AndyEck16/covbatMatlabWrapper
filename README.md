# covbatMatlabWrapper
Wrapper for covbat library

Covbat is intended to correct for batch effects in functional connectivity data. Specifically, it is intended to remove scanner specific effects from functional connectivity data, so that effects of other covariates that may correlate with site or scanner are not masked by scanner effects.

The covariates themselves are not altered by running this wrapper, only the FC data is.

Wrapper to covbat.py script in MATLAB.

covbat.py script based from
https://github.com/andy1764/CovBat_Harmonization/tree/master/Python
with modification to correct deprecated 'iteritems' method.

# License
Artistic License 2.0


## Setup:
This script requires specific versions of certain libraries.
Install python3 on your machine (tested with Python 3.8)
Create a virtual environment, activate it, and install the following libraries/versions:
pip install pandas==2.0.3
pip install -U scikit-learn==1.3.0
pip install patsy==0.5.3

Later versions of these packages may break the script, so be sure to get those particular versions for best stability

## Contents:
covbat.py: Modified version of covbat python library
covbatScript.py: Python wrapper script that is called from MATLAB
runCovbatWrapper.m: MATLAB function that takes in FC data and covariates table and runs covbat on it
testCovbatWrapper.m: Example script on running the covbat wrapper on random junk data

## Notes:
Note: covbat.py has been modified from original to replace deprecated 'iteritems' method

Note: The wrapper will generate temporary text data files in a new folder called 'tempCovbatFiles'. You shouldn't need to open or modify these files, they are only for passing data between python and matlab
