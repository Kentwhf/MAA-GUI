%-----------------------------------------------------------------------------
% Returns the next empty cell in column after row 1.  Basically it puts the active cell in row 1
% and types control-(down arrow) to put you in the last row.  Then it add 1 to get to the next available row.
% Credits to ImageAnalyst who posted this function on https://www.mathworks.com/matlabcentral/answers/285463-how-find-last-row-in-excel

function nextRow = GoToNextRowInColumn(Excel, column)
  try
    % Make a reference to the very last cell in this column.
    cellReference = sprintf('%s1048576', column);
    Excel.Range(cellReference).Select;
    currentCell = Excel.Selection;
    bottomCell = currentCell.End(3); % Control-up arrow.  We should be in row 1 now.
    % Well we're kind of in that row but not really until we select it.
    bottomRow = bottomCell.Row;
    cellReference = sprintf('%s%d', column, bottomRow);
    Excel.Range(cellReference).Select;
    bottomCell = Excel.Selection;
    bottomRow = bottomCell.Row;  % This should be 1
    % If this cell is empty, then it's the next row.
    % If this cell has something in it, then the next row is one row below it.
    cellContents = Excel.ActiveCell.Value;  % Get cell contents - the value (number of string that's in it).
    % If the cell is empty, cellContents will be a NaN.
    if isnan(cellContents)
	% Row 1 is empty.  Next row should be 1.
	nextRow = bottomRow;  % Don't add 1 since it was empty (the top row already).
    else
	% Row 1 is not empty.  Next row should be row 2.
	nextRow = bottomRow + 1;  % Will add 1 to get row 1 as the next row.
    end
  catch ME
    errorMessage = sprintf('Error in function GoToNextRowInColumn.\n\nError Message:\n%s', ME.message);
    fprintf('%s\n', errorMessage);
    WarnUser(errorMessage);
  end
  return; % from LeftAlignSheet
end % of GoToNextRowInColumn

