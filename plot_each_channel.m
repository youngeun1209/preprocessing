function plot_each_channel(EEG, segtime, varargin)
% plot each channel in segment time
% example: 
%           plot_each_channel_bbci(EPO, [0 30], 'nTrial',1 'data', EPO.x1 'scale', 200)
%
% input:    SMT
%           segtime:    a vector of two elements with 
%                       start point and end point (sec)
%           nTrial:     nth trial in interest
%           varargin:   
%               nTrial -    the turn of the class
%               data -      the signals in interest if you have other signals
%                           rather than SMT.x
%                           SMT.x, SMT.x1, SMT.x2, ...
%                           default: x
%               interval -  interval between plotting
% 

if ~exist('EEG','var')
    error('check your EEG data')
end

if ~exist('segtime','var')
    segtime=[0 5];
elseif isempty(segtime)
    segtime=[0 5];
end

opt = struct(varargin{:});

if isfield(opt,'title')
    str_title = opt.title;
else
    str_title = sprintf('EEG data in [%d - %d]',segtime(1),segtime(2));
end

if isfield(opt,'en_text')
    en_text = opt.en_text;
else
    en_text = true;
end

if isfield(opt,'plot_scale')
    plot_scale = opt.plot_scale;
end

if isfield(opt,'baseline')
    baseline = opt.baseline;
else
    baseline = 1;
end

data = EEG.data;
fs = EEG.srate;

% time segment
t=segtime(1)+1/fs:1/fs:segtime(2);
size_data = size(data);
if size(size_data,2) == 3
    chVec = squeeze(data(int64(t*fs),:,nTrial));
elseif size(size_data,2) == 2
    if EEG.nbchan == size_data(1)
        chVec = squeeze(data(:, int64(t*fs)));
    else
        chVec = squeeze(data(int64(t*fs),:));
    end
end
    
% baseline correction
baseline_val = mean(chVec(:,1:baseline*fs),2);
chVec = chVec - baseline_val;

% scale for plotting
windowSize = round(fs*0.01); b = (1/windowSize)*ones(1,windowSize); a = 1; 
t_dat_filt = filter(b,a,chVec);
plot_max = max(abs(t_dat_filt(:)));

if ~exist('plot_scale','var')
if plot_max == 0
    plot_scale = 1;
    warning('plot scale is 0')
elseif plot_max < 10 && plot_max >= 4
    plot_scale = 10;
elseif  plot_max < 5 && plot_max >= 1
    plot_scale = 5;
elseif  plot_max < 2 && plot_max >=0.5
    plot_scale = 1;
elseif plot_max < 0.5
    plot_scale = plot_max*1.5;
else
    plot_scale = round((plot_max*1.5)/10)*10;
end
end

% bias
bias = plot_scale * 2;
bias = cumsum(repmat(bias, size(chVec,1),1));

chVec = chVec + flip(bias);

% figure;
plot(t, chVec,'k')
% ylim([0-bias(1) bias(end)+bias(1)*2])
ylim([0 bias(end)+bias(1)])

xlim(segtime)
yticks(bias)
yticklabels(flip({EEG.chanlocs.labels}))
title(str_title);
ylabel('channels')
xlabel('time [s]')
str = sprintf('scale: %d', plot_scale);  % 
if en_text == true
annotation('textbox',[.01 .68 .3 .3],'String',str,'LineStyle','none');
end
% set(gcf,'Position',[1700 300 500 800]);

% grid on
% grid minor
