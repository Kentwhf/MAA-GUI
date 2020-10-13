function slipOccur = findFirstSlip(trialMatrix)
%findFirstSlip Return the angle of the first slip in a session (uphill OR downhill)

UPHILL_COLS = [3 6 9 12 15];
DOWNHILL_COLS = [4 7 10 13 16];
THRESHOLD = 1;
FAIL = 0;

slipOccur = 'N/A';

for angleIndex = 1 : 16
    resultsUp = getResultsAtAngleDirection(angleIndex, UPHILL_COLS, trialMatrix);
    resultsDown = getResultsAtAngleDirection(angleIndex, DOWNHILL_COLS, trialMatrix);

    % 2 passes here and 2 fails above
    if length(find(resultsUp == FAIL)) >= THRESHOLD || length(find(resultsDown == FAIL)) >= THRESHOLD
        slipOccur = angleIndex - 1;  % this is where the first slip occured
        break
    end

end

end

