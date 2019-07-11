% -----------------------------------------------------------------------
% Created by Norman Huynh
% This will digitize the required data for the footwear results from a
% directory of MAA sessions into a separate excel sheet so the user can
% copy and paste this into the real sheet.
%
% Fields like wear-test distance and "session repeats" are not used because
% i dont know wtf they mean.
%
%
%% USER INSTRUCTIONS

% --- WARNING --- The footwear list sheet changes file name for some
% reason everytime new boots come in. Change the path as needed!!!

% 1. Move to the working directory of this script in MATLAB
% 2. Run this script in the command window i.e. >> MAA_digitize_sessions
% 3. Navigate to the folder that contains all the sheets you want digitized
% 4. Press OK and it will print everything to a digitize excel sheet
% 5. Copy n paste the new cells into the footwear_digitized_results etc.
% -----------------------------------------------------------------------

%% --- Initial setup ---
workspace;  % Make sure the workspace panel is showing.
format longg;
format compact;
addpath(genpath(strcat(pwd, '/dependencies')));  % Add dependencies
tic

%% ---------- Make the ActiveX Excel App into MATLAB ----------
Excel = actxserver ('Excel.Application');

% Set preferred excel parameters - no sound, complaints, and visible
Excel.visible = true;
Excel.DisplayAlerts = false;
Excel.EnableSound = false;


%% ------------ Handy constants and such for the excel parsing ---------- %
COL_TRIALS = [2, 5, 8, 11, 14];  % trial number is located in these columns of the MAA datasheet
UPHILL = 0;
DOWNHILL = 1;
REB = '10-051-DE';
ROW_HEADINGS = {'REB#'	'test'	'id'	'sub#'	'brand'	'name'	'Style#'	'iDAPT#'...
    'sex'	'Footwear size'	'order'	'surface'	'repeats'	'MAA'	'uphill'	'downhill'...
    'first slip'	'pre slip'	'slip'	'thermal'	'fit'	'heaviness'	'overall'...
    'easy take off'	'use'	'compare'	'observor'	'session'	'date'	'time'	'air temp'...
    'ice temp'	'RH'	'airtemp average'	'icetemp average'	'CIMCO AIR TEMP'	'CIMCO ICE TEMP'...
    'MATLAB AIR TEMP'	'MATLAB ICE TEMP'	'time order'};


TOP_LEVEL_DIR = 'J:\winterlab\footwear database\Tipper Operator\MAA Data\';
topLevelFolder = uigetdir(TOP_LEVEL_DIR);  % choose the date folder
if topLevelFolder == 0
    fprintf('Cancelled\n');
	return;
end

% Make the file for this digitized file if it doesn't exist already (which it probably wont lol)
EXPORTED_DATA_PATH = 'J:\winterlab\footwear database\Tipper Operator\AutomatedDigitizing\AutomatedDigitizedResults.xlsx';

% Change the datetime everytime, as sprintf() not defined for datetime()
EXPORTED_SHEET = sprintf('%s_%s', datestr(now, date), datestr(now, 'HH-MM PM'));
if ~exist(EXPORTED_DATA_PATH, 'file')
    fprintf('ALERT! FILE DOES NOT EXIST! MAKING IT NOW...\n');
    xlswrite(EXPORTED_DATA_PATH, ROW_HEADINGS, EXPORTED_SHEET);
    fprintf('SUCCESSFULLY MADE NEW EXCEL SHEET WITH NAME <%s>\n', EXPORTED_SHEET);
    
% if the file exists, make a new sheet, if needed
else
    [~, sheets] = xlsfinfo(EXPORTED_DATA_PATH);
    sheetValid = any(strcmp(sheets, EXPORTED_SHEET));
    
    if sheetValid == 0
        xlswrite(EXPORTED_DATA_PATH, ROW_HEADINGS, EXPORTED_SHEET);
        fprintf('SUCCESSFULLY MADE NEW EXCEL SHEET WITH NAME <%s>\n', EXPORTED_SHEET);
    end
end

% FOOTWEAR LIST SHEET - SOMETIMES CHANGES!!!
FOOTWEAR_LIST_PATH = 'I:\winterlab\footwear database\Master list of footwear updated 20190626.xlsx';

% FOOTWEAR SHEET NUMBER TO READ (read the first sheet)
FOOTWEAR_SHEET_INDEX = 1;

% Parse the footwear data into a table
footwearTable = readtable(FOOTWEAR_LIST_PATH);
footwearTable.Properties.RowNames = footwearTable.idapt_;

% Sheets and file counters
numSheetsRead = 0;
numEmptyFiles = 0;
   
% IF THE DATASHEET EVER CHANGES, MODIFY THESE CELLS CONSTANTS SO THEY POINT TO THE CORRECT LOCATION!!
SUB_CELL = 'E2';
WALKWAY_CELL = 'M2';
FOOTWEAR_CELL = 'E3';
TRIAL_CELLS = 'A8:P30';
DATE_CELL = 'C5';
TIME_CELL = 'G5';
SIZE_CELL = 'C4';
OBV_CELL = 'K5';
ORDER_CELL = 'O5';
PRESLIP_CELL = 'I6';
SEX_CELL = 'G4';
UPHILL_MAA_CELL = 'A40';
DOWNHILL_MAA_CELL = 'I40';
SLIPPERINESS_CELL = 'E31';
THERMAL_CELL = 'E32';
FIT_CELL = 'E33';
HEAVINESS_CELL = 'E34';
OVERALL_CELL = 'E35';
EASE_CELL = 'E36';
USE_CELL = 'E37';
COMPARE_CELL = 'E38';

% error summary
errorCount = 0;
errorsInData = {};
lookupError = 'LOOKUP ERROR';
errorUpMAA = 'ERROR UPHILL MAA';
errorDownMAA = 'ERROR DOWNHILL MAA';

%REB client subID subID brand name model iDAPT sex size order walkway {} {} upMAA downMAA firstSlip preslip slipperiness thermal fit heaviness overall ease use compare obv date time

%% ------------ Find all datasheet files we need to parse -------------- %
[allExcelFiles, numExcelFiles] = getAllDatafilePaths(topLevelFolder, TOP_LEVEL_DIR);

% next section output - for console readability
fprintf('Working on it...\n\n====================================\n');


%% -------------- Excel I/O from all obtained files as *Angles-->Trial* plot ----------- %
% Find the next empty row
%currentExcelRow = 3; %GoToNextRowInColumn(Excel, 'A');

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
    %fprintf('      --> Num sheets: %d\n', numberOfSourceSheets);
    
    % Collection matrix for all data IN A SINGLE FILE to write to file
    datafileMatrix = {};
    
    sheetsEmpty = [0 0 0 0 0];
    
    % Read the sheet in the file
    for sheetIndex = 1 : numberOfSourceSheets
        sheetMatrix = {};
        
        % Invoke this excel file as active
        Worksheets.Item(sheetIndex).Activate;
        cell_subID = get(Excel.ActiveSheet, 'Range', 'E2:E2');  % no need range for merged cells. ask me if i care tho lmao yeet
        testEmpty = cell_subID.value;
        if isnan(testEmpty)
            continue 
        end
        sheetsEmpty(sheetIndex) = 1;
        
        % Get trial matrix range
        readBuffer = get(Excel.ActiveSheet, 'Range', TRIAL_CELLS);
        disp(readBuffer.value);
        
        % Useless code
        % Remove all missing values to NaN 
        ivalidEntries = cellfun(@ischar, readBuffer.value);
        disp(ivalidEntries);
        readBuffer.value(ivalidEntries) = {-1};  % any uni-directional trial is marked as -1 for the untested dir
       
        % Extract the numbers and convert to a 2D array
        myDataRetrieved = cell2mat(readBuffer.value);
        disp(myDataRetrieved);

        % Read info from MAA columns and rows of participant results
        [parameterMap, errorMAAUp, errorMAADown] = getSessionParametersDigitize(Excel, SUB_CELL, FOOTWEAR_CELL, WALKWAY_CELL, SEX_CELL, UPHILL_MAA_CELL, DOWNHILL_MAA_CELL, DATE_CELL, TIME_CELL, SIZE_CELL, OBV_CELL, ORDER_CELL, PRESLIP_CELL, SLIPPERINESS_CELL, THERMAL_CELL, FIT_CELL, HEAVINESS_CELL, OVERALL_CELL, EASE_CELL, USE_CELL, COMPARE_CELL, myDataRetrieved);
                        
        % Get technology and info of boot
        [client, brand, name, modelNum, tech] = getSessionClientInfo(footwearTable, parameterMap('footwearID'));
        
        clientInfo = [client, brand, name, modelNum, tech];
        errorFind = strfind(cellstr(clientInfo), 'ERROR');
        errorFindResults = sum(cell2mat(errorFind));
        if errorFindResults > 0
            fprintf(2, 'ERROR! %s is missing information from footwear table!!!\n', parameterMap('footwearID'));
            fprintf('Client: %s  |  Brand: %s  |  Name: %s  |  Model: %s  |  Tech: %s\n', client, brand, name, modelNum, tech);
            fprintf('Error located in %s  | SHEET %d. Skipping sheet...\n\n', currFile, sheetIndex);
            
            errorsInData = [errorsInData sprintf('%s  |  Sheet %d  |  %s', currFile, sheetIndex, lookupError)];
            errorCount = errorCount + 1;
            continue
        end
        
        if parameterMap('upMAA') == -1  || ~strcmp('', errorMAAUp)
            disp(parameterMap('upMAA'));
            disp(errorUpMAA);
            fprintf(2, 'WARINING! Funky UP MAA at %s  |  Sheet %d. %s \n', currFile, sheetIndex, errorUpMAA);
            errorsInData = [errorsInData sprintf('%s  |  Sheet %d  |  %s', currFile, sheetIndex, errorUpMAA)];
            errorCount = errorCount + 1;
        end
        if  parameterMap('downMAA') == -1 || ~strcmp('', errorMAADown)
            fprintf(2, 'WARINING! Funky DOWN MAA at %s  | Sheet %d. %s\n', currFile, sheetIndex, errorDownMAA);
            errorsInData = [errorsInData sprintf('%s  |  Sheet %d  |  %s', currFile, sheetIndex, errorDownMAA)];
            errorCount = errorCount + 1;
        end

        sheetRowResults = formatResults(parameterMap, REB, clientInfo);
        
        datafileMatrix = vertcat(datafileMatrix, sheetRowResults);  % A matrix containing session data per row. Entire matrix is all sheets in 1 file
        
        numSheetsRead = numSheetsRead + 1;
    
    end
    
    % free any utilized memory for the datasheet
    Workbook.Close(false);
    
    % Skip if all sheets were empty in the file
    if sum(sheetsEmpty) == 0
        numEmptyFiles = numEmptyFiles + 1;
        continue 
    end
    
    % Open our datasheet to write parsed session info
    Excel.Workbooks.Open(EXPORTED_DATA_PATH);
    Workbook = Excel.ActiveWorkbook;
    Worksheets = Workbook.sheets;
    
    % Invoke this excel file as active
    Worksheets.Item(EXPORTED_SHEET).Activate;
    
    % Find the last row (i.e. empty spot) of the master sheet
    currentExcelRow = Excel.ActiveSheet.UsedRange.Rows.Count + 1;
    
    % write all the files data to the excel sheet
    [rows, cols] = size(datafileMatrix);
    cellReference = sprintf('A%d:%s%d', currentExcelRow, xlscol(cols), currentExcelRow + rows - 1);
    
    % WRITE TO SHEET
    xlswrite1(EXPORTED_DATA_PATH, datafileMatrix, EXPORTED_SHEET, cellReference);
  
    % update next excel row
    currentExcelRow = currentExcelRow + rows;
    
    % save the datasheet
    invoke(Excel.ActiveWorkbook,'Save'); 
    
    %row = GoToNextRowInColumn(Excel, 'A')
    
    % close the master datasheet
    Workbook.Close(false);
    
end     % Excel datafiles for-loop

% Safely close the ActiveX server
Excel.Quit;
Excel.delete;
clear Excel;

fprintf('\n\n====================================\n');
fprintf('Finished! Recorded %d non-empty files in %.2f seconds. We found %d sessions\n\n', numExcelFiles - numEmptyFiles, toc, numSheetsRead);
fprintf('----------\n');
fprintf('There were %d errors encountered.\n', errorCount);
fprintf('Files with errors:\n');
fprintf('%s\n', errorsInData{:})
fprintf('----------\n');

disp('done :)')



