classdef Operator < handle
    %   Operator - an abstracted tipper operator object (Model)
    %   Tipper properties during the MAA experiment
    %   UML pending... but 'uses' Participant and Session classes
    
    properties
        session  % contains participant and all other session goodies
        currAngle % start at 3!
        resultsUp  % table of results for uphill
        resultsDown  % table of results for downhill
        timesVisitedAngles  % hashmap of angle-># times visited
        
        % table of results for all trails (new)
        results
        
        uphillMAA  % holds uphill MAA
        downhillMAA  % holds downhill MAA
        
        % boolean flags for found MAAs
        foundUphill  % flag for uphill MAA found
        foundDownhill % flag for downhill MAA found
        
        trialNum  % record trial number
        firstSlip % first slip flag
        firstSlipAngle % where the first slip was located
        lastTestedAngle % the angle where we just tested prior to moving
        lastResultUphill % previously visited angle for uphill
        lastResultDownhill % previously visited angle for downhill
        
        tseriesplot % container for time series data
    end
    
    events
        dataChanged % The exposed data has changed
        selecterror % An error occurred when selecting values 
    end
    
    properties(Constant)
        % physical constraints
        MAX_ANGLE=15  % physical maximum tipper angle
        MIN_ANGLE=0  % minimum angle for the tipper
        
        % moving the tipper
        INCREMENT=1  % increase/decrease by 1 degree as a step
        INITIAL_INCREMENT=2  % prior to first slip, increment by 2 degrees
        
        MAX_VISITS=3  % max number of visited per angle
        PASS_THRESHHOLD=2  % 2 is passes at an angle is considered a potential MAA canditate/lower bound
        
        INITIAL_ANGLE=3  % the first tipper angle starts at 3 degrees
        
        % directions
        UP='UP'  % up direction macro
        DOWN='DOWN'  % down direction macro
    end
    
    methods
        %% Constructor, take in session object info
        function operator = Operator(session)
            operator.session = session;
            operator.currAngle = 3;  % initial angle is 3
            
            % make a table for uphill and downhill, first column is angles
            % ???
            operator.resultsUp = cell(15, 7); 
            operator.resultsDown = cell(15, 7);
            for i=1:16 
               operator.resultsUp{i,1} = i-1;
               operator.resultsDown{i,1} = i-1;
            end
            initKeys = 0:15;
            initValues = zeros(1, 16);
            operator.timesVisitedAngles = containers.Map(initKeys, initValues);
            
            % set MAA to -1 for now
            operator.uphillMAA = -1;
            operator.downhillMAA = -1;
            
            % set found bool-flags as false
            operator.foundUphill = 0;
            operator.foundDownhill = 0;
            
            operator.trialNum = 1;
            operator.firstSlip = 0;
            operator.firstSlipAngle = 0;
            operator.lastTestedAngle = -1;
            operator.lastResultUphill = '*';
            operator.lastResultDownhill = '*';
            
            operator.tseriesplot = timeseries([], []);
            
            % new
            operator.results = cell(16,10);
            for i=1:16 
               operator.results{i,1} = i-1;
            end
        end
        
        %% Record results for the trial, uphill and downhill are 0/1
        % result == 1 means ok, result == 2 is ok but overwrote
        % anywhere where currAngle is used as an index, shift by +1 since
        % table is not 0-indexed (SHIT)
        function result = recordResults(operator, uphill, downhill)
            operator.lastResultUphill = uphill;
            operator.lastResultDownhill = downhill;
            
            % add the current angle to the time series
            operator.tseriesplot = addsample(operator.tseriesplot, 'Data', operator.currAngle, ...
                'Time', operator.trialNum, 'OverwriteFlag', true);
            
            % times visited
            operator.lastTestedAngle = operator.currAngle;
            operator.timesVisitedAngles(operator.currAngle) = operator.timesVisitedAngles(operator.currAngle) + 1;
            
            fprintf('\n--- Currently at angle %d ---\n', operator.currAngle);
            
            % ??? 
            result = 0;
            alreadyFound = '*';  % in place of NULL,'*', '/'
            % find where to put the uphill entry {3, 5, 7}
            trialCols = [3, 5, 7];
            putHere = 0;
            for col=trialCols
                if isempty(operator.resultsUp{operator.currAngle + 1, col})
                    putHere = col;
                    break;
                end
            end
            
            if putHere == 0
               putHere = 7;
               fprintf('WARNING!!! Overwriting row:%d (angle %d), col:%d...\n', operator.currAngle + 1, operator.currAngle, col);
               result = 1;
            end
            
            % put in the results, uphill and downhill share positions!
            if operator.foundUphill  
                uphill = alreadyFound;
            end
            if operator.foundDownhill
                downhill = alreadyFound;
            end
            
            fprintf('Putting %d into position (row:%d (angle %d), col:%d) for uphill...\n', uphill, operator.currAngle + 1, operator.currAngle, putHere);
            operator.resultsUp{operator.currAngle + 1, putHere} = uphill;
            operator.resultsUp{operator.currAngle + 1, putHere - 1} = operator.trialNum;
            
            fprintf('Putting %d into position (row:%d (angle %d), col:%d) for downhill...\n', downhill, operator.currAngle + 1, operator.currAngle, putHere);
            operator.resultsDown{operator.currAngle + 1, putHere} = downhill;
            operator.resultsDown{operator.currAngle + 1, putHere - 1} = operator.trialNum;
            
            trialCols = [2, 5, 8];
            for col=trialCols
                if isempty(operator.results{operator.currAngle + 1, col})
                    operator.results{operator.currAngle + 1, col} = operator.trialNum;
                    operator.results{operator.currAngle + 1, col + 1} = uphill;
                    operator.results{operator.currAngle + 1, col + 2} = downhill;
                    break;
                end
            end
            
            % new 
            disp(operator.results);
            disp(operator.resultsDown)
            disp(operator.resultsUp)
            
            result = result + 1;  % if 1, its ok! if 2 then we overwrote :(
            operator.trialNum = operator.trialNum + 1;
        end
        
        %% Check for MAA in uphill and downhill. Edge cases are handled when the tipper is adjusted at 0 or 15 degrees
        function [upMAA, downMAA] = checkMAA(operator)
%             entryCols = [3, 5, 7];
            upEntry = [3, 6, 9];
            downEntry = [4, 7, 10];
            
%             % angleIndex - 1 == angle, go from indices 2, 3, 4,... 16 since we check angle (0, 1), (1, 2), ..., (14, 15)
%             for angleIndex=2:operator.MAX_ANGLE+1  
%                 numPassesPriorUp = 0;
%                 numFailsHereUp = 0;
%                 
%                 numPassesPriorDown = 0;
%                 numFailsHereDown = 0;
%                 
%                 % check to break
%                 if (operator.foundUphill) && (operator.foundDownhill)
%                     return
%                 end
%                 
%                 % 2 passes before 2 fails for MAA, check each direction
%                 for col=entryCols
%                    % uphill
%                    if operator.resultsUp{angleIndex - 1, col} == 1
%                        numPassesPriorUp = numPassesPriorUp + 1;
%                    end
%                    if operator.resultsUp{angleIndex, col} == 0
%                        numFailsHereUp = numFailsHereUp + 1;
%                    end
%                    % downhill
%                    if operator.resultsDown{angleIndex - 1, col} == 1
%                        numPassesPriorDown = numPassesPriorDown + 1;
%                    end
%                    if operator.resultsDown{angleIndex, col} == 0
%                        numFailsHereDown = numFailsHereDown + 1;
%                    end
%                end
%                
%                % check if found uphill
%                if (numPassesPriorUp >= 2) && (numFailsHereUp >= 2) && (~operator.foundUphill)
%                    upMAA = angleIndex - 2;  % -1 for the index, -1 for the previous angle (2 fails)
%                    operator.foundUphill = 1;
%                    operator.uphillMAA = angleIndex - 2;
%                    fprintf('FOUND UPHILL MAA at %d\n', operator.uphillMAA);
%                else
%                    upMAA = -1;
%                end
%                
%                % check if found downhill
%                if (numPassesPriorDown >= 2) && (numFailsHereDown >= 2) && (~operator.foundDownhill)
%                    downMAA = angleIndex - 2;  % -1 for the index, -1 for the previous angle (2 fails)
%                    operator.foundDownhill = 1;
%                    operator.downhillMAA = angleIndex - 2;
%                    fprintf('FOUND DOWNHILL MAA at %d\n', operator.downhillMAA);
%                else
%                    downMAA = -1;
%                end
%   
%             end
            
            % angleIndex - 1 == angle, go from indices 2, 3, 4,... 16 since we check angle (0, 1), (1, 2), ..., (14, 15)
            % Need to make an edge case for degree 15 when passing all
            % for angleIndex=2:operator.MAX_ANGLE+1
            % new. might not need (14,15) since a participant can ace the test 
            for angleIndex=2:operator.MAX_ANGLE 
                numPassesPriorUp = 0;
                numFailsHereUp = 0;
                
                numPassesPriorDown = 0;
                numFailsHereDown = 0;
                
                % check to break
                if (operator.foundUphill) && (operator.foundDownhill)
                    return
                end
                
                % 2 passes before 2 fails for MAA, check each direction
                for col=upEntry
                   % uphill
                   if operator.results{angleIndex - 1, col} == 1
                       numPassesPriorUp = numPassesPriorUp + 1;
                   end
                   if operator.results{angleIndex, col} == 0
                       numFailsHereUp = numFailsHereUp + 1;
                   end
                end
                   
               for col=downEntry
                   % downhill
                   if operator.results{angleIndex - 1, col} == 1
                       numPassesPriorDown = numPassesPriorDown + 1;
                   end
                   if operator.results{angleIndex, col} == 0
                       numFailsHereDown = numFailsHereDown + 1;
                   end
               end
               
               % check if found uphill
               if (numPassesPriorUp >= 2) && (numFailsHereUp >= 2) && (~operator.foundUphill)
                   upMAA = angleIndex - 2;  % -1 for the index, -1 for the previous angle (2 fails)
                   operator.foundUphill = 1;
                   operator.uphillMAA = angleIndex - 2;
                   fprintf('FOUND UPHILL MAA at %d\n', operator.uphillMAA);
               else
                   upMAA = -1;
               end
               
               % check if found downhill
               if (numPassesPriorDown >= 2) && (numFailsHereDown >= 2) && (~operator.foundDownhill)
                   downMAA = angleIndex - 2;  % -1 for the index, -1 for the previous angle (2 fails)
                   operator.foundDownhill = 1;
                   operator.downhillMAA = angleIndex - 2;
                   fprintf('FOUND DOWNHILL MAA at %d\n', operator.downhillMAA);
               else
                   downMAA = -1;
               end
  
            end
            
        end
        
        %% Adjust the angle to set number - for TESTING PURPOSES ONLY (doesn't physically move the tipper though)
        function result = MasterAdjustAngle(operator, toAngle, uphill, downhill)
            if toAngle < 0 || toAngle > 15
                result = -1;
                fprintf('toAngle out of range: must be within [0, 15]');
            else
                operator.currAngle = toAngle;
                result = toAngle;
                operator.lastTestedAngle = operator.currAngle;
                operator.timeVisitedAngles(toAngle) = operator.timesVisitedAngles(toAngle) + 1;
                operator.lastResultUphill = uphill;
                operator.lastResultDownhill = downhill;
            end
        end
        
        %% Adjust the angle based on the trial results, return the new angle
%         function adjustAngle(operator, uphill, downhill)
%             % --- dont have either MAA yet           
%             if ~operator.foundUphill && ~operator.foundDownhill
%                 % either 1 or both slip - should go down or stay
%                 if uphill == 0 || downhill == 0
%                     % record first slip angle if not already(bidirectional)
%                     if operator.firstSlip == 0
%                         operator.firstSlipAngle = operator.currAngle;
%                     end
%                     operator.firstSlip = 1;  % set first slip to true
%                     
%                     % IMPOSSIBLE CASE:
%                     % isFull > 0 and full here, since that would imply we have an MAA that we didn't see
%                     % due to the way of how we visit angles 
%                     
%                     % regular cases where we are above 0 degrees
%                     if operator.currAngle - operator.INCREMENT >= operator.MIN_ANGLE
%                         timesVisited = operator.checkAngleFullBoth(operator.currAngle - operator.INCREMENT);
% 
%                         % Case 1: angle - 1 is full so test here again
%                         if timesVisited > 0 && operator.checkAngleFullBoth(operator.currAngle) <= 0
%                             fprintf('Moving to angle %d...\n', operator.currAngle);
%                             return
% 
%                         % Case 2: angle - 1 isn't full, so we go down
%                         else
%                             operator.currAngle = operator.currAngle - operator.INCREMENT;
%                             fprintf('Moving to angle %d...\n', operator.currAngle);
%                             return
%                         end
%                         
%                     % we are at 0 degrees, test here again
%                     else
%                         % check if we are full with 2 fails
%                         timesVisited = operator.timesVisitedAngles(operator.currAngle);
%                             
%                         % Case 1: we are full (3 trials), set downhill MAA
%                         % to 0 regardless (due to lack of info from 2 passes below/2 fails above
%                         % or 2 fails here/unknown 'below')
%                         if timesVisited >= 3
%                             fprintf('we are full at 0 degrees\n');
%                             
%                             operator.uphillMAA = 0;
%                             operator.foundUphill = 1;
%                             operator.currAngle = operator.MIN_ANGLE + 1;
%                             
%                             operator.downhillMAA = 0;
%                             operator.foundDownhill = 1;
%                             operator.currAngle = operator.MIN_ANGLE + 1;
%                             fprintf('3 trials at 0, force terminate\n');
%                             
%                         end
%                         return
%                     end
%                 % both pass - go up
%                 else  
%                     % no slips yet, no need to check if angle + 2 is full
%                     % since it would be the first time we visit it...
%                     if ~operator.firstSlip
%                         if operator.currAngle + operator.INITIAL_INCREMENT > operator.MAX_ANGLE
%                             fprintf('+2 is too much, trying to add +1 instead...\n');
%                             if operator.currAngle + operator.INCREMENT <= operator.MAX_ANGLE
%                                 fprintf('Adding +1 is okay!\n');
%                                 operator.currAngle = operator.currAngle + operator.INCREMENT;
%                             else
%                                 fprintf('Staying at angle 15...\n');
%                             end
%                         else
%                             operator.currAngle = operator.currAngle + operator.INITIAL_INCREMENT; 
%                         end
%                         % if the boot is really good and makes it to 15
%                         % degrees without failing AND passes 2 times
%                         % here, then we set both MAAs as 15. 
%                         if operator.checkAngleFullBoth(operator.MAX_ANGLE) > 0
%                            operator.uphillMAA = operator.MAX_ANGLE;
%                            operator.downhillMAA = operator.MAX_ANGLE;
%                            operator.foundUphill = 1;
%                            operator.foundDownhill = 1;
%                            fprintf('Visited angle 15 3 times with no fails, MAAs are 15!\n');
%                         end
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         
%                         return
%                         
%                     % both pass and already slipped once
%                     else
%                         if operator.currAngle + operator.INCREMENT <= operator.MAX_ANGLE
%                             timesVisited = operator.checkAngleFullBoth(operator.currAngle + operator.INCREMENT);
% 
%                             % Case 1: angle + 1 is full
%                             if timesVisited > 1
%                                 % go to angle + 2, check there again recursively
%                                 operator.currAngle = operator.currAngle + operator.INCREMENT + 1;
%                                 fprintf('Moving to angle %d... angle + 1 is full so we going angle + 2!\n', operator.currAngle);
% 
%                                 operator.adjustAngle(uphill, downhill);
%                             % Case 2: angle + 1 isn't full
%                             else
%                                 operator.currAngle = operator.currAngle + operator.INCREMENT;
%                                 fprintf('Moving to angle %d...\n', operator.currAngle);
% 
%                                 return
%                             end
%                             
%                         % both dirs passed but are already at 15    
%                         elseif operator.currAngle == operator.MAX_ANGLE
%                             % if we visited this angle 3 times, that means
%                             % we have 2 passed for both angles at MAX-1, so
%                             % we set MAAs to 15
%                             if operator.timesVisitedAngles(operator.currAngle) == 3
%                                operator.uphillMAA = operator.MAX_ANGLE;
%                                operator.downhillMAA = operator.MAX_ANGLE;
%                                operator.foundUphill = 1;
%                                operator.foundDownhill = 1;
%                                fprintf('Visited angle 15 3 times with no fails, MAAs are 15!\n');
%                                return
%                             % else, repeat 15
%                             else
%                                 fprintf('Staying at angle 15 for another trial...\n');
%                                 return
%                             end
%                            
%                         end
%                     end
%                 end
%             
%             % --- we didn't find uphill MAA yet, but already have downhill
%             elseif ~operator.foundUphill && operator.foundDownhill  % ignore downhill
%                 if uphill == 0
%                     timesVisited = operator.checkAngleFullDir(operator.currAngle - 1, operator.UP);
%                     % IMPOSSIBLE CASES - enforced by constraints or loop invariant 
%                     % isFull == 1 since cannot currently be lower than a full angle with 2 passes
%                     % isFull == 2 and full here with 2 fails since cannot visit the same angle 3 times and fail >2/3 at adjacent angles
%                     % isFull == 2 and full here with 2 passes since that would imply we found MAA, so we should've terminated
% 
%                     % Case 1: angle - 1 uphill is full with 2 fails, here is not
%                     % full and failed, test here again in case pass
%                     if (timesVisited == 2 && operator.checkAngleFullDir(operator.currAngle, operator.UP) <= 0) || timesVisited == 3
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         return
%   
%                     % Case 2/default: uphill at angle - 1 isn't full
%                     else
%                         operator.currAngle = operator.currAngle - operator.INCREMENT;
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         return
%                     end
%                     
%                 else  % uphill == 1
%                     timesVisited = operator.checkAngleFullDir(operator.currAngle + 1, operator.UP);
%                     fprintf('Looking for next angle for uphill only...\n');
%                     % IMPOSSIBLE CASES - enforced by constraints or loop invariant
%                     % isFull == 1 since cannot currently be lower than a
%                     % full angle with 2 passes  **this is a weird exception
%                     % since it could 1 0 and 1 0 for uphill/downhill...
%                     % isFull == 2 and full here with 2 fails since cannot visit the same angle 3 times and fail >2/3 at adjacent angles
%                     % isFull == 2 and full here with 2 passes since that would imply an MAA found at this angle so the loop would terminate!
%                     
%                     
%                     % Case 1: if uphill's angle + 1 is full with 2 fails and here
%                     % isn't full, test here again
%                     if timesVisited == 2 && operator.checkAngleFullDir(operator.currAngle, operator.UP) <= 0
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         
%                         return
%                         
%                     % Case 2: if uphill has 2 passes at angle+1, go to angle + 2    
%                     elseif timesVisited == 1 || timesVisited == 3
%                         operator.currAngle = operator.currAngle + operator.INCREMENT + 1;
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         
%                         return
%                     
%                     % Case 3: uphill is at 15 degrees and already has 2
%                     % passes for both dirs, set MAA to 15
%                     elseif (operator.currAngle + operator.INCREMENT > operator.MAX_ANGLE) && ...
%                             (operator.checkFullDir(operator.currAngle, operator.UP) == 1 || operator.checkFullDir(operator.currAngle, operator.UP) == 4)
%                         fprintf('ALREADY FULL AND 2 PASSES AT MAX ANGLE, UPHILL MAA SET TO 15\n');
%                         operator.uphillMAA = operator.MAX_ANGLE;
%                         operator.foundUphill = 1;
%                         return
%                     
%                     % Case 4: uphill is at 15 degrees at not full, but passed - test here again. This is the 1 case where we
%                     % can repeat an angle more than 3 times.
%                     elseif (operator.currAngle + operator.INCREMENT > operator.MAX_ANGLE) && (operator.checkFullDir(operator.currAngle, operator.UP) <= 0)
%                         fprintf('Repeating angle 15 since passed at 15...\n');
%                         return
%                         
%                     % Case 4: uphill's at angle + 1 isn't full
%                     else
%                         operator.currAngle = operator.currAngle + operator.INCREMENT;
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         
%                         
%                         return
%                     end
%                 end
%                     
%             
%             % --- we didn't find downhill MAA yet, but already have uphill
%             elseif operator.foundUphill && ~operator.foundDownhill  % ignore uphill
%                 if downhill == 0
%                     timesVisited = operator.checkAngleFullDir(operator.currAngle - 1, operator.DOWN);
%                     % IMPOSSIBLE CASES: isFull == 1 since cannot currently
%                     % be lower than a full angle with 2 passes
%                     
%                     % IMPOSSIBLE CASES: 
%                     % isFull == 1 since cannot currently be lower than a
%                     % full angle with 2 passes **UNLESS we visited with the
%                     % other angle
%                     % isFull == 2 and full here with 2 fails since cannot visit the same angle 3 times and fail >2/3 at adjacent angles
%                     % isFull == 2 and full here with 2 passes since that would imply we found MAA, so we should've terminated
%                     
%                     % Case 1: angle - 1 downhill is full with 2 fails, here is not
%                     % full and failed, test here again in case pass
%                     if timesVisited == 2 && operator.checkAngleFullDir(operator.currAngle, operator.DOWN) <= 0
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         
%                         return
%                     
%                     % Case 2/default: uphill at angle - 1 isn't full
%                     else
%                         operator.currAngle = operator.currAngle - operator.INCREMENT;
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         
%                         return
%                     end
%                     
%                 else  % downhill == 1
%                     timesVisited = operator.checkAngleFullDir(operator.currAngle + 1, operator.DOWN);
%                     % IMPOSSIBLE CASES: 
%                     % isFull == 1 since cannot currently be lower than a
%                     % full angle with 2 passes ** UNLESS we visited with
%                     % the other angle
%                     % isFull == 2 and full here with 2 fails since cannot visit the same angle 3 times and fail >2/3 at adjacent angles
%                     % isFull == 2 and full here with 2 passes since that would imply an MAA found at this angle so the loop would terminate!
%                     
%                     
%                     % Case 1: if downhill's angle + 1 is full with 2 fails and here
%                     % isn't full, test here again
%                     if timesVisited == 2 && operator.checkAngleFullDir(operator.currAngle, operator.DOWN) <= 0
%                         fprintf('Testing at angle %d again...\n', operator.currAngle);
%                         
%                         return
%                         
%                     % Case 2: if downhill has 2 passes at angle+1, go to angle + 2 (as long as it's not full)   
%                     elseif timesVisited == 1 || timesVisited == 3 && operator.currAngle + operator.INCREMENT + 1 < operator.MAX_ANGLE
%                         operator.currAngle = operator.currAngle + operator.INCREMENT + 1;
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         return
%                         
%                     % Case 3: downhill is at 15 degrees and passed, full
%                     % here already with 2 passes
%                     elseif (operator.currAngle + operator.INCREMENT > operator.MAX_ANGLE) && ...
%                             (operator.checkFullDir(operator.currAngle, operator.DOWN) == 1 || operator.checkFullDir(operator.currAngle, operator.DOWN) == 4)
%                         fprintf('ALREADY 3 TRIALS AT 15, UPHILL MAA SET TO 15\n');
%                         operator.uphillMAA = operator.MAX_ANGLE;
%                         operator.foundUphill = 1;
%                         return
%                     
%                     % Case 4: downhill is at 15 degrees at not full, but
%                     % passed - test here again. This is the 1 case where we
%                     % can repeat an angle more than 3 times.
%                     elseif (operator.currAngle + operator.INCREMENT > operator.MAX_ANGLE) && ...
%                             (operator.checkFullDir(operator.currAngle, operator.DOWN) <= 0)
%                         fprintf('Repeating angle 15 since passed at 15...\n');
%                         return
%                         
%                     % Case 5: downhill's at angle + 1 isn't full
%                     else
%                         operator.currAngle = operator.currAngle + operator.INCREMENT;
%                         fprintf('Moving to angle %d...\n', operator.currAngle);
%                         
%                         return
%                     end
%                 end
%             end
%         end

        %% Adjust the angle based on the trial results, return the new angle
        function adjustAngle(operator, uphill, downhill)
            if uphill == 0 || downhill == 0
                % Case 1: (0,0)
                % Case 2: (0,1)
                % Case 3: (1,0)
                % Case 4: (0,*)
                % Case 5: (*,0)
            else
                % Case 6: (1,*)
                if (uphill == 1 && downhill == '*') 
                end
                % Case 7: (*,1)
                if (uphill == '*' && downhill == 1)
                end
                % Case 8: (1,1)
                
            end
        end
        
        %% Check if the current angle is bounded below or above by its adjacent angle or itself
        function result = bounded(operator, direction, angle, inequalitySign)
            
            fileNumCols = [2, 5, 8];
            % Bounded below <= and UP
            if strcmp(inequalitySign, '<=') && direction == Opeator.UP
                if angle == 15
                        result = 1;
                        return 
                end
                for file = fileNumCols
                    if operator.results{angle + 1, file} && operator.results{angle + 1, file + 1} == 0
                        counter1 = operator.results{angle + 1, file + 1};
                    end
%                     if operator.results{angle + 2, file} && operator.results{angle + 2, file + 1} == 0
%                         counter2 = operator.results{angle + 2, file + 1};    
%                     end
%                     if counter1 >= 2 || counter2 >= 2
                    if counter1 >= 2
                        result = 1;
                        return
                    end
                end
            end

            % Bounded below <= and DOWN  
            if strcmp(inequalitySign, '<=') && direction == Opeator.DOWN
                if angle == 15
                        result = 1;
                        return 
                end
                for file = fileNumCols
                    if operator.results{angle + 1, file} && operator.results{angle + 1, file + 2} == 0
                        counter1 = operator.results{angle + 1, file + 2};
                    end
%                     if operator.results{angle + 2, file} && operator.results{angle + 2, file + 2} == 0
%                         counter2 = operator.results{angle + 2, file + 2};    
%                     end
%                     if counter1 >= 2 || counter2 >= 2
                    if counter1 >= 2
                        result = 1;
                        return
                    end
                end
            end 
            % Bounded above >= and UP
            if strcmp(inequalitySign, '>=') && direction == Opeator.UP
                if angle == 0
                        result = 1;
                        return 
                end
                for file = fileNumCols
                    if operator.results{angle + 1, file} && operator.results{angle + 1, file + 1} == 1
                        counter1 = operator.results{angle + 1, file + 1};
                    end
%                     if operator.results{angle, file} && operator.results{angle, file + 1} == 1
%                         counter2 = operator.results{angle, file + 1};    
%                     end
%                     if counter1 >= 2 || counter2 >= 2
                    if counter1 >= 2
                        result = 1;
                        return
                    end
                end
            end
            % Bounded above >= and DOWN
            if strcmp(inequalitySign, '>=') && direction == Opeator.DOWN
                if angle == 0
                        result = 1;
                        return 
                end
                for file = fileNumCols
                    if operator.results{angle + 1, file} && operator.results{angle + 1, file + 2} == 1
                        counter1 = operator.results{angle + 1, file + 2};
                    end
%                     if operator.results{angle, file} && operator.results{angle, file + 2} == 1
%                         counter2 = operator.results{angle, file + 2};    
%                     end
%                     if counter1 >= 2 || counter2 >= 2
                    if counter1 >= 2
                        result = 1;
                        return
                    end
                end
            end
        end
        
        %% Iterate over to find next angle 
        function result = nextAngleHellper (operator, direction, angle, inequalitySign)
        end
        
        %% Helper - checkFirstSlipAngle -> return the angle where the first slip happens
        function checkFirstSlipAngle(operator)
        % fileNumCols = [2, 5, 8];
            temp = [];
            if ~operator.firstSlip
                for row = 1:16
                    if operator.results{row, 2}
                        temp = [temp; operator.results(row, 2:4)];
                    end
                    if operator.results{row, 5}
                        temp = [temp; operator.results(row, 5:7)];
                    end
                    if operator.results{row, 8}
                        temp = [temp; operator.results(row, 8:10)];
                    end
                end
                
                for trial = 1:size(temp)
                    if ~temp{trial,2} || ~temp{trial,3}
                        operator.firstSlipAngle = cell2mat(temp(trial,1));
                        operator.firstSlip = 1;
                        break
                    end
                end
            end
        end   
        
        %% Helper - checkAngleFullBoth -> return > 0 if the angle should be skipped, checks both directions
        % isFull == 1 means 3 trials, 2 passes for both
        % isFull == 2 means 3 trials, 2 fails for up, 2 passes for down
        % isFull == 3 means 3 trials, 2 fails for down, 2 passes for up
        % isFull == 4 means 2 trials, but both pass
        % isFull == 0 means less than 3 trials
        % IF isFull > 0, it is FULL!
        function isFull = checkAngleFullBoth(operator, angle)
            isFull = -1;
            % check if full - 3 trials
            uphillContents = [operator.resultsUp{angle+1, 3}, operator.resultsUp{angle+1, 5}, operator.resultsUp{angle+1, 7}];
            downhillContents = [operator.resultsDown{angle+1, 3}, operator.resultsDown{angle+1, 5}, operator.resultsDown{angle+1, 7}];
            % find all occurences of 1s and 0s for the angle
            upPassOccurs = length(find(uphillContents==1));
            upFailOccurs = length(find(uphillContents==0));
            downPassOccurs = length(find(downhillContents==1));
            downFailOccurs = length(find(downhillContents==0));
            
            if operator.timesVisitedAngles(angle) == 3
                if upPassOccurs >= 2 && downPassOccurs >= 2
                    isFull = 1;
                    fprintf('Angle %d IS FULL! Case: 3 trials, >=2 passes for both dirs.\n', angle);
                    return
                elseif upFailOccurs >= 2 && downPassOccurs >= 2
                    isFull = 2;
                    fprintf('Angle %d IS FULL! Case: 3 trials, 2 fails for up, 2 passes for down.\n', angle);
                    return
                elseif downFailOccurs >= 2 && upPassOccurs >= 2
                    isFull = 3;
                    fprintf('Angle %d IS FULL! Case: 3 trials, 2 fails for down, 2 passes for up.\n', angle);
                    return
                end
            elseif operator.timesVisitedAngles(angle) == 2 && upPassOccurs >= 2 && downPassOccurs >= 2
                isFull = 4;
                fprintf('Angle %d IS FULL! Case: 2 trials, both passes up and down.\n', angle);
                return
                
            else
                isFull = 0;
                fprintf('Angle %d is NOT FULL!\n', angle);
                return
            end
        end
        
        %% Helper - checkAngleFull -> return >0 if the angle should be skipped
        % PRECONDITION: DIR = {'UP', 'DOWN'}
        % isFull == 1 means 3 trials, 2 passes for the dir
        % isFull == 2 means 3 trials, 2 fails for the dir
        % isFull == 3 means 2 trials, 2 passes for the dir
        % isFull == 0 means less than 3 trials
        % IF isFull > 0, it is FULL!
        function isFull = checkAngleFullDir(operator, angle, DIR)
            % error checking 
            if strcmp(DIR, operator.UP)
                % if full with 3 trials
                uphillContents = [operator.resultsUp{angle+1, 3}, operator.resultsUp{angle+1, 5}, operator.resultsUp{angle+1, 7}];
                
                % find all occurences of 1s and 0s for the angle
                upPassOccurs = length(find(uphillContents==1));
                upFailOccurs = length(find(uphillContents==0));
                
                if operator.timesVisitedAngles(angle) == 3
                    % 2 passes at this angle
                    if upPassOccurs >= 2
                        isFull = 1;
                        fprintf('Angle %d IS FULL! Case: 3 trials, >=2 passes for the dir.\n', angle);
                    elseif upFailOccurs >= 2
                        isFull = 2;
                        fprintf('Angle %d IS FULL! Case: 3 trials, >=2 fails for the dir.\n', angle);
                    else
                        fprintf('isFull - uphill - shouldnt be here!\n');
                    end
                elseif operator.timesVisitedAngles(angle) == 2 && upPassOccurs >= 2
                    isFull = 3;
                    fprintf('Angle %d IS FULL! Case: 2 trials, >=2 passes for the dir.\n', angle);
                    return
                else
                    isFull = 0;
                    fprintf('Angle %d is NOT FULL!\n', angle);
                end
                
            elseif strcmp(DIR, operator.DOWN)  % DIR == DOWN
                downhillContents = [operator.resultsDown{angle+1, 3}, operator.resultsDown{angle+1, 5}, operator.resultsDown{angle+1, 7}];
                
                % count 1s and 0s for the angle for downhill
                downPassOccurs = length(find(downhillContents==1));
                downFailOccurs = length(find(downhillContents==0));
                
                % if full with 3 trials
                if operator.timesVisitedAngles(angle) == 3
                    % 2 passes at this angle
                    if downPassOccurs >= 2
                        isFull = 1;
                        fprintf('Angle %d IS FULL! Case: 3 trials, >=2 passes for the dir.\n', angle);
                    elseif downFailOccurs >= 2
                        isFull = 2;
                        fprintf('Angle %d IS FULL! Case: 3 trials, >=2 fails for the dir.\n', angle);
                    else
                        fprintf('isFull - uphill - shouldnt be here!\n');
                    end
                elseif operator.timesVisitedAngles(angle) == 2 && downPassOccurs >= 2
                    isFull = 3;
                    fprintf('Angle %d IS FULL! Case: 2 trials, >=2 passes for the dir.\n', angle);
                else
                    isFull = 0;
                    fprintf('Angle %d is NOT FULL!\n', angle);
                end
                
            % param check
            else
               fprintf('WARNING: UP OR DOWN DOES NOT MATCH THE ATTRIBUTE UP/DOWN: %s | setting isFull to -1...\n', DIR);
               isFull = 0;
            end
            
        end
        
        %% checks MAA up/down flags for termination
        function result = checkTermination(operator)
            result = 0;
            if operator.foundDownhill && operator.foundUphill
                result = 1;
            end
        end
        
        %% broadcast to any listeners that we modified oper8or
        function notifyListeners(operator)
            % add the updated angle to the time series
            operator.tseriesplot = addsample(operator.tseriesplot, 'Data', operator.currAngle, ...
                'Time', operator.trialNum, 'OverwriteFlag', true);
            
            notify(operator,'dataChanged'); %Notify event (and anything listening), that the selected data has changed
        end
        
        %% Export the data into rows for an excel spreadsheet
        function sessionData = exportDataCells(operator)
            p = operator.session.participant;
            s = operator.session;
            
            sessionData = {p.ID p.ID 'N/A' 'N/A' 'N/A' s.footwearID p.sex p.size 'N/A' s.walkway 'N/A' '' operator.uphillMAA operator.downhillMAA operator.firstSlipAngle ...
                s.preslip s.slipperiness s.thermal s.fit s.heaviness s.overall s.easeWearing s.useInWinter 'N/A' s.observer 'N/A' s.date s.time s.airTemp s.iceTemp s.humidity};
        end
    end
end

