function cellsWrite = formatResults(parameterMap, REB, clientInfo)
%formatResults Put everything in the proper format for the excel sheet
%given the map of session parameters (ratings, MAAs, etc.)

%REB client subID subID brand name model iDAPT sex size order walkway {} {} upMAA downMAA firstSlip preslip slipperiness thermal fit heaviness overall ease use compare obv date time

cellsWrite = {REB clientInfo{1} parameterMap('subID') parameterMap('subID') clientInfo{2} clientInfo{3} clientInfo{4} ...
    parameterMap('footwearID') parameterMap('subSex') parameterMap('shoeSize') parameterMap('sesOrder') parameterMap('walkway') ...
    '' '' parameterMap('upMAA') parameterMap('downMAA') parameterMap('firstSlip') parameterMap('preSlip') parameterMap('slippery') ...
    parameterMap('thermal') parameterMap('bootFit') parameterMap('heaviness') parameterMap('overall') parameterMap('easePutting') ...
    parameterMap('useWinter') parameterMap('compared') parameterMap('obv') '' parameterMap('sesDate') parameterMap('sesTime') };

end

