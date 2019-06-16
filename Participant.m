classdef Participant < handle
    %Participant: A participant object containing their attributes
    %   Represents the features of the participant in the Winterlab
    
    properties
        ID   % subject ID
        sex  % sex as m/f for male and female, respectively
        size  % footwear size
        height % subject height
        weight % subject weight
    end
    
    events
        dataChanged % The exposed data has changed
        selecterror % An error occurred
    end
    
    methods
        %% Constructor(s)
        function parti = Participant(varargin)  % ID, sex, size, footwear
           if nargin == 3
               parti.ID = varargin{1};
               parti.sex = varargin{2};
               parti.size = varargin{3};
           elseif nargin == 2
               parti.ID = varargin{1};
               parti.sex = varargin{2};
               parti.size = 0;  % Default size is 0
           elseif nargin == 1
               parti.ID = varargin{1};
               parti.sex = 'unknown gender';  % default gender is q
               parti.size = 0;  % Default size is 0
           else
               parti.ID = 'sub000';  % default ID is 'sub000'
               parti.sex = 'unknown gender';  % default gender is unknown
               parti.size = 0;  % Default size is 0
           end
        end
        
        %% SETTERS, nothing special
        function setID(participant, id)
            participant.ID = id;
            %notify(participant,'dataChanged'); %Notify event (and anything listening), that the selected data has changed
        end
        
        function setSex(participant, id)
            participant.sex = id;
            %notify(participant,'dataChanged'); %Notify event (and anything listening), that the selected data has changed
        end
        
        function setSize(participant, size)
            participant.size = size;
            %notify(participant,'dataChanged'); %Notify event (and anything listening), that the selected data has changed
        end
        
        %% Notify to broadcast that data has been changed
        function notifyListeners(participant)
            notify(participant, 'dataChanged');
        end
        
        %% to string method for pretty printing
        function strrep = toString(participant)
           strrep = sprintf('Subject ID: %s\nSex: %s\nShoe size: %d', participant.ID, participant.sex, participant.size); 
        end
        
    end
    
end

