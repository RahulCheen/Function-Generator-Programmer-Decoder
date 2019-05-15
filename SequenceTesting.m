if ~exist('FG','var')
        FG = visa('keysight','USB0::0x0957::0x2A07::MY52600694::0::INSTR')
        % This address depends on the serial number of the machine.
        fopen(FG) % There's some output here, so you know it worked.
end

switch 2
    
    case 1 % Test if I can upload a sequence with pre-existing segments
        fprintf(FG,'DATA:VOL:CLE'); % CLEar VOLatile memory
        fprintf(FG,'MMEM:LOAD:DATA1 "DC0.arb"'); % Load existing segment
        fprintf(FG,'MMEM:LOAD:DATA1 "DC5.arb"');
        fprintf(FG,'DATA:SEQ #282"testSeq.seq","INT:\DC0.arb",10,repeat,maintain,4,"INT:\DC5.arb",0,once,maintain,4'); % Load SEQuence
        fprintf(FG,'SOUR1:FUNC:ARB "testSeq.sEq"'); % Change the ARB waveform for channel 1 to the test sequence
        fprintf(FG,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
        
        
    case 2 % Test if I can upload a segment
        fprintf(FG,'DATA:VOL:CLE');
        fprintf(FG,'DATA:ARB:DAC Noisy,-32767,32767');
        

    case 3 % Test if I can upload a sequence with uploaded segments
        x=3;


    case 4 % Delete uploaded segments for a re-test
        x=4;
        

    case 5 % Further tests
        x=5;
end