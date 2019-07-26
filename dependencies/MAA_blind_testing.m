% -----------------------------------------------------------------------
% A script for testing purpose
% Using historical MAA data sheets to examine the correstness of current
% algorithm, with prority of final MAAs but also angle adjustment
% Created by Kent 

%% --- Initial setup ---
workspace;  % Make sure the workspace panel is showing.
format longg;
format compact;
addpath(genpath(strcat(pwd, '/dependencies')));  % Add dependencies
tic

%% --- Select input ---
topLevelFolder = 'U:\Projects\Winter Projects\Kent\WinterLab\MAA data sheet'; % Change to different folder if needed
TOP_LEVEL_DIR = dir(topLevelFolder);
sheets = getAllDatafilePaths(topLevelFolder, TOP_LEVEL_DIR);
disp(sheets);

%% -- Load and read files