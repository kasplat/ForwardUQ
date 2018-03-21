%% read the files
addpath('/Users/jd1336/Google Drive/Team_ForwardUQ/code_data/ReadData3D_version1k/');

[label,label_info]=ReadData3D('Label.mha');
[va,va_info]=ReadData3D('VA_ICD_004_SA.mha');

%% disply the image
for i = 1: 15
    imshow(va(:,:,i),[min(min(va(:,:,i))) max(max(va(:,:,i))) ]);
    min_max_imgint(i,:) = [min(min(va(:,:,i))) max(max(va(:,:,i))) ];
%     pause;
end 




%% display the labels



for i = 1: 15
    imshow((label(:,:,i)),[ min(min(label(:,:,i))) max(max(label(:,:,i)))]);
    
%      pause
end 


%% intensity study
% I don?t think it is a good idea to use%% read the files
addpath('/home/kesavan/MatlabProjects/ReadData3D_version1k');
[label,label_info]=ReadData3D('Label.mha');
[va,va_info]=ReadData3D('VA_ICD_004_SA.mha');

%% disply the image
for i = 1: 15
    imshow(va(:,:,i),[min(min(va(:,:,i))) max(max(va(:,:,i))) ]);
    min_max_imgint(i,:) = [min(min(va(:,:,i))) max(max(va(:,:,i))) ];
%     pause;
end 




%% display the labels



for i = 1: 15
    imshow((label(:,:,i)),[ min(min(label(:,:,i))) max(max(label(:,:,i)))]);
    
%      pause
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


min_intensity = min(va(find(label>0)))
max_intensity = max(va(find(label>0)))


% normal tissue : intensity< 20% of intensities
% gray tissue   : intensity< 40% of the intensities
% remainder as scar

u = max_intensity; l = min_intensity;  d= u-l

step_size1=1
step_size2=1

thresholds = zeros(size(1:step_size1:100,2)*(size(1:step_size2:100,2)-1)/2,2);
row_num = 0;
for i=1:step_size1:100  % changing the middle one is the step size
    for j = i+1:step_size2:100  % step size must be changed in here as well.
         row_num = row_num + 1;
        thresholds(row_num, 1)=(l+d*i/100);
%         disp(j);
        thresholds(row_num, 2)=(l+d*j/100);
       
    end
end
thresholds = thresholds(1:row_num,:);

% va_labelled = va;
% va_new = cat(6, va);   % increases the number of dims to use
labels = zeros(105*101*15,3);  % make a really big matrix that will store all the classifications
for i = 1:numel(va)
%     disp(va(i));
    value = va(i);
    if value == 0
        continue
    else
        for j= 1:length(thresholds) % go through all rows
            % loop through all lows using my spreadsheet
        
            if value < thresholds(j,1)  % if less than low
                labels(i,1) = labels(i,1) + 1;  % increment low
            elseif value < thresholds(j,2) % if less than high
                labels(i,2) = labels(i,2) + 1;% increment middle
            else % must be high
                labels(i,3) = labels(i,3) + 1;%incrememnt high
            end
            % classified the distribution and stored back in matrix
        end
    end            
end



figure
step_size = 2;
labels_thresholds=zeros(105,101,size(thresholds,1))
for i = 10
     for t_row = 1:step_size:size(thresholds,1)
         % make zeroed out image
         im = zeros(105,101);
         for x = 1:105
             for y = 1:101
                if label(x,y,i)>0
                    if va(x,y,i) < thresholds(t_row,1)
                        im(x,y) = 3;  % low
                    elseif va(x,y,i) < thresholds(t_row,2)
                        im(x,y) = 2;  % medium
                    else
                        im(x,y) = 1;  % high
                    end
                else
                    im(x,y)=0;
                 % for cell in va slice
            % classify that cell
                end
             end
         end
         imshow(im,[0,3])
         title(['t1: ' int2str(thresholds(t_row,1)) ' t2: ' int2str(thresholds(t_row,2))])
%          pause(.1);
         % show image
     end
end 


idexregion = kmeans(labels,3);
out = anova(idexregion);
eva = evalclusters(labels,'kmeans','CalinskiHarabasz','KList',[20:30])
plot

%colormap = normr(labels);
% normalize labels to turn it into colors
n = sqrt( sum( labels.^2, 2 ) );
% patch to overcome rows with zero norm
 n( n == 0 ) = 1;
nA = bsxfun( @rdivide, labels, n );
% nA = nA(any(nA,2),:);  %  remove zero rows

%color each pixel according to their most common classification and then
%display them

nA=colormap(jet)
for i = 1: 15
%    imshow(va(:,:,i),[min(min(va(:,:,i))) max(max(va(:,:,i))) ]);  % old
%    colormap
     imshow(va(:,:,i), nA)
%     imwrite(va(:,:,i), nA, char(sprintf("heart_layer_%i.jpeg",i)),'jpeg');

%     min_max_imgint(i,:) = [min(min(va(:,:,i))) max(max(va(:,:,i))) ];
    pause;
end  %the absolute values of image 
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


min_intensity = min(va(find(label>0)))
max_intensity = max(va(find(label>0)))


% normal tissue : intensity< 20% of intensities
% gray tissue   : intensity< 40% of the intensities
% remainder as scar

u=max_intensity; l = min_intensity;  d= u-l

t=1:1:100;  % changing the middle one is the step size
thresholds = zeros(1500,2)
row_num = 1;
for i=t
    for j = i+1:100  % step size must be changed in here as well.
        thresholds(row_num, 1)=(l+d*i/100);
        disp(j);
        thresholds(row_num, 2)=(l+d*j/100);
        row_num = row_num + 1;
    end
end
thresholds = thresholds(any(thresholds, 2),:);

% va_labelled = va;
% va_new = cat(6, va);   % increases the number of dims to use
labels = zeros(105*101*15,3);  % make a really big matrix that will store all the classifications
for i = 1:numel(va)
%     disp(va(i));
    value = va(i);
    if value == 0
        continue
    else
        for j= 1:length(thresholds) % go through all rows
            % loop through all lows using my spreadsheet
        
            if value < thresholds(j,1)  % if less than low
                labels(i,1) = labels(i,1) + 1;  % increment low
            elseif value < thresholds(j,2) % if less than high
                labels(i,2) = labels(i,2) + 1;% increment middle
            else % must be high
                labels(i,3) = labels(i,3) + 1;%incrememnt high
            end
            % classified the distribution and stored back in matrix
        end
    end            
end

step_size = 2;
for i = 3: 15
%     imshow(va(:,:,i), nA)
     for t_row = (1:size(thresholds)/floor(step_size))*step_size
         % make zeroed out image
         im = zeros(105,101);
         for x = 1:105
             for y = 1:101
                if va(x,y,i) < thresholds(t_row,1)
                    im(x,y) = 0;  % low
                elseif va(x,y,i) < thresholds(t_row,2)
                    im(x,y) = .5;  % medium
                else
                    im(x,y) = 1;  % high
                end
                 % for cell in va slice
            % classify that cell
             end
         end
         imshow(im)
         pause(.5);
         % show image
     end
end 

nA = labels(any(labels,2),:);
idexregion = kmeans(nA,5);

figure
for i = 1:5
   subplot(1,5,i)
   bar(mean(nA(idexregion==i,:)))
    
    
end



out = anova(idexregion);
eva = evalclusters(meas,'kmeans','CalinskiHarabasz','KList',[1:6])


%colormap = normr(labels);
% normalize labels to turn it into colors
n = sqrt( sum( labels.^2, 2 ) );
% patch to overcome rows with zero norm
n( n == 0 ) = 1;
nA = bsxfun( @rdivide, labels, n );
nA = nA(any(nA,2),:);  %  remove zero rows

%color each pixel according to their most common classification and then
%display them

for i = 1: 15
%    imshow(va(:,:,i),[min(min(va(:,:,i))) max(max(va(:,:,i))) ]);  % old
%    colormap
     imshow(va(:,:,i), nA)
%     imwrite(va(:,:,i), nA, char(sprintf("heart_layer_%i.jpeg",i)),'jpeg');

%     min_max_imgint(i,:) = [min(min(va(:,:,i))) max(max(va(:,:,i))) ];
    pause;
end 