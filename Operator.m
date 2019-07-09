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
%             disp(operator.resultsDown)
%             disp(operator.resultsUp)
            
            result = result + 1;  % if 1, its ok! if 2 then we overwrote :(
            operator.trialNum = operator.trialNum + 1;
        end
        
        %% Check for MAA in uphill and downhill. Edge cases are handled when the tipper is adjusted at 0 or 15 degrees
        function [upMAA, downMAA] = checkMAA(operator)

            upEntry = [3, 6, 9];
            downEntry = [4, 7, 10];
            
            % angleIndex - 1 == angle, go from indices 2, 3, 4,... 16 since we check angle (0, 1), (1, 2), ..., (14, 15)
            % Need to make an edge case for degree 15 when passing all
            % for angleIndex=2:operator.MAX_ANGLE+1
            % new. might not need (14,15) since a participant can ace the test 
            for angleIndex=2:operator.MAX_ANGLE + 1
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
            
            % check edge cases
            % at angle 0 or 15
            numPassesUp = 0;
            numPassesDown = 0;
            numFailsUp = 0;
            numFailsDown = 0;
            
            if operator.currAngle == 15
                for col=upEntry
                    % uphill
                    if operator.results{16, col} == 1
                        numPassesUp = numPassesUp + 1;
                    if numPassesUp >= 2
                        operator.foundUphill = 1;
                        operator.uphillMAA = 15;
                    end
                    end
                end
                for col = downEntry
                    % downhill
                    if operator.results{16, col} == 1
                        numPassesDown = numPassesDown + 1;
                    if numPassesDown >= 2
                        operator.foundDownhill = 1;
                        operator.downhillMAA = 15;
                    end
                    end
                end
            end

            if operator.currAngle == 0 
                for col=upEntry
                    % uphill
                    if operator.results{1, col} == 0
                        numFailsUp = numFailsUp + 1;
                    if numFailsUp >= 2
                        operator.foundUphill = 1;
                        operator.uphillMAA = 0;
                    end
                    end
                end
                for col = downEntry
                    % downhill
                    if operator.results{1, col} == 0
                        numFailsDown = numFailsDown + 1;
                    if numFailsUp >= 2
                        operator.foundDownhill = 1;
                        operator.downhillMAA = 0;
                    end
                    end
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
        function adjustAngle(operator, uphill, downhill)
            operator.checkFirstSlipAngle;
            operator.checkMAA;
            if uphill == 0 || downhill == 0
                % Case 1: (0,0)
                if (uphill == 0 && downhill == 0)
                   if ~(operator.bounded('UP','below',operator.currAngle - 1) && operator.bounded('DOWN','below',operator.currAngle - 1))
                         operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                end
                % Case 2: (0,1)
                if (uphill == 0 && downhill == 1) || (uphill == 1 && downhill == 0)
                    if operator.foundDownhill
                        if operator.searchBoundedBelowAngle('UP')
                            uphillBoundedAngle = operator.searchBoundedBelowAngle('UP');
                            operator.currAngle = operator.nextAngleHelper(uphillBoundedAngle + 1, 'non-decreasing');
                        else
                            operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                        end
                    elseif operator.foundUphill
                         if operator.searchBoundedBelowAngle('DOWN')
                            downhillBoundedAngle = operator.searchBoundedBelowAngle('DOWN');
                            operator.currAngle = operator.nextAngleHelper(downhillBoundedAngle + 1, 'non-decreasing');
                         else
                            operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                         end
                    else
                        if operator.bounded('UP','below',operator.currAngle - 1) && operator.bounded('DOWN','below',operator.currAngle - 1)
                            operator.currAngle = operator.nextAngleHelper(operator.currAngle, 'non-decreasing');
                        else
                            operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                        end
                    end
                end
%                 % Case 3: (1,0)
%                 if (uphill == 1 && downhill == 0)
%                     if operator.foundUphill
%                         downhillBoundedAngle = operator.searchBoundedBelowAngle('DOWN');
%                         operator.currAngle = operator.nextAngleHelper(downhillBoundedAngle + 1, 'non-decreasing');
%                     elseif operator.foundDownhill
%                         uphillBoundedAngle = operator.searchBoundedBelowAngle('UP');
%                         operator.currAngle = operator.nextAngleHelper(uphillBoundedAngle + 1, 'non-decreasing');
%                     else
%                         if operator.bounded('UP','below',operator.currAngle - 1) && operator.bounded('DOWN','below',operator.currAngle - 1)
%                             operator.currAngle = operator.nextAngleHelper(operator.currAngle, 'non-decreasing');
%                         else
%                              operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
%                         end
%                     end
%                 end
                % Case 4: (*,0)
                if (uphill == '*' && downhill == 0)
                   if ~(operator.bounded('DOWN','below',operator.currAngle - 1))
                         operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                end
                % Case 5: (0,*)
                if (uphill == 0 && downhill == '*')
                   if ~(operator.bounded("UP",'below',operator.currAngle - 1))
                         operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                end
            else
                %  Case 6: (1,*) 
                if (uphill == 1 && downhill == '*') 
                    if ~operator.bounded('UP','above',operator.currAngle + 1)
                         operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1,'non-decreasing');
                    end
                end
                % Case 7: (*,1)
                if (uphill == '*' && downhill == 1) 
                    if ~operator.bounded('DOWN','above',operator.currAngle + 1)
                         operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                    end
                end
                % Case 8: (1,1)
                if (uphill == 1 && downhill == 1)
                    if operator.firstSlip
                        if ~(operator.bounded('UP','above', operator.currAngle + 1) && operator.bounded('DOWN','above',operator.currAngle + 1))
                            operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                        end
                    else 
                        if operator.currAngle + 2 <= 15
                            operator.currAngle = operator.currAngle + 2;
            
                        end
                    end
                end
            end
        end
        
        %% Check if the current angle is bounded below or above by its adjacent angle or itself
        function result = bounded(operator, direction, position, angle)
            
            fileNumCols = [2, 5, 8];
            % Bounded above >= and UP
            result = 0;
            counter1 = 0;
            if (strcmp(position, 'above') && (strcmp(direction, operator.UP)))
                if operator.currAngle == 15
                   result = 1;
                   return 
                end
                for file = fileNumCols
                    if ~isempty(operator.results{angle + 1, file}) && operator.results{angle + 1, file + 1} == 0
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
            if strcmp(position, 'above') && strcmp(direction, operator.DOWN)
                if operator.currAngle == 15
                   result = 1;
                   return 
                end
                for file = fileNumCols
                    if ~isempty(operator.results{angle + 1, file}) && operator.results{angle + 1, file + 2} == 0
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
            % Bounded below < and UP
            if strcmp(position, 'below') && strcmp(direction, operator.UP)
                if operator.currAngle == 0
                   result = 1;
                   return 
                end
                for file = fileNumCols
                    if ~(isempty(operator.results{angle + 1, file})) && operator.results{angle + 1, file + 1} == 1
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
            % Bounded below < and DOWN
            if strcmp(position, 'below') && strcmp(direction, operator.DOWN)
                if operator.currAngle == 0
                   result = 1;
                   return 
                end
                for file = fileNumCols
                    if ~isempty(operator.results{angle + 1, file}) && operator.results{angle + 1, file + 2} == 1
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
        function result = nextAngleHelper (operator, angle, position)
            fileNumCols = [2, 5, 8];
            result = 0;
            % find less than or equal to <=
            if strcmp(position, 'non-increasing')
                for i = angle+1:-1:1
                    for file = fileNumCols
                        if isempty(operator.results{i, file})
                            result = i - 1; 
                            return
                        end
                    end
                    
                end
            end
            % find greater than or equal to >=
            if strcmp(position, 'non-decreasing')
                for i = angle+1:16
                    for file = fileNumCols
                        if isempty(operator.results{i, file})
                            result = i - 1; 
                            return
                        end
                    end
                end
            end
        end
        
        %% Helper - checkFirstSlipAngle -> modify releated properties where the first slip happens
        function checkFirstSlipAngle(operator)
%             temp = [];
            
            if ~operator.firstSlip
                for i = 1:operator.trialNum
                    for angleIndex = 1:16
                        for file = [2,5]
                            if i == operator.results{angleIndex,file}
                                if ~operator.results{angleIndex,file+1} || ~operator.results{angleIndex,file+2}
                                    operator.firstSlipAngle = operator.results{angleIndex,1};
                                    operator.firstSlip = 1;
                                end
                            end
                        end
                    end
                end
            end
                
%                 length = size(temp, 2);
%                 for file = 1:4:length
%                     if ~temp{file+2} || ~temp{file+3}
%                         operator.firstSlipAngle = temp{file};
%                         operator.firstSlip = 1;
%                         break
%                     end
%                 end
%             end
        end   
        
        %% Helper - searchBoundedBelowAngle -> find greatest angle that has two 1s
        function result = searchBoundedBelowAngle(operator, direction)
            result = 0;
            fileNumCols = [2, 5, 8];
            if strcmp(direction, 'UP')
                for i = 16:-1:1
                    counter = 0;
                    for file = fileNumCols
                        if operator.results{i,file + 1} == 1
                            counter = counter + 1; 
                            if counter >= 2
                                result = i-1;
                                return 
                            end
                        end
                    end
                end
            end
            if strcmp(direction, 'DOWN')
                for i = 16:-1:1
                    counter = 0;
                    for file = fileNumCols
                        if operator.results{i,file + 2} == 1
                            counter = counter + 1; 
                            if counter >= 2
                                result = i-1;
                                return 
                            end
                        end
                    end
                end
            end
        end
            
        %% checkAngleFullBoth -> return > 0 if the angle should be skipped, checks both directions
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

