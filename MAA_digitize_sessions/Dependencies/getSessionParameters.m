function parameterMap = getSessionParameters(Excel, SUB_CELL, FOOTWEAR_CELL, WALKWAY_CELL, SEX_CELL, UPHILL_MAA_CELL, DOWNHILL_MAA_CELL, DATE_CELL, trialMatrix)
%Get MAA session constant parameters (i.e. iDAPT ID, subject ID, ice, etc.
%   DO NOT CALL THIS UNLESS THE EXCEL ACTIVEX SERVER IS ESTABLISHED TO THE
%   EXCEL FILE AND IS READY FOR READING!!!!!!!

% Read raw cells from excel file
cell_subID = get(Excel.ActiveSheet, 'Range', SUB_CELL);
cell_footwearID = get(Excel.ActiveSheet, 'Range', FOOTWEAR_CELL); 
cell_walkway = get(Excel.ActiveSheet, 'Range', WALKWAY_CELL);
cell_sex = get(Excel.ActiveSheet, 'Range', SEX_CELL);
cell_UPMAA = get(Excel.ActiveSheet, 'Range', UPHILL_MAA_CELL);
cell_DOWNMAA = get(Excel.ActiveSheet, 'Range', DOWNHILL_MAA_CELL);
cell_DATE = get(Excel.ActiveSheet, 'Range', DATE_CELL);

% Exract values from cell objects - conditionals for people who forgot the
% iDAPT/sub prefix (makes it consistent)
subID = cell_subID.value;
if length(subID) < 6
    subID = ['sub' num2str(subID)];
end

footwearID = cell_footwearID.value;
if length(footwearID) < 8
    footwearID = ['iDAPT' num2str(footwearID)];
end

walkway = lower(cell_walkway.value);

subSex = upper(cell_sex.value);
if strcmp(subSex, 'M'); subSex = 0;
elseif strcmp(subSex, 'F'); subSex = 1;
else; subSex = 1; % MOL was only females and that was where this was often missing. CHANGE THIS FOR FUTURE DEFAULT i.e. NaN
end

upMAA = cell_UPMAA.value;
downMAA = cell_DOWNMAA.value;
if isnan(upMAA) || isnan(downMAA)
    [upMAA, downMAA] = findMAA(trialMatrix);
end

sesDate = cell_DATE.value;

keySet = {'subID', 'footwearID', 'walkway', 'subSex', 'upMAA', 'downMAA', 'sesDate'};
valueSet = {subID, footwearID, walkway, subSex, upMAA, downMAA, sesDate};
parameterMap = containers.Map(keySet, valueSet);
    
end

