%% read the files
%addpath('/Users/jd1336/Google Drive/Team_ForwardUQ/ForwardUQ/matlab/ReadData3D_version1k/');
addpath('C:\Users\Kesavan\Documents\Matlab_Projects\ForwardUQ\matlab\ReadData3D_version1k\');
[label,label_info]=ReadData3D('Label.mha');
[va,va_info]=ReadData3D('VA_ICD_004_SA.mha');

%% display the image
for i = 1: 15
    imshow(va(:,:,i),[min(min(va(:,:,i))) max(max(va(:,:,i))) ]);
    min_max_imgint(i,:) = [min(min(va(:,:,i))) max(max(va(:,:,i))) ];
%    pause;
end 

%% display the labels
for i = 1: 15
    imshow((label(:,:,i)),[ min(min(label(:,:,i))) max(max(label(:,:,i)))]);
%    pause
end 

%% intensity study
% I don?t think it is a good idea to use the absolute values of image 
%intensities, because the intensities in different patients may vary a lot,
%and also different scanners may have great difference too, so you would 
%better consider using percentage of the whole intensities in the ventricle
%wall to segment different tissues.
% 
% One example:
% 
% The intensities in one ventricle wall (between epicardium and 
%endocardium) are from 10 to 220, you can select the tissue with smaller 
% than 20% of the intensities (220 -10=210; 210*0.20=41; 10+41=51) as 
%normal tissue, which is 51 in the example; and select the tissue with 
%smaller than 40% of the intensities as grey zone, which is 
%94 (10+210*0.4); and the rest tissue is core scar. So one set of 
%parameters mentioned here should be 20% and 40%, and you can choose other 
%values as you want. Like range [10%-40%] as the threshold value between 
%normal tissue and Gray zone, range [30%-60%] as the threshold value 
%between core scar and Gray zone.
% 
% Hope my explanation can help you select these values.
% The whole image intensity is from 0 to 180, but the image intensity in the 
% segmented tissue is from 1 to 130, so the values to segment normal tissue 
% and gray zone should vary from 15% * (130 -1) to 25% *(130 -1), but the 
% values to segment gray zone and core scar should be calculated differently,
% Here I only take 15% as am example. 15%*(130-1) is about 20, so from 20 to 
% 130 is infarcted tissue, then you can segment the gray zone and core scar
% from 20 + 10%*(130-20)=31 to 20+60%*(130-20)=86, so this means that you can
% change the values from 31 to 86 with the steps you want, but you should not
% make the step too small, 5% (5%*110=5.5, so you can use 5) may be a good 
% value for the step, but you can choose a smaller one if you think this 
% value is too big. 
% Then you can repeat these steps for other threshold values.
%


%% Threshold code
min_intensity_tissue = min(va(label>0));
%max_intensity_tissue = max(va(label>0));
max_intensity_tissue = 72;   % hardcoded per Dongdong's email
% normal tissue : intensity< t1% of intensities
% gray tissue   : intensity< t2% of the intensities
% remainder as scar
u = max_intensity_tissue; l = min_intensity_tissue;  d= u-l;
step_size1=2;
step_size2=2;
% Create the zero'd out arrays. Making it larger than necessary since extra
% rows will be deleted later anyways.
thresholds_relative = zeros(size(1:step_size1:100,2)*(size(1:step_size2:100,2)-1)/2,4);
thresholds_absolute = zeros(size(1:step_size1:100,2)*(size(1:step_size2:100,2)-1)/2,2);
row_num = 0;
% set all thresholds
for i=15:step_size1:25
    for j = 10:step_size2:60
        row_num = row_num + 1;
        thresholds_relative(row_num, 1)=l+d*i/100;
        thresholds_relative(row_num, 2)=l+d*j/100;
        thresholds_relative(row_num, 3)=i;
        thresholds_relative(row_num, 4)=j;
        thresholds_absolute(row_num, 1)=l+d*i/100;
        t1 = thresholds_absolute(row_num, 1);
        thresholds_absolute(row_num, 2)=t1+(u-t1)*j/100;
    end
end
thresholds_relative = thresholds_relative(1:row_num,:);  % remove extra rows
thresholds_absolute = thresholds_absolute(1:row_num,:);


%% generate labels
labelled_image = zeros(105*101*15,4);  % make a really big matrix that will store all the classifications
for i = 1:numel(va)
    value = va(i);
    if value == 0
        continue
    else
        for j= 1:length(thresholds_relative) % go through all rows
            if label(i) == 0
               labelled_image(i,4) = 1;
               continue;
            end
            if value < thresholds_relative(j,1)  % if less than low
                labelled_image(i,1) = labelled_image(i,1) + 1; % increment low
            elseif value < thresholds_absolute(j,2) % if less than high
                labelled_image(i,2) = labelled_image(i,2) + 1; % increment middle
            else % must be high
                labelled_image(i,3) = labelled_image(i,3) + 1; % increment high
            end
            % classified the distribution and stored back in matrix
        end
    end            
end


%% get all the labelled slices
healthy_slices = [];
scar_slices = [];
healthy_only = [];
scar_only = [];
total_slices = [];
for slice_num = 0:14
   current_slice = labelled_image((1 + slice_num*101*105):(105*101 + slice_num*101*105),:);
   current_slice( all( current_slice == 0, 2 ), : ) = [];
   current_slice(current_slice(:,4) ~= 0,:) = []; % remove the unlabelled slices
   healthy_slices(slice_num+1) = size(current_slice(current_slice(:,1) < max(current_slice(:,1)) & current_slice(:,1) > 0, :), 1);
   scar_slices(slice_num+1) = size(current_slice(current_slice(:,3) < max(current_slice(:,3)) & current_slice(:,3) > 0, :), 1);
   healthy_only(slice_num+1) = size(current_slice(current_slice(:,1) == max(current_slice(:,1)),:),1);
   scar_only(slice_num+1) = size(current_slice(current_slice(:,3) == max(current_slice(:,3)),:),1);
   total_slices(slice_num+1) = size(current_slice,1);
end

%% generate image
figure
step_size = 10;
labels_thresholds=zeros(105,101,size(thresholds_relative,1));
num_of_heart = 0;
for i = 3:15
     for t_row = 1:step_size:size(thresholds_relative,1)
         im = zeros(105,101); % zeroed out image
         for x = 1:105
             for y = 1:101
                if label(x,y,i)>0
                    num_of_heart = num_of_heart + 1;
                    if va(x,y,i) < thresholds_absolute(t_row,1)
                        im(x,y) = 1;  % healthy
                    elseif va(x,y,i) < thresholds_absolute(t_row,2)
                        im(x,y) = 2;  % border
                    else
                        im(x,y) = 3;  % scar
                    end
                else
                    im(x,y)=0;
                end
             end
         end
         subplot(1,2,1)
        
         imshow(im,[0,3])
         title(['t1: ' int2str(thresholds_relative(t_row,1)) ' t2: ' int2str(thresholds_relative(t_row,2))])
         xlabel({['percentage: t1: ', int2str(thresholds_relative(t_row,3)), '%. t2: ',...
             int2str(thresholds_relative(t_row,4)), '%.' ];
             ['Number of Healthy-Border nodes: ', int2str(healthy_slices(i)),...
             ];['Number of Healthy only nodes: ', num2str(healthy_only(i))]})
         subplot(1,2,2)
         imshow((label(:,:,i)),[ min(min(label(:,:,i))) max(max(label(:,:,i)))]);
         title(['JHU labels, layer:' int2str(i)])
         va_i = va(:,:,i);
         label_i = label(:,:,i);
         xlabel({['min intensity: ', int2str(min(va_i(label_i>0))),...
             ' max intensity: ', int2str(max(max(va_i(label_i>0)))) ];...
                ['Number of Scar-Border nodes: ', int2str(scar_slices(i)),...
                ];['Number of Scar only nodes:', num2str(scar_only(i))]})
         %saveas(gcf, char(sprintf("/home/kesavan/MatlabProjects/ForwardUQ/matlab/heartpics/%i/heart_layer_%i", i, t_row)));
         pause(.05);
     end
end

sum(healthy_only) % 2683
sum(scar_only) % 93
sum(healthy_slices) % 1639
sum(scar_slices) % 1775


%% find optimal clusters using built in matlab evalclusters
idexregion = kmeans(labelled_image,3);
out = anova(idexregion);
eva = evalclusters(labelled_image,'kmeans','CalinskiHarabasz','KList',0:10);

%% color display
%color each pixel according to their most common classification and then
%display them
n = sqrt( sum( labelled_image.^2, 2 ) ); % normalize labels to turn it into colors
n( n == 0 ) = 1;  % patch to overcome rows with zero norm
nA = bsxfun( @rdivide, labelled_image, n );
% nA = nA(any(nA,2),:);  %  remove zero rows
% default coloring
%nA=colormap(jet);

for i = 1: 15
%     imshow(va(:,:,i),[min(min(va(:,:,i))) max(max(va(:,:,i))) ]);  % old
     imshow(va(:,:,i), nA)
%     imwrite(va(:,:,i), nA, char(sprintf("heart_layer_%i.jpeg",i)),'jpeg');
%     min_max_imgint(i,:) = [min(min(va(:,:,i))) max(max(va(:,:,i))) ];
    pause;
end  %the absolute values of image 

%% print scatterplot of classified thresholds
labelled_image( all( labelled_image < .02, 2 ), : ) = [];
jitterAmount = 10;                                       % jitter taken from online
jitterValuesX = 2*(rand(size(labelled_image(:,1)))-0.5)*jitterAmount;   % +/-jitterAmount max
jitterValuesY = 0; % 2*(rand(size(labelled_image(:,1)))-0.5)*jitterAmount;
jitterValuesZ = 2*(rand(size(labelled_image(:,1)))-0.5)*jitterAmount;
scatter3(labelled_image(:,1) + jitterValuesX, ...
         labelled_image(:,2) + jitterValuesY, ...
         labelled_image(:,3) + jitterValuesZ)
% Graph without jitter
%scatter3(labelled_image(:,1), ...
%         labelled_image(:,2), ...
%         labelled_image(:,3))     
 
title("Number of times a node was classified as a certain intensity")
xlabel("Scar")
ylabel("Border")
zlabel("Healthy")

plot(va_i)

%% remove all healthy and scar and print scatterplot of classified thresholds
labelled_image( all( labelled_image == 0, 2 ), : ) = [];
labelled_image( any(labelled_image == max(labelled_image), 2 ),:) = [];

jitterAmount = 10;                              % jitter taken from online
jitterValuesX = 2*(rand(size(labelled_image(:,1)))-0.5)*jitterAmount;   % +/-jitterAmount max
jitterValuesY = 0; % 2*(rand(size(labelled_image(:,1)))-0.5)*jitterAmount;
jitterValuesZ = 2*(rand(size(labelled_image(:,1)))-0.5)*jitterAmount;
scatter3(labelled_image(:,1) + jitterValuesX, ...
         labelled_image(:,2) + jitterValuesY, ...
         labelled_image(:,3) + jitterValuesZ)
%scatter3(labelled_image(:,1), ...
%         labelled_image(:,2), ...
%         labelled_image(:,3))     
 
title("Number of times a node was classified as a certain intensity")
xlabel("Scar")
ylabel("Border")
zlabel("Healthy")

plot(va_i)

%% make a histogram across the 2 lines *note mixed it up a bit ahead
scar_cells = labelled_image(:,1);
border_cells = labelled_image(:,2);
healthy_cells = labelled_image(:,3);
hist(healthy_cells(healthy_cells > 0),100);



%% scatterplot of scar and healthy
healthy_only = labelled_image(labelled_image(:,3) == 0,1);
%hist(healthy_only)
healthy_only = healthy_only(healthy_only < max(healthy_only));
healthy_only = healthy_only(healthy_only > 0);


scar_only = labelled_image(labelled_image(:,1) == 0,3);
scar_only = scar_only(scar_only < max(scar_only));
scar_only = scar_only(scar_only > 0);

hist(healthy_only);
title("Tissues always classified as border or healthy");
xlabel("Number of times labelled as healthy");
ylabel("Number of nodes");
hist(scar_only,100);
title("Tissues always classified as border or scar");
xlabel("Number of times labelled as healthy");
ylabel("Number of nodes");

%% make a plot across both lines
healthy_only = labelled_image(labelled_image(:,3) == 0,1:2);

% labelled_image(labelled_image(:,3) == 0,1:2) = healthy_only; % to
% reassign

healthy_only = healthy_only(healthy_only < max(healthy_only,2), :);
healthy_only = healthy_only(healthy_only(:,2) > 0,:);

scar_only = labelled_image(labelled_image(:,1) == 0,2:3);
scar_only = scar_only(scar_only < max(scar_only,2),:);
scar_only = scar_only(scar_only(:,2) > 0,:);
    
scatter(healthy_only(:,1), healthy_only(:,2));
title("Tissues always classified as border or healthy");
xlabel("Number of times labelled as healthy");
ylabel("Number of nodes");
scatter(scar_only(:,1), scar_only(:,2));
title("Tissues always classified as border or scar");
xlabel("Number of times labelled as healthy");
ylabel("Number of nodes");

%% Scatterplot with lines created on meeting on 4/11/2018
hold on;
plot(reshape(va_i,105*101,1),'o')
plot(0.15*72.*ones(101*105,1),'b');
plot(0.25*72.*ones(101*105,1),'b');
plot(0.15*72+0.1*(72-0.15*72).*ones(101*105,1),'r');
plot(0.15*72+0.6*(72-0.15*72).*ones(101*105,1),'r');
plot(0.25*72+0.6*(72-0.25*72).*ones(101*105,1),'g');
plot(0.25*72+0.1*(72-0.25*72).*ones(101*105,1),'g');

%% Region Growing solution
frame1 = mat2gray(va(:,:,5));
J = regiongrowing(frame1);
image(J)

%%  DBSCAN over random points in healthy only (as it currently is too big)
idx = randperm(size(healthy_only, 1));
indexToGroup1 = (idx<=10000);
group1 = healthy_only(indexToGroup1,:);
[outcome, noisy_points] = DBSCAN(group1, .5, 5);
colormap(jet)
scatter(group1(:,1), group1(:,2), 10, outcome);
scatter(group1(:,1), group1(:,2), 10, noisy_points);

[outcome, noisy_points] = DBSCAN(healthy_only(:,2), .5, 10);
idx = randperm(size(scar_only, 1));
indexToGroup2 = (idx<=10000);
group2 = scar_only(indexToGroup2,:);
[outcome, noisy_points] = DBSCAN(group2(:,2), 5, 5);
scatter(group2(:,1), group2(:,2), 10, outcome);
scatter(group2(:,1), group2(:,2), 10, noisy_points);

%% DBSCAN over all points
% add new columns for the color on labelled image
new_col = zeros(size(labelled_image,1),1);
clustered_image = [labelled_image new_col];

% classify all the unlabelled, scar, healthy onlys. others classified later
for i = 1:size(clustered_image,1)
   if clustered_image(i,4) == 1
       clustered_image(i,5) = 1; % unlabelled
   elseif clustered_image(i,2) == 0
       if clustered_image(i,3) == 0
           clustered_image(i,5) = 2; % always healthy
       end
       if clustered_image(i,1) == 0
            clustered_image(i,5) = 3; % always scar
       end
   end
end

healthy_border = clustered_image(clustered_image(:,3) == 0 & clustered_image(:,1) > 0 & clustered_image(:,1)  < max(clustered_image(:,1)),1);
[outcome, noisy_points_healthy] = DBSCAN(healthy_border, .5, 5);
outcome = outcome + 3;  % make outcomes 4 to n clusters
clustered_image(clustered_image(:,3) == 0 & clustered_image(:,1) > 0 & clustered_image(:,1)  < max(clustered_image(:,1)),5) = outcome;

scar_border = clustered_image(clustered_image(:,1) == 0 & clustered_image(:,3) > 0 & clustered_image(:,3)  < max(clustered_image(:,3)),3);
% dist_scar = pdist2(scar_border, scar_border);
% hist(dist_scar);
[outcome, noisy_points_scar] = DBSCAN(scar_border, 2, 10);
outcome = outcome + max(clustered_image(:,5));  % make outcomes #n clusters
clustered_image(clustered_image(:,1) == 0 & clustered_image(:,3) > 0 & clustered_image(:,3)  < max(clustered_image(:,3)),5) = outcome;

%% show the clustered image

map = colormap(jet);
for i = 3:12
     subplot(1,2,1);
     clus_pic = zeros(105,101); % zeroed out image
     for x = 1:105
         for y = 1:101
             clus_pic(x,y) = clustered_image((i-1)*101*105 + y*105 + x,5);
         end
     end
     map = colormap(jet);
     imshow(clus_pic, map)
     subplot(1,2,2);
     imshow((label(:,:,i)),[ min(min(label(:,:,i))) max(max(label(:,:,i)))]);
         title(['JHU labels, layer:' int2str(i)])
     pause();
end



