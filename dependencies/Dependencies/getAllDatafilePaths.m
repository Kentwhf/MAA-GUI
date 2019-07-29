function [allExcelFiles, numFiles] = getAllDatafilePaths(topLevelFolder, TOP_LEVEL_DIR)
% Return a vector of all MAA datafile paths in a given directory

% Get list of all subfolders.
allSubFolders = genpath(topLevelFolder);
% Parse into a cell array.
remain = allSubFolders;
listOfFolderNames = {};
while true
	[singleSubFolder, remain] = strtok(remain, ';');
	if isempty(singleSubFolder)
		break;
	end
	listOfFolderNames = [listOfFolderNames singleSubFolder];
end
numberOfFolders = length(listOfFolderNames);

allExcelFiles = {};
% Traverse through all participant datasheets in those sub-directories
for k = 1 : numberOfFolders
	% Travserse the current directory
	thisFolder = listOfFolderNames{k};
    
    % Do not look at the topmost directory defined by staring directory
    if strcmp(thisFolder, TOP_LEVEL_DIR) == 0
        %fprintf('Current dir: %s\n', thisFolder);

        % Get participant excel data files
        filePattern = sprintf('%s/*.xlsx', thisFolder);
        baseFileNames = dir(filePattern);
        numDatasheets = length(baseFileNames);
        % Now we have a list of all excel files in this folder

        if numDatasheets >= 1
            % Go through all those excel files
            for f = 1 : numDatasheets
                fullFileName = fullfile(thisFolder, baseFileNames(f).name);
                % ignore the Owner files ~$*.xlsx because of concurrency
                % issues with the network drive grrr
                if strcmp(baseFileNames(f).name(1:2), '~$') == 0
                    %fprintf('     Yahoo!! Found a datasheet: %s\n', fullFileName);
                    allExcelFiles = [allExcelFiles, fullFileName];
                end
            end
        %else
            %fprintf('     No data files in dir: %s\n', thisFolder);
        end
    end
end
numFiles = length(allExcelFiles);

end

