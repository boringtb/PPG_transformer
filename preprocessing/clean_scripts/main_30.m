clear all;

% The main script incorporating all of the methods tested !!!!
% preprocesses the files -> removes flat lines, flat peaks, flat valleys
% Filters and normalizes the signal
% Extracts the feature and raw matrices for each dataset
% Calls the script that concatenates the extracted matrices feature and raw matrices

testOutDir = '/collab2/ktang5/cleaned_30_new/';
dirName = '/collab2/ktang5/out_test_30/';   % Location of the data folder
dirData = dir(dirName); %location of patient data

% count variables for percentage of flat / peak deleted files
count_f = 0;
count_p = 0;
% number of all files
n = 0;



%sampling rate
fsppg = 125;

%windows
w_flat = 5;    % flat lines window
w_peaks = 5;    % flat peaks window
w_fix = 5;     % flat join window

% thresholds
t_peaks = 0.05; % percentage of tolerated flat peaks
t_flat = 0.05;  % percentage of tolerated flat lines


%for i = 3:3 % for testing purposes
%hbar = parfor_progressbar_v1(numel(dirData)-2,'Computing...');  %create the progress bar
for i = 3:numel(dirData)
    %hbar.iterate(1);   % update progress by one iteration
    wName = strcat(dirName, dirData(i).name);
    path = fullfile(wName, '*.mat');
    workDir = dir(path);
    disp(strcat('Working with DIR:', wName))
    
    if(numel(workDir) == 0)
        %delete folder if empty -> rmdir only delets empty folders
        fprintf('Deleting due to empty dirs: %s \n', fullname);
        deleteFolder(wName);
        continue
    end
    
    for j = 1:numel(workDir)
    %for j = 1:1  % for testing purposes

        fullname = strcat(wName,'/',workDir(j).name);
        if(length(fullname) < 50)
            fprintf('Not intended one: %s \n', fullname);
            delete(fullname)
            continue
        end
        out_index = fullname(end-17:end-5);
        pid = out_index;
        out_fold = strcat(testOutDir, out_index(2:8));
        out_index = strcat(out_index, 'm.mat_matrixRawCyclesGood.csv');
        out_index = strcat(out_fold, out_index);
        if ~exist(out_index)==0
            fprintf('Already exist: %s \n', out_index);
            continue
        end
        mat = load(fullname,'-mat');
        data = mat.val;
        n = n+1;
        process_time = 0;
        
        [p_ppg, p_abp] = flat_lines(data, w_flat, false, false);
        if(p_ppg > t_flat || p_abp > t_flat )
            fprintf('Deleting due to flat lines: %s \n', fullname);
            count_f = count_f +1;
            %delete file
            delete(fullname)
            delete(strcat(fullname(1:end-5), '.info'))
            delete(strcat(fullname(1:end-3), 'hea'))
            continue
        end
        

        [~, ppg_peaks] = findpeaks(data(1,:)); [~, ppg_valleys] = findpeaks(-1 * data(1,:));
        [~, abp_peaks] = findpeaks(data(2,:)); [~, abp_valleys] = findpeaks(-1 * data(2,:));
        [a,b] = flat_peaks(data, abp_peaks,abp_valleys,ppg_peaks,ppg_valleys, t_peaks, t_peaks, w_peaks, false);
        if(a > 0 || b > 0 )
            fprintf('Deleting due to flat peaks: %s \n', fullname);
            count_p = count_p +1;
            %delete file
            delete(fullname)
            delete(strcat(fullname(1:end-5), '.info'))
            delete(strcat(fullname(1:end-3), 'hea'))
            continue
        end
        

        
        % first convert data into physical units
        [tm,sig,fs,nfo] = rdmat(fullname(1:end-4));

        % remove NaNs from conversion
        sig = sig';
        sig = sig(:,~isnan(sig(1,:)));
        sig = sig(:,~isnan(sig(2,:)));
        
        if(size(sig,2) < 120 * fsppg)
            fprintf('Processed signal too small: %s \n', fullname);
            delete(fullname)
            delete(strcat(fullname(1:end-5), '.info'))
            delete(strcat(fullname(1:end-3), 'hea'))
            continue
        end
        
        % bandpass and hampel filters
        data = filter_signal(sig, fsppg);


        
        % using the Pulse waveform delineator (quick)
        [nB2,nA2,nM2] = delineator(data(1,:), fsppg);
        new_data = flat(data, w_fix, nB2, 'ppg', false);        %ppg
        [nB3,nA3,nM3] = delineator(new_data(2,:), fsppg);
        new_data = flat(new_data, w_fix, nB3, 'abp', false);    %abp
        
        % delete if its smaller than 2 min (120 * fsppg) after changes
        if(size(new_data,2) < 120 * fsppg)
            fprintf('Processed data too small: %s', fullname);
            delete(fullname)
            delete(strcat(fullname(1:end-5), '.info'))
            delete(strcat(fullname(1:end-3), 'hea'))
            continue
        end
        
        disp(strcat('SUCCESS with file: ', fullname))
        
        %figure;
        %ax(1) = subplot(2,1,1);
        %plot(new_data(1,:));
        %ax(2) = subplot(2,1,2);
        %plot(new_data(2,:));
        %linkaxes(ax, 'x')
        %return;
        
        %save new_file over the current one
        val = new_data; % so all the data is saved the same way
        file_parts = strsplit(fullname, '/');
        outDir = file_parts(end-1);
        outDir = outDir{1};
        outFile = file_parts(end);
        outFile = outFile{1};
        if ~isfolder(strcat(testOutDir,outDir))
            mkdir(strcat(testOutDir,outDir))
            %parsave(strcat(testOutDir,outDir,'/',outFile), val);
        else
            %parsave(strcat(testOutDir,outDir,'/',outFile), val);
        end

        % if you come this far, it means that everything should have went well
        % next step is to make matrices out of the preprocessed data
        

        % normalize
        norm_data = zeros(2, size(data,2));
        norm_data(1,:) = new_data(1,:);
        norm_data(2,:) = new_data(2,:);
        % make a feature matrix and a matrix of raw values
        [feat, raw] = make_matrices(norm_data, fsppg, nA2, nB2, fullname, false, true, testOutDir, pid); % deliniator

        % delete file if the feature matrix or the raw matrix is empty
        %if(isempty(feat) || size(feat,1) < 100 || isempty(raw) || size(raw,1) < 100)
            %fprintf('Feature or raw matrix empty for file: %s \n', fullname);
            %delete(fullname)
            %delete(strcat(fullname(1:end-5), '.info'))
            %delete(strcat(fullname(1:end-3), 'hea'))
            %continue
        %end
        % time for one succesful processing
    end
    
    %delete folder if empty (not contatining any .mat files)
    if numel(dir(path)) == 0
        %sprintf('Deleting folder: %s', wName)
        deleteFolder(wName);
    %else
        % vertically join the extracted feature and raw matrices
        %concat_matrices(strcat(testDir,outDir));
    end
end


per_files_flat = count_f/n;  % percentage of files deleted due to flat lines
per_files_peak = count_p/n;  % percentage of files deleted due to flat peaks
avg_time = full_time/n;
sprintf('Full percentage of flat lines: % .3f | Full percentage of flat peaks: %.3f | Full time (min): %f | Average time (sec): %f',per_files_flat, per_files_peak, full_time/60, avg_time)

function parsave(fname, val)
    save(fname, 'val');
    %disp('Saving cleaned file.')
end
