clear all; close all; clc;

addpath(genpath('eeglab-2025.0.0'));

%% Load data
data_dir = '/Users/young/Library/CloudStorage/GoogleDrive-youngeun@stanford.edu/Shared drives/BrainDynamicsLab/Projects/EEG/Dataset';

save_dir = fullfile(data_dir,'processed_data');

sub = 'sub004';
% task = 'REST';  % 'REST', 'MOVIE', 'STROOP'
% sess = 1;

tasks = {'REST','MOVIE'};
% ival=[0, 645]; % 921, 918, 915, 901

ival_all = [0,120;... % REST %
            0,120;... % REST
            0,120;... % REST
            0,120;... % REST
            0,921;... % MOVIE 1
            0,928]; %;... % MOVIE 2
            % 0,915;... % MOVIE 3
            % 0,901;... % MOVIE 4
            % -0.1,1] ; % STROOP
i_all = 1;


%%
for task_i = 1:length(tasks)
    task = tasks{task_i};
    for sess = 1:4 
        
        dataname = sprintf('%s_%s_session%d', sub, task, sess);

        plot_seg = [20, 40];
        plot_scale = 50;
        r=4; c=8;
        rc={};
        for ic = 1:c
            tmp = [];
            for ir = 1:r
                tmp = [tmp, c*(ir-1)+ic];
            end
            rc{ic} = tmp;
        end

        fi = 1;

        
        EEG = pop_loadbv(fullfile(data_dir,'raw_data',sub),[dataname, '.vhdr']);

        %% Preproessing
        % Event select
        select_epo = {'S  1'}; %,'rs', 'RS','REST','MOVIE'};
        % select_epo = {'S 11'};

        ival = ival_all(i_all,:);
        EEG = pop_epoch(EEG, select_epo, ival, 'epochinfo', 'yes'); % seconds

        figure(1);
        set(gcf,'Position',[0 0 2048 1024]);

        subplot(r,c,rc{fi}(1:end-1));
        plot_each_channel(EEG, plot_seg, 'plot_scale', plot_scale, 'title', 'Raw Signals');

        subplot(r,c,rc{fi}(end));
        plot_psd(EEG, [], 'title', 'Raw Signals')

        fi = fi+1;

        % High-Pass filter - 0.5 Hz
        EEG = pop_eegfilt(EEG, 0.5,0);

        subplot(r,c,rc{fi}(1:end-1));
        plot_each_channel(EEG, plot_seg, 'plot_scale', plot_scale, 'title','High-pass filter');

        subplot(r,c,rc{fi}(end));
        plot_psd(EEG, [], 'title', 'High-pass filter')

        fi = fi+1;


        % Notch filter - 60 & 120 Hz
        EEG = pop_eegfilt(EEG, 59.9,60.1,[],1,1);
        EEG = pop_eegfilt(EEG,119.9,120.1,[],1,1);

        subplot(r,c,rc{fi}(1:end-1));
        plot_each_channel(EEG, plot_seg, 'plot_scale', plot_scale, 'title','Notch Filter');

        subplot(r,c,rc{fi}(end));
        plot_psd(EEG, [], 'title', 'Notch Filter')

        fi = fi+1;


        % EOG removal
        EEG = pop_autobsseog(EEG,[],[],'sobi');
        EEG = pop_select(EEG, 'rmchannel',64);

        subplot(r,c,rc{fi}(1:end-1));
        plot_each_channel(EEG, plot_seg, 'plot_scale', plot_scale, 'title','EOG Removal');

        subplot(r,c,rc{fi}(end));
        plot_psd(EEG, [], 'title', 'EOG Removal')

        fi = fi+1;


        % Channel rejection and interpolation
        [~, indelec1, ~, ~] = pop_rejchan(EEG, 'measure','kurt', 'threshold',5, 'norm','on');
        indelec2 = clean_std(EEG, 'alpha',1.3);
        indelec = unique([indelec1, indelec2']);

        EEG = pop_interp(EEG, indelec, 'spherical');

        subplot(r,c,rc{fi}(1:end-1));
        plot_each_channel(EEG, plot_seg, 'plot_scale', plot_scale, 'title','Channel Correction');

        subplot(r,c,rc{fi}(end));
        plot_psd(EEG, [], 'title', 'Channel Correction')

        fi = fi+1;


        % Rereferencing
        EEG = pop_reref(EEG, [], 'exclude',64);

        subplot(r,c,rc{fi}(1:end-1));
        plot_each_channel(EEG, plot_seg, 'plot_scale', plot_scale, 'title','Re-referencing');

        subplot(r,c,rc{fi}(end));
        plot_psd(EEG, [], 'title', 'Re-referencing')

        fi = fi+1;

        %%
        filename = sprintf('%s_processed_%dHz',dataname,EEG.srate);
        if ~exist(fullfile(save_dir,sub), 'dir')
            mkdir(fullfile(save_dir,sub))
        end
        save(fullfile(save_dir,sub,filename),'EEG')


        % down-sampling - 250Hz
        EEG_tmp = EEG;
        re_srate = 250;
        EEG = pop_resample(EEG_tmp, re_srate);

        figure(1);
        subplot(r,c,rc{fi}(1:end-1));
        plot_each_channel(EEG, plot_seg, 'plot_scale', plot_scale, 'title', sprintf('Resample at %dHz',re_srate));

        subplot(r,c,rc{fi}(end));
        plot_psd(EEG, [], 'title', sprintf('Resample at %dHz',re_srate))

        fi = fi+1;

        filename = sprintf('%s_processed_%dHz',dataname, EEG.srate);
        save(fullfile(save_dir,sub,filename),'EEG')


        % down-sampling - 100Hz
        re_srate = 100;
        EEG = pop_resample(EEG_tmp, re_srate);

        figure(1);
        subplot(r,c,rc{fi}(1:end-1));
        plot_each_channel(EEG, plot_seg, 'plot_scale', plot_scale, 'title', sprintf('Resample at %dHz',re_srate));

        subplot(r,c,rc{fi}(end));
        plot_psd(EEG, [], 'title', sprintf('Resample at %dHz',re_srate))

        fi = fi+1;

        filename = sprintf('%s_processed_%dHz',dataname, EEG.srate);
        save(fullfile(save_dir,sub,filename),'EEG')


        % save figure        
        exportgraphics(gcf,fullfile(save_dir,sub,[dataname,'.png']),'ContentType','vector');

        i_all = i_all + 1; % next session
    end
end
