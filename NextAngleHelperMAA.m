% GUI to tell the tipper operator which angle to do next
% Written by Norman - simple test bench (make this with vectorized input)
% See the MAA algorithm flowcharts for the high-level implementation
clear all
close all
clc

% test test 123
fprintf('-------------TEST CASE 1----------------\n');
participant = Participant('sub100', 'm', 8);
session = Session(participant, 0.08, 4.45, 68.00, 'dry', '12/12/12', '14:08', 8, 8, 8, 8, 8, 8, 8, 8, 'iDAPT000');

% TEST 1 - some basic MAA test
operator = Operator(session);

% trial1 = 1 1 @ 3
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1)

% trial2 = 1 1 @ 5
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1);

% trial3 = 1 1 @ 7
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1)

% trial4 = 1 0 @ 9
operator.recordResults(1, 0);
operator.checkMAA();
operator.adjustAngle(1, 0);

% trial5 = 0 0 @ 8
operator.recordResults(0, 0);
operator.checkMAA();
operator.adjustAngle(0, 0);

% trial6 = 1 0 @ 7
operator.recordResults(1, 0);
operator.checkMAA();
operator.adjustAngle(1, 0);

% trial7 = 1 1 @ 6
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1)

% trial8 = 1 0 @ 7
operator.recordResults(1, 0);
operator.checkMAA();
operator.adjustAngle(1, 0);

% trial9 = 1 1 @ 6 -- should have found downhill MAA here
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1);

% trial10 = 0 * @ 8 -- found downhill prev step so use '*'
operator.recordResults(0, '*');
operator.checkMAA();
operator.adjustAngle(0, '*');

expectedUp=7;
expectedDown=6;
obtainedUp = operator.uphillMAA;
obtainedDown = operator.downhillMAA;
fprintf('Expected (from the datasheet): UPHILL=%d, DOWNHILL=%d\n', expectedUp, expectedDown);
fprintf('Obtained: UPHILL=%d, DOWNHILL=%d\n', obtainedUp, obtainedDown);

assert(obtainedUp == expectedUp, 'FAILED: obtained up MAA did not match expected!');
assert(obtainedDown == expectedDown, 'FAILED: obtained down MAA did not match expected!');

fprintf('============================================\n\n');

%%%% TEST 2 - some other MAA thing made up
operator = Operator(session);

% trial1 = 1 1 @ 3
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1)

% trial2 = 1 1 @ 5
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1);

% trial3 = 1 1 @ 7
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1)

% trial4 = 0 1 @ 9
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults(0, 1);
operator.checkMAA();
operator.adjustAngle(0, 1);

% trial5 = 1 1 @ 8
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1);

% trial6 = 1 1 @ 9
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1);

% trial7 = 0 0 @ 10
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults(0, 0);
operator.checkMAA();
operator.adjustAngle(0, 0)

% trial8 = 0 1 @ 9 
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults(0, 1);
operator.checkMAA();
operator.adjustAngle(0, 1);

% trial9 = 1 1 @ 8 -- should find uphill MAA at 8
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults(1, 1);
operator.checkMAA();
operator.adjustAngle(1, 1);

% trial 10= * 0 @ 10 - should find downhill MAA at 9
fprintf('\nTrialNum = %d', operator.trialNum);
operator.recordResults('*', 0);
operator.checkMAA();
operator.adjustAngle('*', 0);


expectedUp=8;
expectedDown=9;
obtainedUp = operator.uphillMAA;
obtainedDown = operator.downhillMAA;
fprintf('Expected (from the datasheet): UPHILL=%d, DOWNHILL=%d\n', expectedUp, expectedDown);
fprintf('Obtained: UPHILL=%d, DOWNHILL=%d\n', obtainedUp, obtainedDown);

assert(obtainedUp == expectedUp, 'FAILED: obtained up MAA did not match expected!');
assert(obtainedDown == expectedDown, 'FAILED: obtained down MAA did not match expected!');

fprintf('============================================\n\n');
disp('congrats')


