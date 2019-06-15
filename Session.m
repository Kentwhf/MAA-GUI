classdef Session < handle
    %Session: A representation of a participant's session
    
    properties
        % envrionmental attributes
        iceTemp
        airTemp
        humidity
        walkway
        date
        time
        footwearID
        
        % ratings
        preslip
        slipperiness
        thermal
        heaviness
        fit
        useInWinter
        easeWearing
        overall
        
        observer
        
        % participant contianed in the session
        participant
    end
    
    events
        dataChanged % The exposed data has changed
        selecterror % An error occurred
    end
    
    methods
        % Can use a builder pattern later, but all info must be mandatory
        % nayway so for now this constructor works
        function ses = Session(varargin)
            if nargin == 17
                ses.participant = varargin{1};
                ses.iceTemp = varargin{2};
                ses.airTemp = varargin{3};
                ses.humidity = varargin{4};
                ses.walkway = varargin{5};
                ses.date = varargin{6};
                ses.time = varargin{7};
                ses.preslip = varargin{8};
                ses.slipperiness = varargin{9};
                ses.thermal = varargin{10};
                ses.heaviness = varargin{11};
                ses.fit = varargin{12};
                ses.useInWinter = varargin{13};
                ses.easeWearing = varargin{14};
                ses.overall = varargin{15};
                ses.footwearID = varargin{16};
                ses.observer = varargin{17};
            else
                ses.participant = Participant();
                ses.iceTemp = 0;
                ses.airTemp = 0;
                ses.humidity = 0;
                ses.walkway = 'unknown walkway';
                ses.date = '12/12/12';
                ses.time = '12:00';
                ses.preslip = 0;
                ses.slipperiness = 7;
                ses.thermal = 7;
                ses.heaviness = 7;
                ses.fit = 7;
                ses.useInWinter = 7;
                ses.easeWearing = 7;
                ses.overall = 7;
                ses.footwearID = 'iDAPT000';
                ses.observer = 'observer';
            end
        end
        
        %% Setters
        function setParticipant(session, p)
            session.participant = p;
        end
        
        function setIceTemp(session, p)
            session.iceTemp = p;
        end
        
        function setAirTemp(session, p)
            session.airTemp = p;
        end
        
        function setHumidity(session, p)
            session.humidity = p;
        end
        
        function setWalkway(session, p)
           session.walkway = p; 
        end
        
        function setDate(session, p)
            session.date = p;
        end
        
        function setTime(session, p)
            session.time = p;
        end
        
        function setPreslip(session, p)
            session.preslip = p;
        end
        
        function setSlip(session, p)
            session.slipperiness = p;
        end
        
        function setFit(session, p)
            session.fit = p;
        end
        
        function setThermal(session, p)
            session.thermal = p;
        end
        
        function setHeaviness(session, p)
            session.heaviness = p;
        end
        
        function setOverall(session, p)
            session.overall = p;
        end
        
        function setUseInWinter(session, p)
            session.useInWinter = p;
        end
        
        function setEase(session, p)
            session.easeWearing = p;
        end
        
        function setFootwear(session, footID)
            session.footwearID = footID;
        end
        
        function setObserver(session, obv)
            session.observer = obv;
        end
        
         %% to string method for pretty printing
        function strrep = toString(session)
           strrep = sprintf(['Ice Temperature: %d\nAir Temperature: %d\nHumidity:%d\n' ...
               'Walkway: %s\nDate: %s\nTime: %s\nFootwear ID: %s\nPreslip: %d\n' ...
               'Slipperiness: %d\nThermal: %d\nHeaviness: %d\nFit: %d\n'...
               'Use in Winter: %d\nEase of Putting On: %d\nOverall: %d\nObserver: %s'], ...
               session.iceTemp, session.airTemp, session.humidity, session.walkway, ...
               session.date, session.time, session.footwearID, session.preslip, ...
               session.slipperiness, session.thermal, session.heaviness, session.fit, ...
               session.useInWinter, session.easeWearing, session.overall, session.observer); 
        end
        
        %% Notify event (and anything listening), that the selected data has changed
        function notifyListeners(session)
            notify(session,'dataChanged'); 
        end
        
    end
    
end

