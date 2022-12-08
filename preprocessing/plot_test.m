M = readtable('3001554_0004m.mat_matrixRawCyclesGood_ABP.csv');
y = M{5, 1:2496};
if isnan(y)
    print('123');
end
%ppg_section = M{1, 1:84};
%peak_loc = 23;
%[dia_start, dia_peak] = check_pulse(ppg_section,23);
plot(y)

