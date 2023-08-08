numSubj = 20;

testFcData = rand(40,40,numSubj);
testCovarTbl = table(rand(numSubj,1), round(rand(numSubj,1),0),rand(numSubj,1)*2, rand(numSubj,1)+2, ceil(rand(numSubj,1)*3), ...
    'VariableNames',{'numvar1','catvar2','numvar3','numvar4', 'batchVar'});
testModelString = '~ numvar1 + catvar2*numvar3';
colsInModelThatAreNumeric = {'numvar1','numvar3'};

%testCovarTbl.numvar1(3) = NaN;

newFc = runCovbatWrapper(...
                            testFcData, testCovarTbl, 'batchVar', ...
                            testModelString, colsInModelThatAreNumeric);