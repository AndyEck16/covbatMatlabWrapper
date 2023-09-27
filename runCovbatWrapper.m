function fcDataPostCovbatSquare = runCovbatWrapper(inFcData, covariateTable, batchColNameStr, modelString, colsInModelThatAreNumeric)
% runCovbat - This is a wrapper for a third party python function script
% that implements CovBat. CovBat is a method designed to remove site
% effects from fc data.
%
% inputs:
%   inFcData - [numParcels x numParcels x numSubj] matrix of FC data
%   inCovarTbl - table of covariates. Matlab table object that includes one
%                column per covariate, and 1 row for each subject
%   batchColumn - name string of column in 'inCovarTbl' that represents the
%                 batch (or site) variable where you think there are differences among
%                 batches you'd like to remove
%   batchModelString - string to represent model of how you think variables
%                      in 'inCovarTbl' are causing batch effects. 
%                      Ex: "~ Age + mutation * education + behavScore"
%   colsInModelThatAreNumeric - cell string array of column names in
%                               'colsInModel' that are numeric rather than
%                               categorical. 
%                               Ex: 'Age' and 'income' are probably
%                               numeric, and 'sex' and 'mutationFlag' are
%                               categorical 
%
%
% outputs:
%    newFc - [numParcels x numParcels x numSubjInOutput] matrix of FC data
%    newCovarTbl - copy of 'inCovarTbl' filtered to only have subjects that
%                  were included in the covbat analysis
%
    SHOW_WARNING_PROMPTS = true;

    % Make copy of covar table that replaces all illegal characters that
    % will throw errors in covbat py script
    [cleanCovarTbl, illegalCharsFound] = removeIllegalCharactersFromCovarTbl(covariateTable);
    
    if illegalCharsFound && SHOW_WARNING_PROMPTS
        warningPromptAnswer = continueIfIllegalCharsPrompt();
        if ~strcmp(warningPromptAnswer,'Yes')
            return;
        end
        covariateTable = cleanCovarTbl;
    end
    
    errorIfModelTermsMissingFromCovariates(modelString, covariateTable);
    
    errorIfModelTermsHaveNaNValues(modelString, covariateTable);
    
    %% Find all subjects that are alone in their batch and remove them
    subjIsUniqueInBatchFlag = findSubjsThatAreUniqueInBatch(covariateTable, batchColNameStr);
    
    errorIfUniqueSubjectsInBatch(subjIsUniqueInBatchFlag, batchColNameStr)
    
        
    
    %% Generate covbat input files
    tempFileFolderName = 'tempCovbatFiles';
    if ~isfolder(tempFileFolderName)
        mkdir(tempFileFolderName)
    end
    
    fcDataFlat = reshapeSquareFcIntoFlat(inFcData);
    
    writeCovBatFcDataInputTxtFile(fullfile(tempFileFolderName,'tempfcData.txt'), fcDataFlat);
    writeCovBatCovariateInputTxtFile(fullfile(tempFileFolderName,'covarTbl.txt'),covariateTable);
    
    %% Run Python covbat script on input files and designated batch / model strings 
    %system('pip install patsy');
    [thisFileDir, ~, ~] = fileparts(mfilename('fullpath'));
    pyFuncFullPath = fullfile(thisFileDir,'covbatScript.py');
    
    colsInModelThatAreNumeric_string = cellStrArray2SingleString(colsInModelThatAreNumeric);
    runCmdWithModelStr = sprintf("python3 ""%s"" ""%s"" ""%s"" ""%s""", pyFuncFullPath, batchColNameStr, modelString, colsInModelThatAreNumeric_string);
    anyErr = system(runCmdWithModelStr);
    if anyErr
        return;
    end
    
    
    %% Get ouptut covbat file and format into square fc data
    fcPostCovbatFilename = fullfile(tempFileFolderName,'matlabCovBat_FC_output.txt');
    fcDataPostCovbat = readtable(fcPostCovbatFilename);
    fcDataPostCovbat = fcDataPostCovbat(:,2:end);
    fcDataPostCovbatMtx = table2array(fcDataPostCovbat);
    fcDataPostCovbatMtx = fcDataPostCovbatMtx';

    fcDataPostCovbatSquare = reshapeFlatFcIntoSquares(fcDataPostCovbatMtx);
    
    %% Delete temp files made
    
    delete(fullfile(tempFileFolderName,'tempfcData.txt'));
    delete(fullfile(tempFileFolderName,'covarTbl.txt'));
    delete(fullfile(tempFileFolderName,'matlabCovBat_FC_output.txt'));
    


end

function [cleanCovarTbl, illegalCharsFound] = removeIllegalCharactersFromCovarTbl(inCovarTbl)    
    %Make new version of covariate table that replaces illegal characters
    %that will cause errors in the covbat.py function
    
    cleanCovarTbl = inCovarTbl;
    illegalCharsFound = false;
    [totalSubj, totalCovars] = size(inCovarTbl);
    colNames = inCovarTbl.Properties.VariableNames;
    
    for covarCol = 1:totalCovars
        thisColName = colNames{covarCol};
        colIsNumeric = isnumeric(inCovarTbl.(thisColName));
        if ~colIsNumeric
            illegalStrsThisCol = false;
            unqStrsInCol = unique(cleanCovarTbl(:,covarCol));

            legalStrs = makeStringsLegalForCovbat(unqStrsInCol);
            numUnqStrs = length(unqStrsInCol);
            for unqStrIdx = 1:numUnqStrs
                if ~strcmp(legalStrs{unqStrIdx}, unqStrsInCol{unqStrIdx})
                    illegalStrsThisCol = true;
                    illegalCharsFound = true;
                end
            end

            if illegalStrsThisCol
                for unqStrIdx = 1:length(unqStrsInCol)
                    thisOrigStr = unqStrsInCol{unqStrIdx};
                    subjThisStr = strcmp(cleanCovarTbl(:,covarCol), thisOrigStr);
                    cleanCovarTbl(subjThisStr,covarCol) = legalStrs(unqStrIdx);
                end
            end
            
        end
        
    end


end

function legalStrCellArray = makeStringsLegalForCovbat(inStrCellArray)

    legalStrCellArray = inStrCellArray;
    legalStrCellArray = erase(legalStrCellArray," ");
    legalStrCellArray = strrep(legalStrCellArray, '<','lt');
    legalStrCellArray = strrep(legalStrCellArray, '+','plus');

end

function subjIsUniqueInBatchFlag = findSubjsThatAreUniqueInBatch(inCovarTbl, batchColNameStr)

    [numSubj,~] = size(inCovarTbl);
    subjIsUniqueInBatchFlag = zeros(numSubj,1);
    
    batchValues = inCovarTbl.(batchColNameStr);
    unqBatches = unique(batchValues);    
    
    if isnumeric(unqBatches)
        for batchIdx = 1:length(unqBatches)
            thisBatch = unqBatches(batchIdx);
            subjMatchThisBatch = batchValues==thisBatch;
            if sum(subjMatchThisBatch) == 1
                subjIsUniqueInBatchFlag(subjMatchThisBatch) = 1;
            end
        end
    else
        for batchIdx = 1:length(unqBatches)
            thisBatch = unqBatches{batchIdx};
            subjMatchThisBatch = strcmp(batchValues, thisBatch);
            if sum(subjMatchThisBatch) == 1
                subjIsUniqueInBatchFlag(subjMatchThisBatch) = 1;
            end
        end
    end
    
    


end

function illegalCharWarningChoice = continueIfIllegalCharsPrompt()

    illegalCharWarnString = 'Illegal characters detected in covariate file. Output covar table will replace illegal characters. Is this OK?';
    illegalCharWarningChoice = questdlg(illegalCharWarnString,'Illegal Characters','Yes','Quit Program');
    
end

function uniqueSubjectsInBatchChoice = continueIfSubjectsAloneInBatch()

    subjAloneInBatchWarnString = 'Some subjects are alone with their value of the selected batch variable, and must be excluded from the covbat output. Continue?';
    uniqueSubjectsInBatchChoice = questdlg(subjAloneInBatchWarnString,'Remove Subjects Alone In Batch','Yes','Quit Program');
    
end

function errorIfUniqueSubjectsInBatch(uniqueSubjInBatchFlag, batchColStr)

    rowsWithUniqueSubj = find(uniqueSubjInBatchFlag);
    if any(rowsWithUniqueSubj)
        error(['COVBAT error: Some subjects are alone with their value of the selected batch variable, %s\,]',...
               'Those subjects must be excluded from covariate and FC data to be included in covbat analysis.\n',...
               'Subjects unique in their batch are at the following indexes in the input fc and covariate data: %i'],...
               batchColStr, rowsWithUniqueSubj);
    end
    
end

function errorIfModelTermsMissingFromCovariates(modelString, covariateTable)

    covariateNames = covariateTable.Properties.VariableNames;
    
    modelTerms = parseModelStringIntoVariableNames(modelString);
    
    %Confirm all terms in model have matching column in covariate table
    modelTermsNotInCovariates = '';
    for i = 1:length(modelTerms)
        thisModelTerm = modelTerms{i};
        thisModelTermFoundInCovariates = any(cellfun(@(x) strcmp(x, thisModelTerm), covariateNames));
        if ~thisModelTermFoundInCovariates
            modelTermsNotInCovariates = [modelTermsNotInCovariates, thisModelTerm, ' '];
        end
    end
    
    if ~isempty(modelTermsNotInCovariates)        
        error('\n\nrunCovbatWrapper Preprocessing: The following terms are specified in model, but are not found in covariate table: %s'\n,...
            modelTermsNotInCovariates);
    end

end

function errorIfModelTermsHaveNaNValues(modelString, covariateTable)

    
    modelTerms = parseModelStringIntoVariableNames(modelString);
    stringOfVarsWithNans = [];
    for i = 1:length(modelTerms)
        thisModelTerm = modelTerms{i};
        thisCovariate = covariateTable.(thisModelTerm);
        if any(isnan(thisCovariate))
            stringOfVarsWithNans = [stringOfVarsWithNans, thisModelTerm, ' '];
        end        
    end
    
    if ~isempty(stringOfVarsWithNans)
        error(['\n\nrunCovbatWrapper Preprocessing: Some variables specified in the desired model have NaN values in covariate table.\n',...
                    'Either exclude those variables from the model, or remove subjects with NaN values from FC and covariate data to process without error.\n',...
                    'Variables with NaNs: %s\n\n'],stringOfVarsWithNans);            
    end

end

function modelTermCellStr = parseModelStringIntoVariableNames(modelString)

    % Find variable names in model string. Check that they exist in your
    % covariate table, and that none of them have NaN's
    modelTermCellStr = strsplit(modelString,{'~','+','*',' ','-'});
    modelTermIsEmptyTextField = false(1,length(modelTermCellStr));
    for i = 1:length(modelTermCellStr)
        if isempty(modelTermCellStr{i})
            modelTermIsEmptyTextField(i) = true;
        end
    end
    modelTermCellStr = modelTermCellStr(~modelTermIsEmptyTextField);

end

function fcDataFlat = reshapeSquareFcIntoFlat(sqFcData)

    [numROI, ~, numSubj] = size(sqFcData);
    tempOnesMtxOneSubj = ones(numROI, numROI);
    idxOfLowerTri = find(tril(tempOnesMtxOneSubj));
    
    numUniqueEdgeCombos = length(idxOfLowerTri);
    
    fcDataFlat = zeros(numSubj, numUniqueEdgeCombos);
    for subjIdx = 1:numSubj
        thisSubjFc = sqFcData(:,:,subjIdx);
        fcDataFlat(subjIdx,:) = thisSubjFc(idxOfLowerTri);
    end

end

function squareFc = reshapeFlatFcIntoSquares(flatFc)
    [numSubj, numFcEdges] = size(flatFc);
    numROI = (-1 + sqrt(1 + 8*numFcEdges)) / 2;
    
    squareFc = zeros(numROI, numROI, numSubj);
    
    index_matrix = tril(ones(numROI));
    index_matrix(index_matrix>0) = 1:numFcEdges;
    
    for rowIdx = 1:numROI
        for colIdx = 1:rowIdx
            flatIdx = index_matrix(rowIdx,colIdx);
            squareFc(rowIdx, colIdx, :) = flatFc(:,flatIdx);
            squareFc(colIdx, rowIdx, :) = flatFc(:,flatIdx);
        end
    end
end

function outStr = cellStrArray2SingleString(inCellArr)
    
    outStr = '';
    
    if ~isempty(inCellArr)
        outStr = inCellArr{1};
    end
    for i = 2:length(inCellArr)
        
        thisStr = inCellArr{i};
        outStr = strcat(outStr, ', ', thisStr);        
        
    end


end

function writeCovBatFcDataInputTxtFile(fName, fcData)
    %This function takes a 2D matrix of fc data and writes it to a tab
    %delimited txt file that can be read into an existing covBat.py file
    %for testing covBat algorithm
    %
    %inputs:
    %  fName - string, name of file to save
    %  fcData - numSubj x numFcEdges matrix
    [numSubjs, numFcEdges] = size(fcData);
    
    fid = fopen(fName,'w');
    
    %Write header line
    
    %fprintf(fid, 'fcEdgeId');    
    for subjIdx = 1:numSubjs
        fprintf(fid, '\t');
        fprintf(fid, 'subjId%i',subjIdx);
    end
    
    %Print each vector of fc edges for each subject
    for fcIdx = 1:numFcEdges
        fprintf(fid,'\n');
        fprintf(fid, 'fcIdx%i',fcIdx);
        fprintf(fid, '\t%1.6f',fcData(:,fcIdx));        
    end
    
    fclose(fid);

end

function writeCovBatCovariateInputTxtFile(fName, covarTbl)
    %This function takes a matlab table of covariates and writes it to a
    %tab delimited txt file that can be read into an existing covBat.py
    %file for testing covBat algorithm
    %
    %inputs:
    %  fName - string, name of file to save
    %  covarTbl - matlab tbl: numSubj x numCovariates, along with covariate
    %  names
    
    [numSubjs, numCovars] = size(covarTbl);
    
    fid = fopen(fName,'w');
    
    covarNames = covarTbl.Properties.VariableNames;
    %Write header line
    fprintf(fid, 'subjId');
    for covarIdx = 1:numCovars
        fprintf(fid, '\t%s',covarNames{covarIdx});
    end
    
    %Print each vector of covariates for each subject
    for subjIdx = 1:numSubjs
        fprintf(fid,'\n');
        fprintf(fid, 'subjId%i',subjIdx);
        for covarIdx = 1:numCovars
            if iscell(covarTbl.(covarNames{covarIdx})(subjIdx))
                thisCell = covarTbl.(covarNames{covarIdx})(subjIdx);
                thisCellVal = thisCell{1};
            else
                thisCellVal = covarTbl.(covarNames{covarIdx})(subjIdx);
            end
            
            if isnumeric(thisCellVal)
                fprintf(fid, '\t%1.10f',covarTbl.(covarNames{covarIdx})(subjIdx));
            else
                fprintf(fid, '\t''%s''', thisCellVal);
            end
            
        end
        
    end
    
    fclose(fid);


end



function outSquare = fullSquareFromLowerTriangleAndNans(inSquare)
    inSquareNoNans = inSquare;
    inSquareNoNans(isnan(inSquare)) = 0;
    
    %Make upper diag match lower diag
    outSquare = inSquareNoNans + inSquareNoNans';

end