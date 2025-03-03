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

### Setting up a new virtual Python environment
If you need to setup a new venv to control the library versions above, follow these steps:
*	Open a terminal
*	Make a new directory to hold your new python environment
    *	mkdir path/to/your/userDir/CovbatEnv
*	Create a new python environment there
    *	python3 -m venv path/to/your/userDir/CovbatEnv
*	Activate that python environment
    *	source  ./CovbatEnv/bin/activate.csh
    *	If the activate.csh doesn’t work try some combination of the other ‘activate’ scipts in this folder. source activate.csh is the only method that worked on our test machine
*	After activating, install the proper versions of the libraries we need for covbat (library versions that were validated for this build are reflected in steps below)
    *	pip install pandas==2.0.3
    *	pip install -U scikit-learn==1.3.0
    *	pip install patsy==0.5.3
*	Close the terminal
*	LAST STEP, DONT SKIP!: Edit your local ‘runCovbatWrapper.m’ file to include the path to ‘python3’ in your newly created python environment folder.
      * This will be in a subfunction in the runCovbatWrapper file, called 'getPathToPythonEnv()'.
      * Edit the variable called 'PATH_OF_YOUR_NEW_PYTHON_ENV' to point to the 'python3' in the new venv you just created


## Contents:
covbat.py: Modified version of covbat python library
covbatScript.py: Python wrapper script that is called from MATLAB
runCovbatWrapper.m: MATLAB function that takes in FC data and covariates table and runs covbat on it
testCovbatWrapper.m: Example script on running the covbat wrapper on random junk data

## Notes:
Note: covbat.py has been modified from original to replace deprecated 'iteritems' method

Note: The wrapper will generate temporary text data files in a new folder called 'tempCovbatFiles'. You shouldn't need to open or modify these files, they are only for passing data between python and matlab
