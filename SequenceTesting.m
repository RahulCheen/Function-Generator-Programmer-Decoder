if ~exist('FG','var')
        FG = visa('keysight','USB0::0x0957::0x2A07::MY52600694::0::INSTR')
        % This address depends on the serial number of the machine.
        fopen(FG) % There's some output here, so you know it worked.
end

switch 1
    
    case 1 % Test if I can upload a sequence with pre-existing segments
        fprintf(FG,'DATA:VOL:CLE'); % CLEar VOLatile memory
        fprintf(FG,'MMEM:LOAD:DATA1 "DC0.arb"'); % Load existing segment
        fprintf(FG,'MMEM:LOAD:DATA1 "DC5.arb"');
        fprintf(FG,'DATA:SEQ #282"testSeq.seq","INT:\DC0.arb",10,repeat,maintain,4,"INT:\DC5.arb",0,once,maintain,4'); % Load SEQuence
        fprintf(FG,'SOUR1:FUNC:ARB "testSeq.sEq"'); % Change the ARB waveform for channel 1 to the test sequence
        fprintf(FG,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
        
        
    case 2 % Test if I can upload a segment
        fprintf(FG,'DATA:VOL:CLE');
        fprintf(FG,'DATA:ARB:DAC attempt,-32767,-30000,-25000,-20000,-15000,-10000,-5000,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,20,40,80,160,320,640,1280,2560,5120,10240,20480,32767,0,0,0,0,0,0,0,0,0,0');
        % Always has 3 MSa/s and 100 mV ptp.

    case 3 % Test if I can upload a sequence with uploaded segments
        x=3;


    case 4 % Delete uploaded segments for a re-test
        x=4;
        

    case 5 % Further tests
        x=5;
end