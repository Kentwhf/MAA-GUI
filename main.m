% -----------------------------------------------------------------------
% Programmed by Kent Wu
% Start date: 2/7/2020
% 
% This script is designed for the purpose of intergration with the
% singleAxis GUI for Winterlab MAA testing.
%
% The real implmentation should be somewhat similar. The code elaborates
% the work flow in a general way. Consulting with CEAL engineers, see what
% changes need to make. 
% 
%% Work flow 

% --- POTENTIAL CHANGES ---
% 1. Assume the input is current angle and a pair of trial results, for UP 
% and DOWN respectively. Need a placeholder for trial results for the 
% current angle, like [*,*,angle] and PASS: 1, FAIL: 0, UNKNOWN: *
%
% 2. Request a confirmation if these are proper outcomes  [1,0], [1,1] etc.
% If results are not confirmed, pass and keep track of them. 

% --- PROCEDURE ---
%
% 1. API Class Operator will be initialized to observe, and respond to how 
% angle should be changed. 
%
% 2. Start testing by selecting results, and wait for confirmation.
%
% 3. Process input and check its legitimacy, proceed further if the input
% is appropriate. Otherwise, warn the user and ask for another input.
%
% 4. Repeat step 2 and 3.
%
% 5. Give a message as both MAAs (UP and DOWN) are acquired. Save certain
% varaibles eg.table as future reference.

% --- Pseudo Code for Step 2 and 3 ---
% 
% Initilize an Operator objective 
% Make some placeholder for inputs
% if operator.checkInput(resultUphill, resultDownhill, angle):
%   if Both MAA found:
%       return 
%   else:
%       % where 
%       operator.recordResults()
%       operator.checkMAA()
%   
% -----------------------------------------------------------------------




