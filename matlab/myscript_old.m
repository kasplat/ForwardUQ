%% read the files
addpath('/Users/jd1336/Google Drive/Team_ForwardUQ/code_data/ReadData3D_version1k/');
[label,label_info]=ReadData3D('Label.mha');
[va,va_info]=ReadData3D('VA_ICD_004_SA.mha');

%% disply the image
for i = 1: 15
    imshow(va(:,:,i),[min(min(va(:,:,i))) max(max(va(:,:,i))) ]);
    min_max_imgint(i,:) = [min(min(va(:,:,i))) max(max(va(:,:,i))) ];
end 




%% display the labels

for i = 1: 15
    imshow((label(:,:,i)),[ min(min(label(:,:,i))) max(max(label(:,:,i)))]);
    
     pause
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

u=max_intensity; l = min_intensity;  d= u-l

t=1:1:100

for i=t
    normal_t1(i)=(l+d*i/100)
    for j = i+1:t
         grey_t2(i,j)=(l+d*j/100)
    end
end


for 



% 1% threshold means inte<12.1 is normal i.e small normal region
% 100% threshodl means int<220 is normal i.e. everyhting is normal

% 
%



