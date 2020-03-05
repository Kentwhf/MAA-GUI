% -----------------------------------------------------------------------
% A script for testing purpose
% Using MAA_digitized_sessions.m as reference
% Using historical MAA data sheets to examine the correstness of current
% algorithm, with prority of final MAAs but also angle adjustment
% Created by Kent 

%% --- Initial setup ---
workspace;  % Make sure the workspace panel is showing.
format longg;
format compact;
addpath(genpath(strcat(pwd, '/dependencies/dependencies/')));  % Add dependencies
tic

TRIAL_CELLS = 'A8:P30'; 
UPHILL_MAA_CELL = 'A40';
DOWNHILL_MAA_CELL = 'I40';
counter = 0;
files = NaN;
numOfSheets = 0;

% participant = Participant('sub100', 'm', 8);
% session = Session(participant, 0.08, 4.45, 68.00, 'dry', '12/12/12', '14:08', 8, 8, 8, 8, 8, 8, 8, 8, 'iDAPT000');

%% ---------- Make the ActiveX Excel App into MATLAB ----------
Excel = actxserver ('Excel.Application');

% Set preferred excel parameters - no sound, complaints, and visible
Excel.visible = true;
Excel.DisplayAlerts = false;
Excel.EnableSound = false;

%% --- Select input ---

TOP_LEVEL_DIR = 'U:\Projects\Winter Projects\Kent\WinterLab\MAA data sheet\';
topLevelFolder = uigetdir(TOP_LEVEL_DIR);  % choose the date folder

% topLevelFolder = 'U:\Projects\Winter Projects\Kent\WinterLab\MAA data sheet\2019-03-07\'; % Change to different folder if needed
% TOP_LEVEL_DIR = dir(topLevelFolder);
[allExcelFiles, numExcelFiles] = getAllDatafilePaths(topLevelFolder, TOP_LEVEL_DIR); % a vector of all MAA datafile paths in a given directory

%% -- Load and read files
for file = 1 : numExcelFiles
    currFile = allExcelFiles{file};
    fprintf('----- Current file: %s -----\n', currFile);
    
    % if the main data file doesn't exist, we go to the next file
    if ~exist(currFile,'file')
        fprintf(2, 'FILE DOES NOT EXIST: %s\n', currFile);
        continue
    end

    % Open the excel workbook datasheet file
    Excel.Workbooks.Open(currFile);
    Workbook = Excel.ActiveWorkbook;
    Worksheets = Workbook.sheets;
    
    % Get the number of worksheets in the source datasheet file
    numberOfSourceSheets = Worksheets.Count;
   
    datafileMatrix = {};
    
    sheetsEmpty = [0 0 0 0 0];
    
    % Read the sheet in the file
    for sheetIndex = 1 : numberOfSourceSheets
       
        % Invoke this excel file as active
        Worksheets.Item(sheetIndex).Activate;
        cell_subID = get(Excel.ActiveSheet, 'Range', 'E2:E2');  % no need range for merged cells. ask me if i care tho lmao yeet
        testEmpty = cell_subID.value;
        
        if isnan(testEmpty)
            continue 
        end
        
        numOfSheets = numOfSheets + 1;
        fprintf('----- Current sheet: %d -----\n', sheetIndex);
        sheetMatrix = {};
        
        sheetsEmpty(sheetIndex) = 1;
        
        % Get trial matrix range
        readBuffer = get(Excel.ActiveSheet, 'Range', TRIAL_CELLS);
        % disp(readBuffer.value);
        
        % Convert unknown trial to '*'
        ivalidEntries = cellfun(@ischar, readBuffer.value);
        readBuffer.value(ivalidEntries) = {-1}; 
        
        % Sort the trials by brute force
        trials = [readBuffer.value(:, 2:4); readBuffer.value(:, 5:7); readBuffer.value(:, 8:10)];
        % disp(trials);
        trials(any(cellfun(@(x) any(isnan(x)),trials),2),:) = [];
        [~,idx] = sort(cell2mat((trials(:,1)))); % sort just the first column
        trials = trials(idx,:);   % sort the whole matrix using the sort indices
      
        % Testing model
        operator = Operator();
        for trialNum = 1 : length(trials)
            upResult = trials{trialNum, 2};
            downResult = trials{trialNum, 3};
            if upResult == -1
                upResult = '*';
            end
            if downResult == -1
                downResult = '*';
            end
            %operator.recordResults(upResult, downResult);
            %operator.adjustAngle(upResult, downResult);
            operator.ProcessInput(operator.predictedAngle, upResult, downResult);
        end
        
        % Get table
        newline;
        fprintf('\n');

        % Remove all missing values to NaN 
        invalidEntries = cellfun(@ischar, operator.results);
        % disp(ivalidEntries);
        operator.results(invalidEntries) = {-1};  % any uni-directional trial is marked as -1 for the untested dir
        
        % Assign a new variable for comparision 
        temp = readBuffer.value;
        isNanEntries = cellfun(@isnan, temp);
        temp(isNanEntries) = {[]}; 
        
        disp(operator.results);
        fprintf('\n');
        disp(temp(1:16, 1:10));
        
        % Get MAAs
        cell_UPMAA = get(Excel.ActiveSheet, 'Range', UPHILL_MAA_CELL);
        cell_DOWNMAA = get(Excel.ActiveSheet, 'Range', DOWNHILL_MAA_CELL);
        upMAA = cell_UPMAA.value;
        downMAA = cell_DOWNMAA.value;

        operator.checkMAA;
        expectedUp = upMAA;
        expectedDown = downMAA;
        obtainedUp = operator.uphillMAA;
        obtainedDown = operator.downhillMAA;
        fprintf('Expected (from the datasheet): UPHILL=%d, DOWNHILL=%d\n', expectedUp, expectedDown);
        fprintf('Obtained: UPHILL=%d, DOWNHILL=%d\n', obtainedUp, obtainedDown);
        
        
        
        % if any([obtainedUp ~= expectedUp, obtainedDown ~= expectedDown])
        if ~isequal(operator.results, temp(1:16, 1:10)) || any([obtainedUp ~= expectedUp, obtainedDown ~= expectedDown])
            counter = counter + 1;
            files = vertcat(files, strcat(currFile, " Sheet#: ", string(sheetIndex)));
            files = rmmissing(files);
        end
        
        fprintf('============================================\n\n');

    end
    
    % free any utilized memory for the datasheet
    Workbook.Close(false);
    
    fprintf('Total inconsistencies=%d\n', counter);
    fprintf('Total Sheets=%d\n', numOfSheets);
    disp(files);
    
end

% Safely close the ActiveX server
Excel.Quit;
Excel.delete;
clear Excel;
toc
    






