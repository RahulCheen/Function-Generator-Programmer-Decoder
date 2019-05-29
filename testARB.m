%testARB
FG_ID           = 'MY52600694'; % serial number of new fxn generator


if ~exist('FG','var')
    FG = visa('keysight',['USB0::0x0957::0x2A07::',FG_ID,'::0::INSTR'])
end

fprintf(FG,'FUNCtion SQU');
fprintf(FG,'FREQuency +1.0E+04 VOLTage +1 VOLTage:OFFset 0.0 AM:SOURce INT');
fprintf(FG,'AM:DSSC 0');
fprintf(FG,'AM:DEPTh +120 AM:INTernal:FUNCtion TRI AM:INTernal:FREQ 5E+02 AM:STATe 1');
fprintf(FG,'OUTPut1 1');