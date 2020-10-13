function [client, brand, name, modelNum, tech] = getSessionClientInfo(table, footwearID)
%getSessionClientInfo Get the 
%   Detailed explanation goes here
% The function definition.

row = ismember(footwearID, table.idapt_); % Find row where this person is stored.
if row > 0
    client = table{footwearID, 'Client'};
    brand = table{footwearID, 'Brand'};
    name = table{footwearID, 'Name'};
    modelNum = table{footwearID, 'Model_'};
    tech = table{footwearID, 'technology'};
else
    % iDAPT# was not found.
    client = 'ERROR';
    brand = 'ERROR';
    name = 'ERROR';
    modelNum = 'ERROR';
    tech = 'ERROR';
end

end

