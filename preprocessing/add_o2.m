root_dir = '/collab2/ktang5/cleaned_39_new/';
dirData = dir(root_dir);

for i = 3:numel(dirData)
    x = dirData(i).name;
    cur_dir = strcat(root_dir, x);
    disp("working in");
    disp(cur_dir);
    
    num_head = strcat(cur_dir, '/', x, 'n.hea');
    f = fopen(num_head);
    tline = fgetl(f);
    O2_line = 0;
    while ischar(tline)
        if(strcmp(tline(end-3:end),'SpO2') | strcmp(tline(end-3:end),'spO2') | strcmp(tline(end-4:end),'%SpO2'))
            break;
        end
        O2_line = O2_line + 1;
        tline = fgetl(f);
    end
    fclose(f);

    sig_head = strcat(cur_dir, '/', x, '.hea');
    f = fopen(sig_head);
    tline = fgetl(f);
    tline = fgetl(f);
    tline = fgetl(f);
    tp_sum = 0;
    len_list = [];
    while ischar(tline)
        num = strsplit(tline);
        num = num(end);
        num = str2num(num{1:1});
        if(~(tline(1) == '~'))
            len_list = [len_list, tp_sum];
        end
        tp_sum = tp_sum + num;
        tline = fgetl(f);
        if(isletter(tline(end)))
            break;
        end
    end
    fclose(f);

    cd(cur_dir);
    O2 = strcat(x, 'n');
    data = rdsamp(O2, [O2_line]);

    csvs = dir(cur_dir);
    for k = 3:numel(csvs)
        csv_name = csvs(k).name;
        if(size(csv_name,2) == 41)
            csv_dict = strcat(cur_dir, '/', csv_name);
            m = csvread(csv_dict);
            p = [m, ones(1, size(m, 1))'];
            for j = 1:size(m, 1)
                tp = m(j,:);
                pos = tp(2);
                t_point = tp(3);
                t_point = (len_list(pos) + t_point) / 125;
                mean_o2 = mean(data(t_point-10:t_point+10));
                if(mean_o2<0)
                    mean_o2 = 0;
                end
                if(mean_o2>100)
                    mean_o2 = 100;
                end
                p(j, 2508) = mean_o2;
            end
            new_csv = strcat(cur_dir, '/', csv_name(1:18), '.csv');
            csvwrite(new_csv, p);
        end
    end
end