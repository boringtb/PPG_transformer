clear all;

testOutDir = '/collab2/ktang5/cleaned_30/';
dirName = '/collab2/ktang5/out_test_30/';   % Location of the data folder
dirData = dir(dirName); %location of patient data


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
    ppg = [];
    for j = 1:numel(workDir)
    %for j = 1:1  % for testing purposes
        fullname = strcat(wName,'/',workDir(j).name);
        out_index = fullname(end-17:end-5);
        pid = out_index(2:end);

        mat = load(fullname,'-mat');
        data = mat.val;
        data = data(1, :);
        ppg = [ppg, data];
        process_time = 0;
    end
    x = zscore(ppg);
    temp_s = 0;
    for j = 1:numel(workDir)
        fullname = strcat(wName,'/',workDir(j).name);
        out_index = fullname(end-17:end-5);
        pid = out_index;
        mat = load(fullname,'-mat');
        val = mat.val;
        temp_len = length(val(1,:));
        val(1,:) = x(1, temp_s+1:temp_s+temp_len);
        save(fullname, 'val');
        temp_s = temp_s + temp_len;
    end
    fprintf('%s total length: ', pid(1:7));
    fprintf('%d \n', length(ppg));
end