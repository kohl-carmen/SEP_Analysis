%% EEG 
%called preproc_2020.m in backup
clear
% load toolboxes
eeglab_dir='C:\Users\ckohl\Documents\MATLAB\eeglab2019_0';
% fieldtrip_dir='C:\Users\ackg426\Documents\fieldtrip-20160904';
% rmpath(genpath(fieldtrip_dir))
cd(eeglab_dir)
eeglab


% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% BEH
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load('C:\Users\ckohl\Downloads\New_Task_Code_Beeper\Beta02_20200306_data_final.mat')
% %% these arrays are a mess
% % trial - time - delay time - stimulus - detected?
% beh.pest=output_array_PEST_1;
% beh.train=output_array_training_1;
% beh.task=[tactile_detection_baseline_run1;tactile_detection_baseline_run2];
% clearvars -except beh
% beh.task(:,1)=1:length(beh.task);
% 
% data=beh.task;
% rt=[];
% for i=2:length(data)
%     rt(i)=data(i,2)-data(i-1,2);
% end
% 
% unique(data(:,3))
% unique(data(:,4))
% plot(data(:,1),rt,'o')
% 
% 
% supra='S  1';
% threshold='S  2';
% null='S  3';

% 
% 
% 
% 
% 
% 
% 
% count_triggers=[];
% trigger_types={};
% boundary_count=0;
% for event = 1:length(EEG.event)-1
%     if ~any(ismember(EEG.event(event).type ,trigger_types))
%         trigger_types{end+1}=EEG.event(event).type;
%         count_triggers(end+1)=1;
%     else
%         for trig=1:length(trigger_types)
%             if EEG.event(event).type(1:4) == trigger_types{trig}(1:4)
%                 count_triggers(trig)=count_triggers(trig)+1;
%             end
%         end
%     end
% end








%% Load EEG 
%Carmen
EEG = pop_loadbv('F:\\Brown\\Pilot Data Sets\\Dektop_Current_EEG\\', 'actiCHamp_Plus_BC-TMS_BETA02_20200306_EOG000027_Change Sampling Rate_6.vhdr');
%Danielle
EEG = pop_loadbv('F:\\Brown\\Pilot Data Sets\\Dektop_Current_EEG\\', 'actiCHamp_Plus_BC-TMS_BETA04_20200305_EOG000025_Change Sampling Rate_6.vhdr');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% First, let's see what triggerd there
count_triggers=[];
trigger_types={};
boundary_count=0;
for event = 1:length(EEG.event)-1
    if ~any(ismember(EEG.event(event).type ,trigger_types))
        trigger_types{end+1}=EEG.event(event).type;
        count_triggers(end+1)=1;
    else
        for trig=1:length(trigger_types)
            if EEG.event(event).type(1:4) == trigger_types{trig}(1:4)
                count_triggers(trig)=count_triggers(trig)+1;
            end
        end
    end
end

fprintf('Found a total of %i triggers and %i trigger types: \n',length(EEG.event),length(trigger_types))
for trig=1:length(trigger_types)
    fprintf('\t %s (%i) \n', trigger_types{trig},count_triggers(trig))
end
disp('----')
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Clean Data (EEG Preprocessing)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% EEG.chanlocs = readlocs('C:\Users\ckohl\Documents\Virtual_Shared\Pilot\1020.elp','defaultelp', 'besa')
% EEG=pop_chanedit(EEG, 'lookup','C:\\Users\\ckohl\\Documents\\MATLAB\\eeglab2019_0\\plugins\\dipfit\\standard_BESA\\standard-10-5-cap385.elp');
EEG=eeg_checkset(EEG);
% eeglab redraw
% EEG=pop_resample(EEG,1000)

%take out EOG
EOG_Channels=[64, 65];
EOG=pop_select(EEG, 'channel', EOG_Channels);
EEG=pop_select(EEG, 'nochannel', EOG_Channels);

% check bad channels before rereferencing
pop_eegplot(EEG);

% filter
EEG = pop_eegfiltnew(EEG, 0.1, [], [], 0, [], 0);
EEG = pop_eegfiltnew(EEG, [], 45, [], 0, [], 0);

% Remove Bad Channlels
pop_eegplot( EEG, 1, 1, 1);
figure; pop_spectopo(EEG, 1, [], 'EEG' , 'percent',15,'freq', [10 20 30],'freqrange',[2 80],'electrodes','off');

% Beta04 bad=[];
% Beta02 bad=[12 29];
EEG=pop_select(EEG, 'nochannel',bad);

% Re-reference to Average
EEG = pop_reref( EEG, []);

 % Reject Break Dat
pop_eegplot(EEG);
% Beta02 EEG = eeg_eegrej( EEG, [22 228651;1213500 1239072;1316451 1330780;1512615 1538367;1627953 1688614;2426264 2487304;3213378 3273200;3455943 3515120]);
% Beta04 EEG = eeg_eegrej( EEG, [24 276254;1256167 1346786;4689870 4707040]);

 %% Run ICA
tic
EEG=pop_runica(EEG, 'icatype', 'runica')
toc

%%Remove Blink Component
pop_selectcomps(EEG, [1:35] );
EEG = pop_subcomp( EEG, [1], 0);

%  Beta04 1
%  Beta02 1
% 
% Reject Noise
pop_eegplot(EEG);
% Beta04 EEG = eeg_eegrej( EEG, [3653 3712;255527 255574;750579 751074;869260 869956;1056696 1059803;1060377 1060927;1064254 1073896;1257693 1264857;1265123 1272601;2027923 2029050;2298599 2298703;2313463 2314586;2447279 2447989;2590345 2591241;2681529 2681868;2725963 2726623;2738018 2738644;2770583 2770747;2792186 2794087;2865874 2866859;2867825 2868089;2955622 2956361;2969263 3004527;3057071 3058211;3065423 3066250;3163886 3165688;3187363 3343568]);
% Beta02 EEG = eeg_eegrej( EEG, [72632 72970;80967 81202;232118 232900;291815 292059;384306 384915;585986 586651;736062 737619;996305 997640;1045605 1045964;1255284 1256131;1262777 1263393;1266565 1266638;1281344 1281573;1337695 1338328;1349228 1350156;1363861 1364857;1385486 1387243;1396648 1397287;1429666 1430044;1463810 1464427;1471206 1471892;1493693 1493998;1537012 1537707;1599885 1600508;1621431 1621957;1702626 1703267;1743797 1744521;1762710 1763157;1766580 1767089;1773875 1774234;1785455 1785901;1818074 1818415;1836750 1837463;1844885 1846107;1871370 1871794;1874853 1875322;1878487 1878887;1903862 1904046;1919003 1920171;1959115 1959388;1983933 1984720;1998369 1998794;2024135 2024675;2038840 2039280;2078827 2079432;2137038 2137985;2140577 2140886;2200525 2201049;2215555 2216255;2280681 2281140;2366359 2369460;2390427 2392603;2427303 2428785;2447166 2449013;2458534 2459378;2461936 2462593;2602769 2603165;2952522 2953037]);


%% Interpolate Removed Channels
% channel_interpol=readlocs('C:\Users\ckohl\Documents\Virtual_Shared\Pilot\1020.elp','defaultelp', 'besa');
[nr_chan t]=size(EEG.data);
if nr_chan < 63
    EEG=pop_interp(EEG,55,'spherical');
end


% cd('C:\Users\ckohl\Desktop\Current\EEG\')
% save('Beta02_preproc','EEG')
     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Chop into intervals

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
eeglab_dir='C:\Users\ckohl\Documents\MATLAB\eeglab2019_0';
cd(eeglab_dir)
eeglab

%load preprocessed data
%Carmen
load('C:\Users\ckohl\Desktop\Current\EEG\Beta02_preproc.mat')
%Danielle
load('C:\Users\ckohl\Desktop\Current\EEG\Beta04_preproc.mat')
    
        
my_events=[];        
for event = 1:length(EEG.event)
    if EEG.event(event).type(end)=='y'
        my_events(event)=nan;
    else
        my_events(event)=str2num(EEG.event(event).type(end));
    end
end
my_events=my_events'  ;


my_boundaries=[];
bound_i=[];
found_intervals =[0 0 0 0 0 0];%[supra,training,rest,pest,task,rest]
for i=1:length(my_events)
    %% supra
    if found_intervals(1)==0 & my_events(i:i+4)==1
        found_intervals(1)=1;
        my_boundaries=0;
        bound_i=0;
    %% training
    elseif found_intervals(1)==1 & sum(found_intervals)==1 
        if all([my_events(i:i+4)==1]==[1 1 1 0 0]') & any(~(isnan(my_events(i:i+4))==[0 0 0 1 1]')) % 1 1 1 and then 2 of somethign else (but not only boundaries)
            found_intervals(2)=1;
            % find exact boundary
            if any(my_events(i+3:i+10)==7) %is there a voundary event?
                my_boundaries(2)=EEG.event(i+2+find(my_events(i+3:i+10)==7)).latency;
                bound_i(2)=i+2+find(my_events(i+3:i+10)==7);
            else
                earliest4=min(find(my_events(i+3:i+10)==4));
                earliest5=min(find(my_events(i+3:i+10)==5));
                if earliest4<earliest5
                    my_boundaries(2)=EEG.event(i+2+earliest4).latency-200;
                    bound_i(2)=i+2+earliest4;
                else 
                    my_boundaries(2)=EEG.event(i+2+earliest5-2).latency-200;
                    bound_i(2)=i+2+earliest5-2;
                end
            end
        end
     %% rest 
     elseif found_intervals(2)==1 & sum(found_intervals)==2
         % right now, it cant fidn the rest of the initial S4 isnt there
         if my_events(i)==4 & ( EEG.event(i+1).latency - EEG.event(i).latency > 10000 | (isnan(my_events(i+1) & EEG.event(i+2).latency - EEG.event(i).latency > 10000)))
            found_intervals(3)=1;
            rest_start=i;
            % find exact boundary
            if any(my_events(i-3:i)==7)
                my_boundaries(3)=EEG.event(i-4+find(my_events(i-3:i)==7)).latency;
                bound_i(3)=i-4+find(my_events(i-3:i)==7);
            else
                my_boundaries(3)=EEG.event(i).latency-200;
                bound_i(3)=i;
            end
         end
     %% PEST
     elseif found_intervals(3)==1 & sum(found_intervals)==3
         if i-1==rest_start
             found_intervals(4)=1;
             next_event=i+min(find(~isnan(my_events(i:i+10))))-1;
             if my_events(next_event)==7
                my_boundaries(4)=EEG.event(next_event).latency; 
             else
                my_boundaries(4)=EEG.event(next_event).latency-200; 
             end
             bound_i(4)=next_event;
         end
         
    %% TASK
    elseif found_intervals(4)==1 & sum(found_intervals)==4 % find long latency between 4 and previosu 5
           if i> bound_i(4)+10
               if my_events(i)==4 &  (my_events(i-1)==5   | ( my_events(i-2)==5  & (my_events(i-1)==7 | isnan(my_events(i-1)))) |  (my_events(i-3)==5 & (my_events(i-1)==7 | isnan(my_events(i-1))) | (my_events(i-2)==7 | isnan(my_events(i-2)))))
                  if (EEG.event(i).latency-EEG.event(i-4+find(my_events(i-3:i)==5)).latency > 5000) 
                      my_boundaries(5)=EEG.event(i).latency-200; 
                      bound_i(5)=i;
                      found_intervals(5)=1;
                  elseif any(isnan(my_events(i-3:i)))
                      if EEG.event(i-4+find(isnan(my_events(i-3:i)))).duration >5000
                        my_boundaries(5)=EEG.event(i).latency-200; 
                        bound_i(5)=i;
                        found_intervals(5)=1;
                      end
                  end
               end
           end
         
     %% Rest  
    else 
        if i==length(my_events) % last event that' s not a boundary
            last_event=i-10+max(find(~isnan(my_events(i-10:i))))-1;
            my_boundaries(6)=EEG.event(last_event).latency-200; 
            bound_i(6)=last_event;
            found_intervals(end)=1;
        end
    end
end
if found_intervals==1
    fprintf('\nAll segments found: \nsupra: \t%i\ntrain: \t%i\nrest: \t%i\npest: \t%i\ntask: \t%i\nrest: \t%i\n',bound_i)
else
    fprintf('Only %i segments were found. Review.\n',sum(found_intervals))
    dd
end

%split
my_boundaries(7)=length(EEG.data);
EEG_intervals=struct();
for i=1:length(my_boundaries)-1
    EEG_intervals.(strcat('i',num2str(i)))=pop_select(EEG,'point',[my_boundaries(i), my_boundaries(i+1)]);
end

%try to just add events?
%find an S1 as a template
event_template=EEG.event(min(find(my_events==1)));
for i=1:length(my_boundaries)
    EEG.event(end+1)=event_template;
    EEG.event(end).latency=my_boundaries(i);
    EEG.event(end).type='99';
end














%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ERP

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
eeglab_dir='C:\Users\ckohl\Documents\MATLAB\eeglab2019_0';
cd(eeglab_dir)
eeglab

%ppt
h = actxserver('PowerPoint.Application');
Presentation = h.Presentation.Add;

%load preprocessed data
%Carmen
load('C:\Users\ckohl\Desktop\Current\EEG\Beta02_preproc.mat')
%Danielle
load('C:\Users\ckohl\Desktop\Current\EEG\Beta04_preproc.mat')




which_trials=2; 
%1 = all possible supra
%2 = only supra from supra sequence
%3 = only first supra sequence(danielle only) - dark but sleepy
%4 = only last supra sequence(danielle only) - light

eeglab redraw
supra='S  1';
electr_oi='C3';

%find electrode
for chan= 1:length(EEG.chanlocs)
    if length(EEG.chanlocs(chan).labels)==2
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end

if which_trials>1
    %there are more htan 600 S1 triggers, so I want to find the ones I think
    %are part of the supra part
    count=0;
    for i= 2:length(EEG.event)
        if length(EEG.event(i).type)==length(supra)
            if EEG.event(i).type==supra
                if EEG.event(i-1).type(1)=='b' | EEG.event(i-1).type(end)=='5'| EEG.event(i-1).type(end)=='1'
                    count=count+1;
                    EEG.event(i).type='S X1';
                end
            end
        end
    end

    supra='S X1';
    
   if which_trials>2
       count=0;
       time_diff=[];
       latest_X=0;
       cutoff=0;
       temp={};
       for i= 1:length(EEG.event)
           temp{i}=EEG.event(i).type;
           if any(EEG.event(i).type=='X')  
               time_diff(i)=EEG.event(i).latency-latest_X;
               latest_X=EEG.event(i).latency;
               if time_diff(i)>20000
                   cutoff=1;
               end
               if cutoff
                   EEG.event(i).type='S X2';
               end
           end
       end
       if which_trials==4
           supra='S X2';
       end
   end
end 

EEG = pop_epoch( EEG, { supra }, [-.2 1], 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-200   0]);
figure; pop_timtopo(EEG, [-200  999], [100 170]);
%% ERP IMAGE
figure; 
pop_erpimage(EEG,1, [electr_oi_i],[[]],strcat(EEG.chanlocs(electr_oi_i).labels, '- Trials: ',num2str(size(EEG.data,3))),10,1,{},[],'' ,'yerplabel','\muV','erp','on','limits',[-50 299 NaN NaN NaN NaN NaN NaN] ,'cbar','on','topo', { [electr_oi_i] EEG.chanlocs EEG.chaninfo } );

print('-dpng','-r150',strcat('temp','.png'));
blankSlide = Presentation.SlideMaster.CustomLayouts.Item(1);
Slide1 = Presentation.Slides.AddSlide(1,blankSlide);
Image1 = Slide1.Shapes.AddPicture(strcat(cd,'/temp','.png'),'msoFalse','msoTrue',0,0,850,550);%10,20,700,500


%% All Electrodes

subplarray=[nan,nan,nan,nan,1,60,2,nan,nan,nan,nan;nan,nan,nan,52,38,30,39,53,nan,nan,nan;nan,11,46,3,32,17,33,4,47,12,nan;nan,54,25,40,21,31,22,41,26,55,nan;nan,13,48,5,34,18,35,6,49,14,nan;29,56,27,42,23,61,24,43,28,57,nan;nan,15,50,7,36,19,37,8,51,16,nan;nan,nan,nan,58,44,62,45,59,nan,nan,nan;nan,nan,nan,nan,9,63,10,nan,nan,nan,nan;nan,nan,nan,nan,nan,20,nan,nan,nan,nan,nan];                
Data=EEG;
figure
clf
hold on
% time=[-1*dt+1:1.*dt];
time=[-50:300];
y_lims=[0 0];
colour=[.4 .4 .4];
for c=1:length(EEG.chanlocs)
    sub_i=find(subplarray'==c);
    sub=subplot(10,11,sub_i);     
    hold on
%   title(EEG.chanlocs(c).labels)
    plot(zeros(size([-10*10^6:1*10^6:10*10^6])),[-10*10^6:1*10^6:10*10^6],'Color',[.5 .5 .5])
    plot(time,zeros(size(time)),'Color',[.5 .5 .5])
    plot(time,mean(Data.data(c,150:end,:),3));
        %make standard error
        SE_upper=[];
        SE_lower=[];
        for i=1:size(Data.data,2)
            se=std(Data.data(c,i,:))./sqrt(length(Data.data(c,i,:)));
            SE_upper(i)=mean(Data.data(c,i,:))+se;
            SE_lower(i)=mean(Data.data(c,i,:))-se;
        end 
        tempx=[time,fliplr(time)];
        tempy=[SE_upper(150:end),fliplr(SE_lower(150:end))];
        A=fill(tempx,tempy,'k');
        A.EdgeColor='none';
        A.FaceColor=colour;
        A.FaceAlpha=.2;
    y_lims(1)=min([y_lims(1),min(mean(Data.data(c,:,:),3))]);
    y_lims(2)=max([y_lims(2),max(mean(Data.data(c,:,:),3))]);
    set(gca,'visible','off')
    b=annotation('textbox','String',Data.chanlocs(c).labels);
    b.Position=sub.Position;
%   b.FontSize=14;
    b.EdgeColor='none';
end

for c=1:length(EEG.chanlocs)
    sub_i=find(subplarray'==c);
    subplot(10,11,sub_i) 
    ylim(y_lims)
    % colour coding
    thirds=linspace(0,y_lims(2)-y_lims(1),4);
    this_diff=max(mean(Data.data(c,:,:),3))-min(mean(Data.data(c,:,:),3));
%     if this_diff<thirds(2)
%         plot(time,mean(Data.data(c,:,:),3),'Linewidth',2,'Color',[.344 .906 .344]);
%     elseif this_diff<thirds(3)
%         plot(time,mean(Data.data(c,:,:),3),'Linewidth',2,'Color',[1 .625 .25]);
%     else
%          plot(time,mean(Data.data(c,:,:),3),'Linewidth',2,'Color',[.75 0 0]);
%     end
    plot(time,mean(Data.data(c,150:end,:),3),'Linewidth',1,'Color',[.3 .3 .3]);
end        


print('-dpng','-r150',strcat('temp','.png'));
blankSlide = Presentation.SlideMaster.CustomLayouts.Item(1);
Slide1 = Presentation.Slides.AddSlide(1,blankSlide);
Image1 = Slide1.Shapes.AddPicture(strcat(cd,'/temp','.png'),'msoFalse','msoTrue',0,0,850,550);%10,20,700,500


%% transform for MNE-Python
EEG = pop_saveset( EEG, 'filename','Beta02_1s_ERP_for_MNE.set','filepath','C:\\Users\\ckohl\\Documents\\Virtual_Shared\\Pilot\\Beta02\\EEG\\');



%% Topos
fig1=figure
fig1.Renderer='Painters';
dataoi=EEG;
topo_time=[0:20:240]%[0:2];%ms
topo_time=[0:10 :250]
topo_time_interval=topo_time(2)-topo_time(1);
topo_samples=topo_time+200;%topo_time*dt + 1*dt;
topo_loc=[-.1 .1 .4 .65 .9];
max_clim=[0 0];

for i=[1:length(topo_samples)]
    temp=mean(mean(dataoi.data(:,topo_samples(i)-topo_time_interval:topo_samples(i),:),3),2);
    max_clim(1)=min(max_clim(1),min(temp));
    max_clim(2)=max(max_clim(2),max(temp));
end
figure
hold on
for i=1:length(topo_time)-1
    subplot(3,4,i)
    topoplot(mean(mean(dataoi.data(:,topo_samples(i)-topo_time_interval:topo_samples(i),:),3),2),EEG.chanlocs,'maplimits',max_clim./3);
    title(strcat(num2str(topo_time(i)-topo_time_interval),'-',num2str(topo_time(i)),'ms'));
end

print('-dpng','-r150',strcat('temp','.png'));
blankSlide = Presentation.SlideMaster.CustomLayouts.Item(1);
Slide1 = Presentation.Slides.AddSlide(1,blankSlide);
Image1 = Slide1.Shapes.AddPicture(strcat(cd,'/temp','.png'),'msoFalse','msoTrue',0,0,850,550);%10,20,700,500



%% ERPs with topos
dataoi=EEG;
figure
clf
eeg_time=[-50:300];
time=eeg_time???
eeg_samples=eeg_time+200;%;eeg_time*dt + 1*dt;
subplot(2,5,[6:10]);
hold on
% plot(eeg_time,mean(dataoi.data(:,eeg_samples,:),3));
plot(eeg_time,mean(dataoi.data(electr_oi_i,eeg_samples,:),3),'k','Linewidth',2);
%  make standard error
SE_upper=[];
SE_lower=[];
for i=1:size(dataoi.data,2)
    se=std(dataoi.data(electr_oi_i,i,:))./sqrt(length(dataoi.data(electr_oi_i,i,:)));
    SE_upper(i)=mean(dataoi.data(electr_oi_i,i,:))+se;
    SE_lower(i)=mean(dataoi.data(electr_oi_i,i,:))-se;
end 
tempx=[time,fliplr(time)];
tempy=[SE_upper(eeg_samples),fliplr(SE_lower(eeg_samples))];
A=fill(tempx,tempy,'k');
A.EdgeColor='none';
A.FaceColor=colour;
A.FaceAlpha=.2;
% for i=1:size(dataoi.data,3)/10
%     plot(eeg_time,(dataoi.data(electr_oi_i,eeg_samples,i)),'Color',[.5 .5 .5]);
% end
y=ylim;
x=xlim;
ylim(y)
xlim(x)
xlabel('Time');
ylabel('Amplitude');
set(gca,'Clipping','Off')
topo_time=[50 75 120 170 220];%[50 70 100 150 200];%[0:2];%ms
topo-time=[70 
topo_time_interval=10;%topo_time(2)-topo_time(1);
topo_samples=topo_time+200;%topo_time*dt + 1*dt;
topo_loc=[-25 50 125 200 275];
max_clim=[0 0];

for i=[1:length(topo_samples)]
    temp=mean(mean(dataoi.data(:,topo_samples(i)-topo_time_interval:topo_samples(i)+topo_time_interval,:),3),2);
    max_clim(1)=min(max_clim(1),min(temp));
    max_clim(2)=max(max_clim(2),max(temp));
end
for i=1:length(topo_samples)
    subplot(2,5,i)
    topoplot(mean(mean(dataoi.data(:,topo_samples(i)-topo_time_interval:topo_samples(i)+topo_time_interval,:),3),2),EEG.chanlocs,'maplimits',max_clim./3);
%     cbar('horiz',0,round(max_clim/1000),3)
%     title(strcat(num2str(topo_time(i)-topo_time_interval),'-',num2str(topo_time(i)+topo_time_interval),'ms'));
    title(strcat(num2str(topo_time(i)),'ms'))
    subplot(2,5,[6:10]);
    h=line([topo_time(i)-topo_time_interval,topo_loc(i)],      [mean(EEG.data(electr_oi_i,topo_samples(i)-topo_time_interval,:),3),y(2)*2]);
    h.Color='k';
    h=line([topo_time(i)+topo_time_interval,topo_loc(i)],      [mean(EEG.data(electr_oi_i,topo_samples(i)+topo_time_interval,:),3),y(2)*2]);
    h.Color='k';
end

print('-dpng','-r150',strcat('temp','.png'));
blankSlide = Presentation.SlideMaster.CustomLayouts.Item(1);
Slide1 = Presentation.Slides.AddSlide(1,blankSlide);
Image1 = Slide1.Shapes.AddPicture(strcat(cd,'/temp','.png'),'msoFalse','msoTrue',0,0,850,550);%10,20,700,500





%% compare conds
supra='S  1';
threshold='S  2';
null='S  3';
supra = pop_epoch( EEG, { supra }, [-.2 .3], 'epochinfo', 'yes');
supra = pop_rmbase( supra, [-200   0]);
threshold = pop_epoch( EEG, { threshold }, [-.2 .3], 'epochinfo', 'yes');
threshold = pop_rmbase( threshold, [-200   0]);
null = pop_epoch( EEG, { null }, [-.2 .3], 'epochinfo', 'yes');
null = pop_rmbase( null, [-200   0]);


%%%%
% supra02=supra;
% threshold02=threshold;
% null02=null;
% 
% supra02.data(:,:,size(supra02.data,3)+1:size(supra02.data,3)+size(supra04.data,3))=supra04.data;
% threshold02.data(:,:,size(threshold02.data,3)+1:size(threshold02.data,3)+size(threshold04.data,3))=threshold04.data;
% null02.data(:,:,size(null02.data,3)+1:size(null02.data,3)+size(null04.data,3))=null04.data;
% 
% supra=supra02;
% null=null02;
% threshold=threshold02;

electr_oi='C3';

%find electrode
for chan= 1:length(EEG.chanlocs)
    if length(EEG.chanlocs(chan).labels)==2
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end


go_through={'supra','threshold'}%,'null'};
fig1=figure
fig1.Renderer='Painters';
clf
hold on
Colour={'r','b','k'}
for go=1:3
    colour=Colour{go};
    dataoi=eval(go_through{go});
    eeg_time=[-50:300];
    eeg_samples=eeg_time+200;%;eeg_time*dt + 1*dt;
    hold on
    % plot(eeg_time,mean(dataoi.data(:,eeg_samples,:),3));
   
    %  make standard error
    SE_upper=[];
    SE_lower=[];
    for i=1:size(dataoi.data,2)
        se=std(dataoi.data(electr_oi_i,i,:))./sqrt(length(dataoi.data(electr_oi_i,i,:)));
        SE_upper(i)=mean(dataoi.data(electr_oi_i,i,:))+se;
        SE_lower(i)=mean(dataoi.data(electr_oi_i,i,:))-se;
    end 
    tempx=[eeg_time,fliplr(eeg_time)];
    tempy=[SE_upper(eeg_samples),fliplr(SE_lower(eeg_samples))];
    A=fill(tempx,tempy,'k');
    A.EdgeColor='none';
    A.FaceColor=colour;
    A.FaceAlpha=.2;
    
    line(go)=plot(eeg_time,mean(dataoi.data(electr_oi_i,eeg_samples,:),3),'Color',colour,'Linewidth',2);

end
legend(line,go_through)



print('-dpng','-r150',strcat('temp','.png'));
blankSlide = Presentation.SlideMaster.CustomLayouts.Item(1);
Slide1 = Presentation.Slides.AddSlide(1,blankSlide);
Image1 = Slide1.Shapes.AddPicture(strcat(cd,'/temp','.png'),'msoFalse','msoTrue',0,0,850,550);%10,20,700,500
































%plot
time=[-199:300];
colour=[.438 .062 .438];
topo_times_time=[0 30 70 110 150 190];% in ms
zero_index=find(time==0);
topo_times=topo_times_time+zero_index; %in samples
data=mean(EEG.data(this_one,:,:),3);
clf
subplot(3,5,[1:10])
hold on
plot(time, data,'Linewidth',2,'Color', [.438 .062 .438])
%error bars
tempx=[time,fliplr(time)];
tempy=[SE_upper,fliplr(SE_lower)];
A=fill(tempx,tempy,'k')
A.EdgeColor=colour;
A.FaceColor=colour;
A.FaceAlpha=.2;
%stuff
y=ylim;
plot(zeros(length([y(1) y(2)])),[y(1) y(2)],'Color',[.5 .5 .5])
% if ~ S
%     plot(zeros(length([y(1) y(2)]))-299,[y(1) y(2)],'Color',[.5 .5 .5],'LineStyle','--')
% end
plot(time, zeros(length(time)),'Color',[.5 .5 .5])
xlim([-50 200])
legend([electr_oi;'SE'],'Location','southeast')
title(strcat('Trigger: ',Stim))
%topo
max_clim=0;
for topo_time=[30 70 110 150 190];
    sublpot_handle=subplot(3,5,11)
    topoplot(mean(EEG.data(:,topo_time,:),3),EEG.chanlocs);
    clim=caxis;
    max_clim=max(max_clim,clim(2));
end
delete(sublpot_handle)

for topo_time=2:length(topo_times)
    subplot(3,5,10+topo_time-1)
    topoplot(mean(mean(EEG.data(:,[topo_times(topo_time-1):topo_times(topo_time)],:),3),2),EEG.chanlocs,'maplimits',[-max_clim, max_clim]);
    hold on
    colorbar
    title(strcat(num2str(topo_times_time(topo_time)),' ms'))
end
    
set(gca, 'YDir','reverse')



y=ylim;
plot(zeros(length([y(1):y(2)])),[y(1) : y(2)],'Color',[.5 .5 .5])
plot(time, zeros(length(time)),'Color',[.5 .5 .5])
title(Stim)

figure('units','normalized','outerposition',[0 0 1 1])
pop_plottopo(EEG, [1:63] , Stim, 0, 'ydir',1);
print('-dpng','-r150',strcat('temp','.png'));
blankSlide = Presentation.SlideMaster.CustomLayouts.Item(1);
Slide1 = Presentation.Slides.AddSlide(1,blankSlide);
Image1 = Slide1.Shapes.AddPicture(strcat(cd,'/temp','.png'),'msoFalse','msoTrue',0,0,850,550);%10,20,700,500

close all
pop_topoplot(EEG, 1, [0:10:100] ,Stim ,[3 4],0,'electrodes','on');
print('-dpng','-r150',strcat('temp','.png'));
Slide1 = Presentation.Slides.AddSlide(1,blankSlide);
Image1 = Slide1.Shapes.AddPicture(strcat(cd,'/temp','.png'),'msoFalse','msoTrue',0,0,850,550);%10,20,700,500


    

figure
hold on

plot(time, c3(150:end),'Linewidth',2,'Color', [.438 .062 .438])
y=ylim;
plot(zeros(length([y(1):y(2)])),[y(1) : y(2)],'Color',[.5 .5 .5])
plot(time, zeros(length(time)),'Color',[.5 .5 .5])
title(Stim)
print('-dpng','-r150',strcat('temp','.png'));

Slide1 = Presentation.Slides.AddSlide(1,blankSlide);
Image1 = Slide1.Shapes.AddPicture(strcat(cd,'/temp','.png'),'msoFalse','msoTrue',0,0,850,550);%10,20,700,500

close all


%plot trials
count=0;
for outer=1:6
%     figure('units','normalized','outerposition',[0 0 1 1])
    hold on
    mini=[];
    for i=1:50
        count=count+1;
        subplot(10,5,i)
        hold on
        title(num2str(count))
%         plot(time, EEG.data(this_one,150:end,count))
        mini(i,:)=EEG.data(this_one,150:end,count);
        ylim([-10 10])
        y=ylim;
        plot(zeros(length([y(1):y(2)])),[y(1) : y(2)],'Color',[.5 .5 .5])
        plot(time, zeros(length(time)),'Color',[.5 .5 .5])
    end
    plot(mean(mini))
end

%plot trials
count=0;

for outer=1:6
    figure
    hold on
    mini=[];
    for i=1:50
        count=count+1;
%         plot(time, EEG.data(this_one,150:end,count))
        mini(i,:)=EEG.data(this_one,150:end,count);
    end
    plot(time,mean(mini))
    y=ylim;
    plot(zeros(length([y(1):y(2)])),[y(1) : y(2)],'Color',[.5 .5 .5])
    plot(time, zeros(length(time)),'Color',[.5 .5 .5])
end



%% SE
plot([RT.(Conds{cond}) RT.(Conds{cond})], y1,'Color',Colour.(Exp{exp}).(Lock{lock}){cond},'Linestyle','--','Linewidth',2)
                
                %% plot standard error
                x=plot_times.(Exp{exp}).(Lock{lock})                  ;                  %#initialize x array
                Y1=to_plot+to_plot_sem;                   %#create first curve
                Y2=to_plot-to_plot_sem;                  %#create second curve
                X=[x,fliplr(x)];                %#create continuous x value array for plotting
                Y=[Y1,fliplr(Y2)]; 
                A=fill(X,Y,'k')%#create y values for out and then back
                A.EdgeColor=Colour.(Exp{exp}).(Lock{lock}){cond};
                A.FaceColor=Colour.(Exp{exp}).(Lock{lock}){cond};
                A.FaceAlpha=.2;
                
                tempx=[time,fliplr(time)];
                tempy=[SE_upper,fliplr(SE_lower)];
                A=fill(tempx,tempy,'k')
                A.EdgeColor=colour;
                A.FaceColor=colour;
                A.FaceAlpha=.2;
                
