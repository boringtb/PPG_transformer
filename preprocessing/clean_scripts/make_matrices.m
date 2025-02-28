function [feature_mat, raw_mat, raw_mat_g] = make_matrices(data, fsppg, nA,nB, filename, make1, make2, testDir, pid)

    % INPUT
    %   data -> 2xM half-normalized matrix (1 -> ppg signal (noramlized), 2 -> abp signal (non-normalized))
    %   fsppg -> sampling frequency
    %   nA -> locations of the systolic peaks in the ppg signal
    %   nB -> starting locations of the ppg pulses
    %   filename -> name of the file the pulses were extracted from
    %   make1 -> boolean, flag for saving the feature matrix
    %   make2 -> boolean, flag for saving the raw matrix
    %   testDir -> directory where to save all raw signals and peaks/valleys
    % OUTPUT
    %   feature_mat -> N*15 matrix of features extracted from ppg pulses
    %   raw_mat -> N*(fsppg * 2 + 3) matrix containing centered raw values
    %       (normalized) of ppg pulses + systolic and distolic blood pressure values
    
    
    %% Default values
        if nargin<5
            error('Not enough input arguments');
        end

        % optional values make1 and make2 (boolean, deciding if the matrices will be saved to csv or not)
        if nargin<6
            make1 = false;
        end

        if nargin<7
            make2 = false;
        end

        % plots 1 and 2 (only for visualization during testing)
        %p1 = true;
        p1 = false;
        %p2 = true;
        p2 = false;
        
    %% Main loop

    % margin of the abp section and initialization of feature and raw matrices
    margin = 20;
    feature_mat = [];
    raw_mat = [];
    raw_mat_g = [];
    raw_mat_abp = [];
    sec_len = 20;
    
    % first and second dervatives of the ppg signal, for features extraction later on
    vpg = diff(data(1,:));
    vpg = [vpg(1), vpg];
    apg = diff(vpg);
    apg = [apg(1), apg];
    temp_pointer = -250;
    
    flag = 0;
    for i = 1:(size(nA,2)-1)
    %for i = 246:256 % for testing purposes
        
        %% Check for anomalies
        if flag ~= 0
            flag = flag - 1;
            if flag < 0
                flag = 0;
            end
            continue
        end
        
        if(isnan(nA(i)) || isnan(nB(i)))
            continue
        end
        
        if(nB(i) < (temp_pointer + (sec_len+2) * fsppg) + 4)
            continue
        end
        
        if(nB(i) > (size(data,2) - (sec_len+2) * fsppg) + 4)
            continue
        end           
        
        % check if the given pulse indices point to NaN data
        if(any(isnan(data(1,nA(i):nA(i)+sec_len * fsppg))) || any(isnan(data(1,nB(i):nB(i)+sec_len * fsppg))))
            continue
        end
        if(any(isnan(data(2,nA(i):nA(i)+sec_len * fsppg))) || any(isnan(data(2,nB(i):nB(i)+sec_len * fsppg))))
            continue
        end
     
        
        %% Check for any abnormal spikes in Systolic peaks (PPG)
        
        % throw away the whole recording if this happens, since we dont have an idea what the correct signal is anymore
        % if the difference in peaks is (> 20 mmHg) in under 10 seconds
        if i ~= 1 && (data(1,nA(i+1)) - data(1,nA(i))) > 20 && (nB(i+1) - nB(i)) > 2*fsppg
            %fprintf('make_mat error: %s \n', fullname);
            feature_mat = [];
            raw_mat = [];
            return; 
        end
        
        %% Extract PPG, VPG, APG and ABP sections

        for k = 1:30
            if nB(i+k)-nB(i) > sec_len * fsppg
                break;
            end
            temp_ppg_section = data(1, nB(i+k-1):nB(i+k));
            [dia_start, dia_peak] = check_pulse(temp_ppg_section,nA(i+k-1)-nB(i+k-1)+1);
           
            if dia_peak == -1 || dia_start == -1
                %fprintf('no diastolic peak/ledge\n')
                flag = k;
                break;
            end
            vpg_section = vpg(1, nB(i+k-1):nB(i+k));
            [w,y,z] = vpg_features(vpg_section, fsppg);
            if w == -1
                %fprintf('a pombear\n')
                flag = k;
                break;
            end
            apg_section = apg(1, nB(i+k-1):nB(i+k));
            [a,b,c,d,e] = apg_features(apg_section);
            if a == -1
                %fprintf('a pombel\n')
                flag = k;
                break;
            end
        end
        
        if flag ~= 0
            temp_pointer = nA(i); 
             continue;
        end
        
        ppg_section = data(1, nB(i):(nB(i) + sec_len * fsppg -1));
        left = max(1,nB(i)-margin);
        right = min(size(data,2), nB(i) + sec_len * fsppg - margin);
        abp_section = data(2, left:right);
        % size equals to the sampling frequency*2 + 1 (helps to be odd)
        raw_new_g = zeros(1,sec_len*fsppg+7);
        sec_len = 20;
        fsppg = 125;
        raw_new_g(1,1) = str2num(pid(2:8));
        raw_new_g(1,2) = str2num(pid(end-3:end));
        raw_new_g(1,3) = nB(i);
        % center the raw signal
        raw_new_g(4 :sec_len * fsppg + 3) = ppg_section;
        target_feats_g = gasper_all_raw_cycles(abp_section);
        abp_section = zeros(1, sec_len*fsppg);
        abp_section(1:end) = data(2, nB(i):(nB(i) + sec_len * fsppg -1));
        if ~any(target_feats_g < 0)
            raw_new_g(end-3:end) = gasper_all_raw_cycles(abp_section);
            raw_mat_g = [raw_mat_g; raw_new_g];
            raw_new_abp = zeros(1, sec_len*fsppg);
            raw_new_abp(1:sec_len * fsppg) = abp_section;
            raw_mat_abp = [raw_mat_abp; raw_new_abp];
        end

        %% Extract the features of the current pulse
        
        % evaluate the pulse and calculate the point of diastolic slope
        % returns -1 if the diastolic slope doesnt exsist

        
        % first derivative features
        % [w,y,z] = vpg_features(vpg_section, fsppg);
        % if w == -1
            %fprintf('a pombear\n')
            % continue
        % end
        
        % second derivative features
        % [a,b,c,d,e] = apg_features(apg_section);
        % if a == -1
            %fprintf('a pombel\n')
            % continue
        % end
        
        % check the data for any anomalies that have gotten past the checks
        % so far and join the extracted features in a matrix, alogn with some addtional ones
        %features = make_features(ppg_section, abp_section, fsppg, 1, nA(i)-nB(i)+1, dia_peak, dia_start);
        %if isempty(features)
        %    continue 
        %end

        % add a timestamp (starting sample number / sampling frequency to get the time in seconds) to the features vector
        % features = [nB(i)/fsppg,features];
        % add feature vector to the feature matrix
        % feature_mat = [feature_mat; features];

        % make raw_signal matrix (ppg)
        % size equals to the sampling frequency*2 + 1 (helps to be odd)
        %raw_new = zeros(1,sec_len*fsppg+1+4);
        % center the raw signal
        %padding = ceil((size(raw_new,2)-2 - size(ppg_section,2))/2);
        %raw_new(1:sec_len*fsppg+1) = ppg_section;
        %raw_new(end-3:end) = [features(end-3),features(end-2), features(end-1), features(end)];
        %raw_mat = [raw_mat; raw_new];      


        %% renew temp pointer
        temp_pointer = nA(i);
    end
    %% Make csv for the two matrices
    file_parts = strsplit(filename, '/');
    outDir = file_parts(end-1);
    outDir = outDir{1};
    outFile = file_parts(end);
    outFile = outFile{1};
    if(make1 && ~isempty(feature_mat))
        disp('Saving feature matrix.')
        filename_feat = strcat(testDir,outDir,'/',outFile, '_matrixFeatures.csv');
        csvwrite(filename_feat,feature_mat);
    end
    if(make2 && ~isempty(raw_mat_g))
        disp('Saving raw cycle matrix.')
        filename_raw = strcat(testDir,outDir,'/',outFile, '_matrixRawCyclesGood.csv');
        csvwrite(filename_raw,raw_mat_g);
        filename_abp = strcat(testDir,outDir,'/',outFile, '_matrixRawCyclesGood_ABP.csv');
        csvwrite(filename_abp,raw_mat_abp);       
    else
        disp('Too bad. The raw cycle matrix is empty.')
        delete(filename)
        delete(strcat(filename(1:end-5), '.info'))
        delete(strcat(filename(1:end-3), 'hea'))
    end
    %if( isempty(raw_mat_g))
        %delete(fullname)
    %end
    %if(~isempty(nA) && ~isempty(nB))
        %filename_raw_g = strcat(testDir,outDir,'/',outFile, '_matrixRawCyclesAll.csv');
        %csvwrite(filename_raw_g,raw_mat_g);
        %filename_peakValley_g = strcat(testDir,outDir,'/',outFile, '_matrixPeaksValleys.csv');
        %csvwrite(filename_peakValley_g, [nB(:), nA(:)]);
    %end

end