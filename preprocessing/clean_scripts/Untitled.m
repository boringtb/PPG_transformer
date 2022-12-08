%clear all;

% The main script incorporating all of the methods tested !!!!
% preprocesses the files -> removes flat lines, flat peaks, flat valleys
% Filters and normalizes the signal
% Extracts the feature and raw matrices for each dataset
% Calls the script that concatenates the extracted matrices feature and raw matrices

dirName = './data/';   % Location of the data folder
dirData = dir(dirName); %location of patient data

% count variables for percentage of flat / peak deleted files
count_f = 0;
count_p = 0;
% number of all files
n = 0;
% time per file calculation
time = [];

%% PARAMETRS

%sampling rate
fsppg = 125;

%windows
w_flat = 15;    % flat lines window
w_peaks = 5;    % flat peaks window
w_fix = 15;     % flat join window

% thresholds
count_f = 0;
count_p = 0;
t_peaks = 0.05; % percentage of tolerated flat peaks
t_flat = 0.05;  % percentage of tolerated flat lines
res_file = 'res_file.mat';
total_len_list = [];
p_ppg_list = [];
p_abp_list = [];
save res_file total_len_list p_ppg_list p_abp_list count_f count_p n;
tic
%% Loop through the data
%for i = 3:3 % for testing purposes
hbar = parfor_progressbar_v1(numel(dirData)-2,'Computing...');  %create the progress bar
load 'res_file.mat';

for i = 3+3*length(p_ppg_list):numel(dirData)
    fprintf('processing: %s \n', dirData(i).name);
    flag = 0;
    hbar.iterate(1);   % update progress by one iteration
    wName = strcat(dirName, dirData(i).name);
    if(~strcmp(wName(end-2:end),'mat') | (~contains(wName, '_')))
        continue;
    end

    mat = load(wName,'-mat');
    data = mat.val;
    total_len = length(data) / 125 / 60;
    n = n+1;
    process_time = 0;

    %% Detect flat lines in the signal
    [p_ppg, p_abp] = flat_lines(data, w_flat, false, false);
    if(p_ppg > t_flat || p_abp > t_flat )
        count_f = count_f + 1;
        flag = 1;
        %delete file
        %delete(fullname)
        %delete(strcat(fullname(1:end-5), '.info'))
        %delete(strcat(fullname(1:end-3), 'hea'))
        %continue
    end

    %% detect flat peaks in the signal
    [~, ppg_peaks] = findpeaks(data(1,:)); [~, ppg_valleys] = findpeaks(-1 * data(1,:));
    [~, abp_peaks] = findpeaks(data(2,:)); [~, abp_valleys] = findpeaks(-1 * data(2,:));
    [a,b] = flat_peaks(data, abp_peaks,abp_valleys,ppg_peaks, ppg_valleys, t_peaks, t_peaks, w_peaks, false);
    if(a > 0 || b > 0 )
        count_p = count_p + 1;
        flag = 1;
        %delete file
        %delete(fullname)
        %delete(strcat(fullname(1:end-5), '.info'))
        %delete(strcat(fullname(1:end-3), 'hea'))
        %continue
    end

    %% Filter the data

    % first convert data into physical units
    [tm,sig,fs,nfo] = rdmat(wName(1:end-4));

    % remove NaNs from conversion
    sig = sig';
    sig = sig(:,~isnan(sig(1,:)));
    sig = sig(:,~isnan(sig(2,:)));
    total_len_list(end+1) = total_len;
    p_ppg_list(end+1) = p_ppg;
    p_abp_list(end+1) = p_abp;
    if(size(sig,2) < 120 * fsppg)
        fprintf('Processed signal too small: %s \n', wName);
        flag = 1;
        %delete(fullname)
        %delete(strcat(fullname(1:end-5), '.info'))
        %delete(strcat(fullname(1:end-3), 'hea'))
        continue
    end

    % bandpass and hampel filters
    %%%%% zhuyi data = filter_signal(sig, fsppg);
    data = sig;
    %% Join relevant valleys to remove flat lines

    % using the Pulse waveform deliniator (quick)
    % [nB2,nA2,nM2] = delineator(data(1,:), fsppg);
    % new_data = flat(data, w_fix, nB2, 'ppg', false);        %ppg
    % [nB3,nA3,nM3] = delineator(new_data(2,:), fsppg);
    % new_data = flat(new_data, w_fix, nB3, 'abp', false);    %abp

    % delete if its smaller than 2 min (120 * fsppg) after changes
    %if(size(new_data,2) < 120 * fsppg)
        %flag = 1
        %delete(fullname)
        %delete(strcat(fullname(1:end-5), '.info'))
        %delete(strcat(fullname(1:end-3), 'hea'))
        %continue
    %end

    if(flag == 0)
        disp(strcat('SUCCESS with file: ', wName))
    end
    
    if(mod(length(total_len_list), 20) == 0)
        save res_file total_len_list p_ppg_list p_abp_list count_f count_p n;
        fprintf('saving: %d \n', length(total_len_list));
    end
end
close(hbar);   %close progress bar
