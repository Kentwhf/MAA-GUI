function directionResults = getResultsAtAngleDirection(angleIndex, indices, trialMatrix)
%getResultsAtAngleDirection Return all the trials done at angle for a given
%direction from the session matrix
% direction = 0 --> UPHILL  |  direction == 1 --> DOWNHILL
% indices is a 5x1 vector with the indices to look for

directionResults = [trialMatrix(angleIndex, indices(1)) trialMatrix(angleIndex, indices(2)) ...
    trialMatrix(angleIndex, indices(3)) trialMatrix(angleIndex, indices(4)) trialMatrix(angleIndex, indices(5))];

end

