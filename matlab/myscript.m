%% read the files
%addpath('/Users/jd1336/Google Drive/Team_ForwardUQ/code_data/ReadData3D_version1k/');
addpath('/home/kesavan/MatlabProjects/ForwardUQ/matlab/ReadData3D_version1k/');
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
max_intensity_tissue = max(va(label>0));
% normal tissue : intensity< 20% of intensities
% gray tissue   : intensity< 40% of the intensities
% remainder as scar
u = max_intensity_tissue; l = min_intensity_tissue;  d= u-l;
step_size1=1;
step_size2=1;
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
labelled_image = zeros(105*101*15,3);  % make a really big matrix that will store all the classifications
for i = 1:numel(va)
    value = va(i);
    if value == 0
        continue
    else
        for j= 1:length(thresholds_relative) % go through all rows
            % loop through all lows using my spreadsheet
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

%% generate image
figure
step_size = 2;
labels_thresholds=zeros(105,101,size(thresholds_relative,1));
for i = 2:13
     for t_row = 1:step_size:size(thresholds_relative,1)
         im = zeros(105,101); % zeroed out image
         for x = 1:105
             for y = 1:101
                if label(x,y,i)>0
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
         xlabel(['percentage: t1: ' int2str(thresholds_relative(t_row,3)) '%. t2: ' int2str(thresholds_relative(t_row,4)) '%.' ])
         subplot(1,2,2)
         imshow((label(:,:,i)),[ min(min(label(:,:,i))) max(max(label(:,:,i)))]);
         title(['JHU labels, layer:' int2str(i)])
         va_i = va(:,:,i);
         label_i = label(:,:,i);
         xlabel(['min intensity: ' int2str(min(va_i(label_i>0))) ' max intensity: ' int2str(max(max(va_i(label_i>0)))) ])
         %saveas(gcf, char(sprintf("/home/kesavan/MatlabProjects/ForwardUQ/matlab/heartpics/%i/heart_layer_%i", i, t_row)));
         pause(.05);
     end
end
g

%% find optimal clusters
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