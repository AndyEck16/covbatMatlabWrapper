import patsy
import time
import sys
import pandas as pd
import numpy as np

import covbat as cb

# import importlib
# importlib.reload(cb)

# read data from R output

#Expects command line arguments in the following order:
#arg1: Text name of batch column variable in covariate file
#arg2: String to specify model to pass to covbat. Eg: "~ mutation + Age + income*only_child_flag"
#arg3: Text name of columns in model that are numeric rather than categorical

batchVarName = sys.argv[1]
modelStr = sys.argv[2]
numerColNameStr = sys.argv[3]
numerColName = [x.strip() for x in numerColNameStr.split(",")]

covTbl = pd.read_table('./tempCovbatFiles/covarTbl.txt', index_col=0)
fcDat = pd.read_table('./tempCovbatFiles/tempfcData.txt', index_col=0)

mod = patsy.dmatrix(modelStr, covTbl, return_type="dataframe")


#### CovBat test ####
ebat = cb.covbat(fcDat, covTbl[batchVarName], mod, numerColName)


ebat.to_csv("./tempCovbatFiles/matlabCovBat_FC_output.txt", sep="\t") # save Python output