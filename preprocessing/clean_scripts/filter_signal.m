function [data] = filter_signal(data, fs)
    % INPUT:
    % data  -> 2xN matrix where (1,:) is PPG signal assuming that N >= 1000
    % fs    -> Sampling frequency
    % OUTPUT
    % data  -> filtered input data
    
    % Remove steep steps at the begining of the data (if there are any)
    dff = find( abs(diff(data(1,1:800))) > 10 , 1);
    if(~isempty(dff))
        % remove the step in both ABP and PPG
        data = data(:,dff+1:end);
    end

    % In rare cases where the spike apears at the end of signal
    dff = find( abs(diff(data(1,(end-800):end))) > 10 , 1);
    if(~isempty(dff))
        % remove the step in both ABP and PPG
        data = data(:,1:end-dff-1);
    end
    
    % Flter PPG using the buttersworth filter (Bandwidth, [0.5, 8] Hz, 2-5 order)
    [b,a] = butter(4,[0.5,8]/(fs/2));  % butterworth filter
    
    
end