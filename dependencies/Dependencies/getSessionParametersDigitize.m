function [parameterMap, errorMAAUp, errorMAADown] = getSessionParametersDigitize(Excel, SUB_CELL, FOOTWEAR_CELL, WALKWAY_CELL, SEX_CELL, UPHILL_MAA_CELL, DOWNHILL_MAA_CELL, DATE_CELL, TIME_CELL, SIZE_CELL, ...
    OBV_CELL, ORDER_CELL, PRESLIP_CELL, SLIPPERINESS_CELL, THERMAL_CELL, FIT_CELL, HEAVINESS_CELL, OVERALL_CELL, EASE_CELL, USE_CELL, COMPARE_CELL,  trialMatrix)
%Get MAA session constant parameters for the MAA digitize shit (i.e. iDAPT ID, subject ID, ice, etc.
%   DO NOT CALL THIS UNLESS THE EXCEL ACTIVEX SERVER IS ESTABLISHED TO THE
%   EXCEL FILE AND IS READY FOR READING!!!!!!!

% Read raw cells from excel file. This is shit but at the risk of the
% datasheet changing in the future this is easily modified
cell_subID = get(Excel.ActiveSheet, 'Range', SUB_CELL);
cell_footwearID = get(Excel.ActiveSheet, 'Range', FOOTWEAR_CELL); 
cell_walkway = get(Excel.ActiveSheet, 'Range', WALKWAY_CELL);
cell_sex = get(Excel.ActiveSheet, 'Range', SEX_CELL);
cell_UPMAA = get(Excel.ActiveSheet, 'Range', UPHILL_MAA_CELL);
cell_DOWNMAA = get(Excel.ActiveSheet, 'Range', DOWNHILL_MAA_CELL);
cell_DATE = get(Excel.ActiveSheet, 'Range', DATE_CELL);
cell_TIME = get(Excel.ActiveSheet, 'Range', TIME_CELL);
cell_SIZE = get(Excel.ActiveSheet, 'Range', SIZE_CELL);
cell_OBV = get(Excel.ActiveSheet, 'Range', OBV_CELL);
cell_ORDER = get(Excel.ActiveSheet, 'Range', ORDER_CELL);
cell_PRESLIP = get(Excel.ActiveSheet, 'Range', PRESLIP_CELL);
cell_SLIPPERINESS = get(Excel.ActiveSheet, 'Range', SLIPPERINESS_CELL);
cell_THERMAL = get(Excel.ActiveSheet, 'Range', THERMAL_CELL);
cell_FIT = get(Excel.ActiveSheet, 'Range', FIT_CELL);
cell_HEAVINESS = get(Excel.ActiveSheet, 'Range', HEAVINESS_CELL);
cell_OVERALL = get(Excel.ActiveSheet, 'Range', OVERALL_CELL);
cell_EASE = get(Excel.ActiveSheet, 'Range', EASE_CELL);
cell_USE = get(Excel.ActiveSheet, 'Range', USE_CELL);
cell_COMPARE = get(Excel.ActiveSheet, 'Range', COMPARE_CELL);

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
footwearID = regexprep(strtrim(footwearID),' +',' ');  % remove all spaces

walkway = lower(cell_walkway.value);

subSex = upper(cell_sex.value);
if isnan(subSex)
    subSex = 'UNKNOWN';
end

errorMAAUp = '';
errorMAADown = '';
upMAA = cell_UPMAA.value;
downMAA = cell_DOWNMAA.value;
[autoUp, autoDown] = findMAA(trialMatrix);

if isnumeric(upMAA) && upMAA ~= autoUp
    upMAA = autoUp
    errorMAAUp = sprintf('Uphill MAA recorded does not match expected! Obtained: %d  |  Expected: %d\nUsing Expected...\n', upMAA, autoUp);
end
if isnumeric(downMAA) && downMAA ~= autoDown
    downMAA = autoDown
    errorMAADown = sprintf('Downhill MAA recorded does not match expected! Obtained: %d  |  Expected: %d\nUsing Expected...\n', downMAA, autoDown);
end
if ~isnumeric(upMAA)
    upMAA = autoUp;
end
if ~isnumeric(downMAA)
    downMAA = autoDown;
end


firstSlip = findFirstSlip(trialMatrix);

% im too lazy for error checking lmao just trust the operator
sesDate = cell_DATE.value;
sesTime = cell_TIME.value;
if ~isnan(sesTime)
    sesTime = datestr(sesTime,'HH:MM');
end
shoeSize = cell_SIZE.value;
obv = cell_OBV.value;
if isnan(obv)
    obv = 'UNKNOWN';
end
sesOrder = cell_ORDER.value;
preSlip = cell_PRESLIP.value;
slippery = cell_SLIPPERINESS.value;
thermal = cell_THERMAL.value;
bootFit = cell_FIT.value;
heaviness = cell_HEAVINESS.value;
overall = cell_OVERALL.value;
easePutting = cell_EASE.value;
useWinter = cell_USE.value;
compared = cell_COMPARE.value;
if isnan(compared)
    compared = '';
end


keySet = {'subID', 'footwearID', 'walkway', 'subSex', 'firstSlip', 'upMAA', 'downMAA', 'sesDate', ... 
   'sesTime', 'shoeSize', 'obv', 'sesOrder', 'preSlip', 'slippery', 'thermal', 'bootFit', ...
   'heaviness', 'overall', 'easePutting', 'useWinter', 'compared'};
valueSet = {subID, footwearID, walkway, subSex, firstSlip, upMAA, downMAA, sesDate, sesTime, ...
    shoeSize, obv, sesOrder, preSlip, slippery, thermal, bootFit, heaviness, overall, ...
    easePutting, useWinter, compared};
parameterMap = containers.Map(keySet, valueSet);
    
end

