classdef Operator <  matlab.mixin.Copyable 
    %   Operator - an abstracted tipper operator object (Model)
    %   Tipper properties during the MAA experiment
    
    %   Initally created by Norman
    %   Largely modified and improved by Kent 
    
    %   Very first script stored in I:\winterlab\footwear database\old files\AutomatedDigitizing\GUI\gui
    %   Coding logic embedded in the GUIs is messy, pending to be restructured and refactored
    %   Class Operator should be the core algorithm being rewritten, if the testing protocol is changed
    %   Such dependency should be eliminated
    
    properties
        % session  % contains participant and all other session goodies
        currAngle % start at 3!
        timesVisitedAngles  % hash map of angle -> # times visited
        predictedAngle % Suggested angle to go
        
        results % table of results for all trails 
        
        uphillMAA  % holds uphill MAA
        downhillMAA  % holds downhill MAA
        
        % boolean flags for found MAAs
        foundUphill  % flag for uphill MAA found
        foundDownhill % flag for downhill MAA found
        trialNum  % record trial number
        firstSlip % first slip flag
        firstSlipAngle % where the first slip was located
        lastTestedAngle % the last angle where we just tested 
        lastResultUphill % previously visited angle for uphill
        lastResultDownhill % previously visited angle for downhill
        
        % tseriesplot % container for time series data
    end
    
    properties(Constant)
        % directions
        UP='UP'  % up direction macro
        DOWN='DOWN'  % down direction macro
    end
    
    methods
        %% Constructor, take in session object info
        function operator = Operator()
            % initial angle is 3
            operator.currAngle = 3; 
            operator.predictedAngle = 3; 

            % A container recording times of visted angles 
            initKeys = 0:15;
            initValues = zeros(1, 16);
            operator.timesVisitedAngles = containers.Map(initKeys, initValues); 
            
            % set MAA to -1 for now
            operator.uphillMAA = -1;
            operator.downhillMAA = -1;
            
            % set found bool-flags as false
            operator.foundUphill = 0;
            operator.foundDownhill = 0;
            
            % Basic flags and counter
            operator.trialNum = 1;
            operator.firstSlip = 0;
            operator.firstSlipAngle = -1;
            operator.lastTestedAngle = 0;
            operator.lastResultUphill = '*';
            operator.lastResultDownhill = '*';
            
            % The underlying MAA table whose first column as angle index
            % Table is in form of cell matrix, as inputs have different data types, which are 0, 1 amd '*'
            % May consider using another integer value to replace '*' 
            % Then Table can be treated as general matrix of integers
            % Syntax might be cleaner, and reduce time complexity this way?
            
            operator.results = cell(16,10);
            for i=1:16 
               operator.results{i,1} = i-1;
            end
        end
        
        %% Record results for the trial, uphill and downhill are 0/1
        function recordResults(operator, uphill, downhill)
            
            operator.lastResultUphill = uphill;
            operator.lastResultDownhill = downhill;
            
            % times visited
            operator.lastTestedAngle = operator.currAngle;
            operator.timesVisitedAngles(operator.currAngle) = ...
                operator.timesVisitedAngles(operator.currAngle) + 1;
            
            fprintf('\n--- Currently at angle %d ---\n', operator.currAngle);
            
            % Enter results in MAA table
            trialNumColss = [2, 5, 8];
            for col=trialNumColss
                if isempty(operator.results{operator.currAngle + 1, col})
                    operator.results{operator.currAngle + 1, col} = operator.trialNum;
                    operator.results{operator.currAngle + 1, col + 1} = uphill;
                    operator.results{operator.currAngle + 1, col + 2} = downhill;
                    break;
                end
            end
            
            % disp method just for debugging purpose
            % disp(operator.results);
        end
        
        %% Check for MAA in uphill and downhill. Edge cases are handled for 0 or 15 degrees
        function checkMAA(operator)

            upEntry = [3, 6, 9];
            downEntry = [4, 7, 10];
            
            % General case: check adjacent angles 
            % angleIndex - 1 == angle, go from indices 2, 3, 4,... 16 since we check angle (0, 1), (1, 2), ..., (14, 15)
            % See if two passes for the latter and two fails for the former
            % Edge case: when currAng = 15 or 0, additional check required
            % See if two passes at 15 or two fails at 0
            
            acc0 = 0;
            acc15 = 0;
            
            % ----- UPHILL
            for col = upEntry
                if operator.results{1,col} == 0
                    acc0 = acc0 + 1;
                end
                if operator.results{16,col} == 1
                    acc15 = acc15 + 1;
                end
            end
            
            % base case 1: MAA 0 --> 2 fails at 0
            if acc0 >= 2
                operator.uphillMAA = 0; 
                operator.foundUphill = 1;

            % base case 2: MAA 15 --> 2 passes at 15
            elseif acc15 >= 2
                operator.uphillMAA = 15;
                operator.foundUphill = 1;

            else
                % general case: iteratively search for 2 passes behind 2 fails
                for angleIndex = 1 : 15
                    accCurrent = 0;
                    accNext = 0;
                    for col = upEntry
                        if operator.results{angleIndex,col} == 1
                            accCurrent = accCurrent + 1;
                        end
                        if operator.results{angleIndex + 1,col} == 0
                            accNext = accNext + 1;
                        end
                        % 2 passes here and 2 fails above
                        if accCurrent >= 2 && accNext >= 2
                            operator.uphillMAA = angleIndex - 1;
                            operator.foundUphill = 1;
                        end
                        if accCurrent >= 2 && accNext < 2
                            operator.uphillMAA = -1;
                            operator.foundUphill = 0;
                        end
                    end 
                end
            end
            
            acc0 = 0;
            acc15 = 0;
            
            % ----- DOWNNHILL
            for col = downEntry
                if operator.results{1,col} == 0
                    acc0 = acc0 + 1;
                end
                if operator.results{16,col} == 1
                    acc15 = acc15 + 1;
                end
            end
            
            % base case 1: MAA 0 --> 2 fails at 0
            if acc0 >= 2
                operator.downhillMAA = 0; 
                operator.foundDownhill = 1;

            % base case 2: MAA 15 --> 2 passes at 15
            elseif acc15 >= 2
                operator.downhillMAA = 15;
                operator.foundDownhill = 1;

            else
                % general case: iteratively search for 2 passes behind 2 fails
                for angleIndex = 1 : 15
                    accCurrent = 0;
                    accNext = 0;
                    for col = downEntry 
                        if operator.results{angleIndex,col} == 1
                            accCurrent = accCurrent + 1;
                        end
                        if operator.results{angleIndex + 1,col} == 0
                            accNext = accNext + 1;
                        end
                        % 2 passes here and 2 fails above
                        if accCurrent >= 2 && accNext >= 2
                            operator.downhillMAA = angleIndex - 1;
                            operator.foundDownhill = 1;
                        end
                        if accCurrent >= 2 && accNext < 2
                            operator.downhillMAA = -1;
                            operator.foundDownhill = 0;
                        end
                    end 
                end
            end
        end

        %% Adjust the angle based on the trial results, return the new angle
        function adjustAngle(operator, uphill, downhill)
            operator.checkFirstSlipAngle;
            operator.checkMAA();
            operator.trialNum = operator.trialNum + 1; % Update counter
            
            % Case 1: (0,0)
            if (uphill == 0 && downhill == 0)
                
                if operator.foundDownhill
                    [foundBoundedBelowAngle, uphillBoundedAngle] = operator.searchBoundedBelowAngle('UP');
                    if foundBoundedBelowAngle && uphillBoundedAngle >= operator.currAngle
                        operator.currAngle = operator.nextAngleHelper(uphillBoundedAngle + 1, 'non-decreasing');
                    elseif (operator.bounded('UP','below',operator.currAngle - 1))
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle, 'non-increasing');
                    else
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                    
                elseif operator.foundUphill                    
                    [foundBoundedBelowAngle, downhillBoundedAngle] = operator.searchBoundedBelowAngle('DOWN');
                    if foundBoundedBelowAngle && downhillBoundedAngle >= operator.currAngle
                       operator.currAngle = operator.nextAngleHelper(downhillBoundedAngle + 1, 'non-decreasing');
                    elseif (operator.bounded('DOWN','below',operator.currAngle - 1))
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle, 'non-increasing');
                    else
                       operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end  
                    
                elseif ~(operator.bounded('UP','below',operator.currAngle - 1) && operator.bounded('DOWN','below',operator.currAngle - 1))
                    operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    
                end
          
            end
            
            % Case 2: (0,1) 
            if (uphill == 0 && downhill == 1) 
                if operator.foundDownhill
                    [foundBoundedBelowAngle, uphillBoundedAngle] = operator.searchBoundedBelowAngle('UP');
                    if foundBoundedBelowAngle && uphillBoundedAngle >= operator.currAngle
                        operator.currAngle = operator.nextAngleHelper(uphillBoundedAngle + 1, 'non-decreasing');
                    elseif (operator.bounded('UP','below',operator.currAngle - 1))
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle, 'non-increasing');
                    else
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                    
                elseif operator.foundUphill
                    [foundBoundedBelowAngle, downhillBoundedAngle] = operator.searchBoundedBelowAngle('DOWN');
                    if foundBoundedBelowAngle && downhillBoundedAngle >= operator.currAngle
                        operator.currAngle = operator.nextAngleHelper(downhillBoundedAngle + 1, 'non-decreasing');
                    else
                        % 'non-increasing' and 'non-decreasing' may not matter here
                        % as there should be an empy trial for currAngle - 1
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                    end
                    
                else
                    if operator.bounded('UP','below',operator.currAngle - 1) && operator.bounded('DOWN','below',operator.currAngle - 1)
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle, 'non-decreasing');
                    elseif operator.bounded('UP','below',operator.currAngle) && operator.bounded('DOWN','below',operator.currAngle)
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                    else
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                end
            end
            
            % Case 3:(1,0)
            if (uphill == 1 && downhill == 0)
                if operator.foundDownhill
                    [foundBoundedBelowAngle, uphillBoundedAngle] = operator.searchBoundedBelowAngle('UP');
                    if foundBoundedBelowAngle && uphillBoundedAngle >= operator.currAngle
                        operator.currAngle = operator.nextAngleHelper(uphillBoundedAngle + 1, 'non-decreasing');
                    else
                        % 'non-increasing' and 'non-decreasing' may not matter here 
                        % as there should be an empy trial for currAngle - 1
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                    end
                    
                elseif operator.foundUphill
                    [foundBoundedBelowAngle, downhillBoundedAngle] = operator.searchBoundedBelowAngle('DOWN');
                    if foundBoundedBelowAngle && downhillBoundedAngle >= operator.currAngle
                        operator.currAngle = operator.nextAngleHelper(downhillBoundedAngle + 1, 'non-decreasing');
                    elseif (operator.bounded('DOWN','below',operator.currAngle - 1))
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle, 'non-increasing');
                    else
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                    
                else
                    if operator.bounded('UP','below',operator.currAngle - 1) && operator.bounded('DOWN','below',operator.currAngle - 1)
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle, 'non-decreasing');
                    elseif operator.bounded('UP','below',operator.currAngle) && operator.bounded('DOWN','below',operator.currAngle)
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                    else
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                end
            end
            
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
                    
                    if operator.foundDownhill
                        [foundBoundedBelowAngle, uphillBoundedAngle] = operator.searchBoundedBelowAngle('UP');
                        if foundBoundedBelowAngle && uphillBoundedAngle >= operator.currAngle
                            operator.currAngle = operator.nextAngleHelper(uphillBoundedAngle + 1, 'non-decreasing');
                        else
                            operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                        end
                    
                    elseif operator.foundUphill
                        [foundBoundedBelowAngle, downhillBoundedAngle] = operator.searchBoundedBelowAngle('DOWN');
                        if foundBoundedBelowAngle && downhillBoundedAngle >= operator.currAngle
                            operator.currAngle = operator.nextAngleHelper(downhillBoundedAngle + 1, 'non-decreasing');
                        else
                            operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                        end
                    
                    elseif ~(operator.bounded('UP','above', operator.currAngle + 1) && operator.bounded('DOWN','above',operator.currAngle + 1))
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                        
                    end
                 
                else
     
                    if operator.currAngle + 2 <= 15
                        operator.currAngle = operator.currAngle + 2;
                    end
                    
                end
            end
            
            operator.predictedAngle = operator.currAngle;
            
            if ~operator.checkTermination
                fprintf('Next angle: %d', operator.predictedAngle);
            end
            
            operator.checkMAA();
        
            disp(operator.results)
            
            fprintf('\nUpMAA = %d, DownMAA = %d\n', operator.uphillMAA, operator.downhillMAA);
        end
       
        %% Check if the current angle is bounded below or above by the given angle
        function result = bounded(operator, direction, position, angle)
            
            % AngleIndex - 1 = Angle            
            trialNumCols = [2, 5, 8];
            result = 0;
            acc = 0;
            
            % Bounded above and UP looking for 2 fails at the given angle at uphill   
            if (strcmp(position, 'above') && (strcmp(direction, operator.UP)))
                % Angle 15 is bounded above for sure
                if operator.currAngle == 15 
                   result = 1;
                   return 
                end
                for trial = trialNumCols
                    % Check if trial is blank 
                    if ~isempty(operator.results{angle + 1, trial}) && operator.results{angle + 1, trial + 1} == 0
                        acc = acc + 1;
                    end
                    if acc >= 2
                        result = 1;
                        return
                    end
                end
            end

            % Bounded above and DOWN ie. looking for 2 fails at the given angle at downhill   
            if strcmp(position, 'above') && strcmp(direction, operator.DOWN)
                % Angle 15 is bounded above for sure
                if operator.currAngle == 15
                   result = 1;
                   return 
                end
                for trial = trialNumCols
                    % Check if trial is blank 
                    if ~isempty(operator.results{angle + 1, trial}) && operator.results{angle + 1, trial + 2} == 0
                        acc = acc + 1;
                    end
                    if acc >= 2
                        result = 1;
                        return                     
                    end
                end
            end 
            
            % Bounded below and UP ie. looking for 2 passes at the given angle at uphill 
            if strcmp(position, 'below') && strcmp(direction, operator.UP)
                % Angle 0 is bounded below for sure
                if operator.currAngle == 0
                   result = 1;
                   return 
                end
                for trial = trialNumCols
                    % Check if trial is blank 
                    if ~(isempty(operator.results{angle + 1, trial})) && operator.results{angle + 1, trial + 1} == 1
                        acc = acc + 1;
                    end
                    if acc >= 2
                        result = 1;
                        return                        
                    end
                end
            end
            
            % Bounded below and DOWN ie. looking for 2 passes at the given angle at downhill 
            if strcmp(position, 'below') && strcmp(direction, operator.DOWN)
                if operator.currAngle == 0
                   result = 1;
                   return 
                end
                for trial = trialNumCols
                    % Check if trial is blank 
                    if ~isempty(operator.results{angle + 1, trial}) && operator.results{angle + 1, trial + 2} == 1
                        acc = acc + 1;
                    end
                    if acc >= 2
                        result = 1;
                        return                        
                    end
                end
            end
        end
        
        %% Iterate over to find next angle 
        function result = nextAngleHelper (operator, angle, position)
            trialNumCols = [2, 5, 8];
            result = 0;
            
            if angle == 16
                angle = 15;
            end
            if angle == -1
                angle = 0;
            end
            
            % find an angle that is less than or equal to <=
            if strcmp(position, 'non-increasing')
                for i = angle+1:-1:1
                    for trial = trialNumCols
                        if isempty(operator.results{i, trial})
                            result = i - 1; 
                            return
                        end
                    end
                end
            end
            % find an angle that is greater than or equal to >=
            if strcmp(position, 'non-decreasing')
                for i = angle+1:16
                    for trial = trialNumCols
                        if isempty(operator.results{i, trial})
                            result = i - 1; 
                            return
                        end
                    end
                end
            end
        end
        
        %% Helper - checkFirstSlipAngle -> modify releated properties where the first slip happens
        function checkFirstSlipAngle(operator)
            % Starting with trialNum in an ascending order to find the first slip ever
            % Nested block 
            % Need to refactor
            if ~operator.firstSlip
                for i = 1:operator.trialNum
                    for angleIndex = 1:16
                        for trial = [2,5] % No need to check 3rd trial for each angle
                            if i == operator.results{angleIndex,trial}
                                if ~operator.results{angleIndex,trial+1} || ~operator.results{angleIndex,trial+2}
                                    operator.firstSlipAngle = operator.results{angleIndex,1};
                                    operator.firstSlip = 1;
                                end
                            end
                        end
                    end
                end
            end
        end   
        
        %% Helper - searchBoundedBelowAngle -> find the greatest angle that has two 1s
        function [foundBoundedBelowAngle,result] = searchBoundedBelowAngle(operator, direction)
            
            % Hideous implementation
            result = 0;
            foundBoundedBelowAngle = 0; % A flag if we don't find such an angle
            trialNumCols = [2, 5, 8]; 
           
            if strcmp(direction, 'UP')
                for i = 16:-1:1 % from top to bottom
                    counter = 0;
                    for trial = trialNumCols
                        if operator.results{i, trial + 1} == 1
                            counter = counter + 1; 
                        if counter >= 2
                            result = i-1;
                            foundBoundedBelowAngle = 1;
                            return 
                        end
                        end
                    end
                end
            end
            if strcmp(direction, 'DOWN')
                for i = 16:-1:1 % from top to bottom
                    counter = 0;
                    for trial = trialNumCols
                        if operator.results{i, trial + 2} == 1
                            counter = counter + 1; 
                        if counter >= 2
                            result = i-1;
                            foundBoundedBelowAngle = 1;
                            return 
                        end
                        end
                    end
                end
            end
            
            
        end
        
        %% checks MAA up/down flags for termination
        function result = checkTermination(operator)
            result = 0;
            if operator.foundDownhill && operator.foundUphill
                result = 1;
            end
        end
        
        %% checks if input received are valid
        function processInput(operator, currAngle, resultUphill, resultDownhill)
            if operator.foundUphill && operator.foundDownhill
                fprintf('\nBoth MAAs are found! UpMAA = %d, DownMAA = %d\n', ...
                    operator.uphillMAA, operator.downhillMAA);
                return
            end    
               
            if ~operator.foundUphill && ~operator.foundDownhill
                if operator.predictedAngle == currAngle && (resultUphill ~= '*' ...
                    && resultDownhill ~= '*')
                    operator.recordResults(resultUphill, resultDownhill);
                    operator.adjustAngle(resultUphill, resultDownhill); 
                    return
                end
            end
            
            if operator.foundUphill && ~operator.foundDownhill
                if operator.predictedAngle == currAngle && resultDownhill ~= '*'
                    operator.recordResults('*', resultDownhill);
                    operator.adjustAngle('*', resultDownhill);
                    return
                end
            end
            
            if ~operator.foundUphill && operator.foundDownhill
                if operator.predictedAngle == currAngle && resultUphill ~= '*'
                    operator.recordResults(resultUphill, '*');
                    operator.adjustAngle(resultUphill, '*');
                    return
                end
            end
            
            disp('Check your input')
    
        end
       
    end
end

