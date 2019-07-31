classdef Operator < handle
    %   Operator - an abstracted tipper operator object (Model)
    %   Tipper properties during the MAA experiment
    %   UML pending... but 'uses' Participant and Session classes
    %   Initally created by Norman
    %   Modified and improved by Kent 
    
    properties
        session  % contains participant and all other session goodies
        currAngle % start at 3!
        timesVisitedAngles  % hashmap of angle -> # times visited
        
        results % table of results for all trails 
        
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
        % Some constant properties(fields), not often used 
        
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
            % operator takes a session object to initialize
            operator.session = session;
            
            % initial angle is 3
            operator.currAngle = 3; 

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
            
            % for angle plot in MAAHelperView
            operator.tseriesplot = timeseries([], []);
            
            % The underlying MAA table whose first column as angle 
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
            operator.timesVisitedAngles(operator.currAngle) = operator.timesVisitedAngles(operator.currAngle) + 1;
            
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
            disp(operator.results);
        end
        
        %% Check for MAA in uphill and downhill. Edge cases are handled when the tipper is adjusted at 0 or 15 degrees
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
                    if foundBoundedBelowAngle
                        operator.currAngle = operator.nextAngleHelper(uphillBoundedAngle + 1, 'non-decreasing');
                    else
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                    
                elseif operator.foundUphill
                    [foundBoundedBelowAngle, downhillBoundedAngle] = operator.searchBoundedBelowAngle('DOWN');
                    if foundBoundedBelowAngle
                       operator.currAngle = operator.nextAngleHelper(downhillBoundedAngle + 1, 'non-decreasing');
                    else
                       operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end  
                elseif ~(operator.bounded('UP','below',operator.currAngle - 1) && operator.bounded('DOWN','below',operator.currAngle - 1))
                    operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                end
                
            end
            
            % Case 2 and 3: (0,1) or (1,0)
            if (uphill == 0 && downhill == 1) || (uphill == 1 && downhill == 0)
                if operator.foundDownhill
                    [foundBoundedBelowAngle, uphillBoundedAngle] = operator.searchBoundedBelowAngle('UP');
                    if foundBoundedBelowAngle
                        operator.currAngle = operator.nextAngleHelper(uphillBoundedAngle + 1, 'non-decreasing');
                    else
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                    end
                    
                elseif operator.foundUphill
                    [foundBoundedBelowAngle, downhillBoundedAngle] = operator.searchBoundedBelowAngle('DOWN');
                    if foundBoundedBelowAngle
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
                        if foundBoundedBelowAngle
                            operator.currAngle = operator.nextAngleHelper(uphillBoundedAngle + 1, 'non-decreasing');
                        else
                            operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                        end
                    
                    elseif operator.foundUphill
                        [foundBoundedBelowAngle, downhillBoundedAngle] = operator.searchBoundedBelowAngle('DOWN');
                        if foundBoundedBelowAngle
                            operator.currAngle = operator.nextAngleHelper(downhillBoundedAngle + 1, 'non-decreasing');
                        else
                            operator.currAngle = operator.nextAngleHelper(operator.currAngle - 1, 'non-increasing');
                        end
                    
                    elseif ~(operator.bounded('UP','above', operator.currAngle + 1) && operator.bounded('DOWN','above',operator.currAngle + 1));
                        operator.currAngle = operator.nextAngleHelper(operator.currAngle + 1, 'non-decreasing');
                        
                    end
                 
                else
                    if operator.currAngle + 2 <= 15
                        operator.currAngle = operator.currAngle + 2;
                    end
                end
            end
        end
       
        %% Check if the current angle is bounded below or above by its adjacent angle or itself
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
            
            % hideous implementation
            % Need to refactor
            
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
        
        %% broadcast to any listeners that we modified operator's fields
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

