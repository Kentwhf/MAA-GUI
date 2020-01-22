function varargout = MAAHelperView(varargin)
% MAAHELPERVIEW MATLAB code for MAAHelperView.fig (View)
%      MAAHELPERVIEW, by itself, creates a new MAAHELPERVIEW or raises the existing
%      singleton*.
%
%      H = MAAHELPERVIEW returns the handle to a new MAAHELPERVIEW or the handle to
%      the existing singleton*.
%
%      MAAHELPERVIEW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAAHELPERVIEW.M with the given input arguments.
%
%      MAAHELPERVIEW('Property','Value',...) creates a new MAAHELPERVIEW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MAAHelperView_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MAAHelperView_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MAAHelperView

% Last Modified by GUIDE v2.5 26-Jul-2018 09:40:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MAAHelperView_OpeningFcn, ...
                   'gui_OutputFcn',  @MAAHelperView_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end



if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before MAAHelperView is made visible.
function MAAHelperView_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MAAHelperView (see VARARGIN)

% Choose default command line output for MAAHelperView
handles.output = hObject;

% get the operator object and button tags
handles.operator = varargin{1};

%Listen for change event
handles.listen = event.listener(handles.operator, 'dataChanged', @(o,e) onChangedTrial(handles, handles.operator));
handles.listen = event.listener(handles.operator.session, 'dataChanged', @(o,e) onChangedSession(handles, handles.operator.session));
handles.listen = event.listener(handles.operator.session.participant, 'dataChanged', @(o,e) onChangedParticipant(handles, handles.operator.session.participant));

% Update handles structure
guidata(hObject, handles);

% do this when any changed data
onChangedTrial(handles, handles.operator);
onChangedSession(handles, handles.operator.session);
onChangedParticipant(handles, handles.operator.session.participant);

% move to left of screen
movegui(handles.figure1, 'west');

% set current angle stuff
startupWindows(handles);

% --- Outputs from this function are returned to the command line.
function varargout = MAAHelperView_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function startupWindows(handles)
% angle information
set(handles.currAngleWindow, 'String', handles.operator.lastTestedAngle);
set(handles.timesVisited, 'String', handles.operator.timesVisitedAngles(handles.operator.currAngle) + 1);
set(handles.trialNumWindow, 'String', handles.operator.trialNum);
set(handles.upDownWindow, 'String', sprintf('%s | %s', num2str(handles.operator.lastResultUphill), num2str(handles.operator.lastResultDownhill)));
set(handles.nextAngleWindow, 'String', handles.operator.nextAngle);  % after this listener is notified, all angles have already been adjusted...

% --- Do this when the thing changes
function onChangedTrial(handles, operator)
% plot and print out next angle and other info
% if ~handles.operator.foundUphill || ~handles.operator.foundDownhill
%     fprintf('    ---- updating angle: %d\n', operator.currAngle);
% end

handles.operator.notifyListeners();

% angle information
set(handles.currAngleWindow, 'String', operator.lastTestedAngle);
set(handles.timesVisited, 'String', operator.timesVisitedAngles(operator.currAngle) + 1);
set(handles.trialNumWindow, 'String', operator.trialNum);
set(handles.upDownWindow, 'String', sprintf('%s | %s', num2str(operator.lastResultUphill), num2str(operator.lastResultDownhill)));
set(handles.nextAngleWindow, 'String', operator.nextAngle);  % after this listener is notified, all angles have already been adjusted...

% found maa's panel
if operator.foundUphill
    set(handles.foundUphillRadio, 'Value', 1);
    set(handles.uphillMAAWindow, 'String', operator.uphillMAA);
else
    set(handles.foundUphillRadio, 'Value', 0);
    set(handles.uphillMAAWindow, 'String', '');
end

if operator.foundDownhill
    set(handles.foundDownhillRadio, 'Value', 1);
    set(handles.downhillMAAWindow, 'String', operator.downhillMAA);
else
    set(handles.foundDownhillRadio, 'Value', 0);
    set(handles.downhillMAAWindow, 'String', '');    
end

if operator.firstSlip
    set(handles.firstSlipWindow, 'String', operator.firstSlipAngle);
else
    set(handles.firstSlipWindow, 'String', '');
end

% grey out angle if we found both MAAs
if operator.foundUphill && operator.foundDownhill
    set(handles.nextAngleWindow, 'Enable', 'off');
    set(handles.nextAngleWindow, 'String', 'DONE');
    set(handles.trialNumWindow, 'String', 'N/A');
    set(handles.timesVisited, 'String', operator.timesVisitedAngles(operator.currAngle));

else
    set(handles.nextAngleWindow, 'Enable', 'on');
    set(handles.nextAngleWindow, 'String', '');
end

% plot time series
plot(handles.AnglePlot, operator.tseriesplot.Time, operator.tseriesplot.Data, '-*');
newYTicks = 0:20;
newXTicks = 1:25;
set(handles.AnglePlot,'YTick',newYTicks);%,'YTickLabel',num2str(newYTicks))
set(handles.AnglePlot,'XTick',newXTicks);%,'XTickLabel',num2str(newYTicks))

function onChangedSession(handles, session)
%Depending on tag fed to GUI, select how to plot
fprintf('    ---- updating session info...\n');
strrep = session.toString();
set(handles.sessionSummary, 'String', strrep);

function onChangedParticipant(handles, participant)
fprintf('    ---- updating participant info...\n');
strrep = participant.toString();
set(handles.participantSummary, 'String', strrep);

% --- Executes on button press in foundDownhillRadio.
function foundDownhillRadio_Callback(hObject, eventdata, handles)

% --- Executes on button press in foundUphillRadio.
function foundUphillRadio_Callback(hObject, eventdata, handles)
