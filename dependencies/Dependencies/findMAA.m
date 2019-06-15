function [uphillMAA, downhillMAA] = findMAA(trialMatrix)
%findMAA Finds the MAA via brute force for legacy datasheets
%   Finds the first occurrence of 2 passes at angle X and 2 fails at angle X+1
UPHILL_COLS = [3 6 9 12 15];
DOWNHILL_COLS = [4 7 10 13 16];
PASS = 1;
FAIL = 0;
THRESHOLD = 2;

uphillMAA = -1;
downhillMAA = -1;

% ----- UPHILL
results0 = getResultsAtAngleDirection(1, UPHILL_COLS, trialMatrix);
results15 = getResultsAtAngleDirection(16, UPHILL_COLS, trialMatrix);

% base case 1: MAA 0 --> 2 fails at 0
if length(find(results0 == FAIL)) >= THRESHOLD
    uphillMAA = 0; 
    
% base case 2: MAA 15 --> 2 passes at 15
elseif length(find(results15 == PASS)) >= THRESHOLD
    uphillMAA = 15;
    
else
    % general case: iteratively search for 2 passes behind 2 fails lol
    for angleIndex = 1 : 15
        resultsCurrent = getResultsAtAngleDirection(angleIndex, UPHILL_COLS, trialMatrix);
        resultsNext = getResultsAtAngleDirection(angleIndex + 1, UPHILL_COLS, trialMatrix);
        
        % 2 passes here and 2 fails above
        if length(find(resultsCurrent == PASS)) >= THRESHOLD && length(find(resultsNext == FAIL)) >= THRESHOLD
            uphillMAA = angleIndex - 1;  
        end
    
    end
end

% ----- DOWNHILL
results0 = getResultsAtAngleDirection(1, DOWNHILL_COLS, trialMatrix);
results15 = getResultsAtAngleDirection(16, DOWNHILL_COLS, trialMatrix);

% base case 1: MAA 0 --> 2 fails at 0
if length(find(results0 == FAIL)) >= THRESHOLD
    downhillMAA = 0;
    
% base case 2: MAA 15 --> 2 passes at 15
elseif length(find(results15 == PASS)) >= THRESHOLD
    downhillMAA = 15;
else
    % general case: iteratively search for 2 passes behind 2 fails lol
    for angleIndex = 1 : 15
        resultsCurrent = getResultsAtAngleDirection(angleIndex, DOWNHILL_COLS, trialMatrix);
        resultsNext = getResultsAtAngleDirection(angleIndex + 1, DOWNHILL_COLS, trialMatrix);
        
        % 2 passes here and 2 fails above
        if length(find(resultsCurrent == PASS)) >= THRESHOLD && length(find(resultsNext == FAIL)) >= THRESHOLD
            downhillMAA = angleIndex - 1;  
        end
    
    end
    
end

end


