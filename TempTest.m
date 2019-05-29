fprintf(FG,'DATA:VOL:CLE'); % CLEar VOLatile memory
fprintf(FG,'MMEM:LOAD:DATA1 "DC0.arb"'); % Load existing segment
fprintf(FG,'MMEM:LOAD:DATA1 "DC5.arb"');
fprintf(FG,'MMEM:LOAD:DATA1 "TST_001.arb"');
fprintf(FG,'SOUR1:DATA:SEQ #3130"testSeq.seq","INT:\DC0.arb",0,repeatTilTrig,maintain,4,"INT:\TST_001.arb",0,once,maintain,4,"INT:\DC5.arb",0,repeatInf,maintain,4'); % Load SEQuence
fprintf(FG,'SOUR1:FUNC:ARB "testSeq.sEq"'); % Change the ARB waveform for channel 1 to the test sequence
fprintf(FG,'VOLT 5');
fprintf(FG,'SOUR1:FUNC ARB'); % Change channel 1's waveform to ARB
%fprintf(FG,'*TRG');
        