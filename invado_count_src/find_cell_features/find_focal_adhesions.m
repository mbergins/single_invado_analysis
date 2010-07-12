function find_focal_adhesions(I_file,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i_p = inputParser;
i_p.FunctionName = 'FIND_FOCAL_ADHESIONS';

i_p.addRequired('I_file',@(x)exist(x,'file') == 2);

i_p.parse(I_file);

i_p.addParamValue('registration_binary',fullfile(fileparts(I_file),'binary_shift.png'), ...
    @(x)exist(x,'file')==2);
i_p.addParamValue('filter_size',11,@(x)isnumeric(x) && x > 1);
i_p.addParamValue('filter_file',fullfile(fileparts(I_file),'puncta_threshold.csv'), ...
    @(x)exist(x,'file')==2);
i_p.addParamValue('output_dir', fileparts(I_file), @(x)exist(x,'dir')==7);
i_p.addParamValue('min_max_file',fullfile(fileparts(I_file),'puncta_image_range.csv'),@(x)exist(x,'file') == 2)
i_p.addParamValue('debug',0,@(x)x == 1 || x == 0);

i_p.parse(I_file,varargin{:});

%read in binary shift file
binary_shift = logical(imread(i_p.Results.registration_binary));
min_row = find(sum(binary_shift,2),1,'first');
max_row = find(sum(binary_shift,2),1,'last');
min_col = find(sum(binary_shift),1,'first');
max_col = find(sum(binary_shift),1,'last');

cell_mask = logical(imread(fullfile(fileparts(I_file),'cell_mask.png')));

%read in and normalize the input focal adhesion image
focal_image  = imread(I_file);
scale_factor = double(intmax(class(focal_image)));
focal_image  = double(focal_image)/scale_factor;
only_reg_focal_image = focal_image(min_row:max_row, min_col:max_col);

%read in the global min max file, if present, will be used in the last part
%to output a normalized copy of the image with the puncta highlighted
if (exist(i_p.Results.min_max_file, 'file'))
    min_max = csvread(i_p.Results.min_max_file);
else
    min_max = [min(only_reg_focal_image(:)), max(only_reg_focal_image(:))];
end

%read in the threshold from the file produced by the threshold selection
%script
filter_thresh = csvread(i_p.Results.filter_file);

%Add the folder with all the scripts used in this master program
addpath('matlab_scripts');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
I_filt = fspecial('disk',i_p.Results.filter_size);
blurred_image = imfilter(only_reg_focal_image,I_filt,'same',mean(only_reg_focal_image(:)));
high_passed_image = only_reg_focal_image - blurred_image;
threshed_image = logical(im2bw(high_passed_image,filter_thresh));

%identify and remove adhesions on the immediate edge of the image
threshed_image = remove_edge_adhesions(threshed_image);

%place the thresholded image back in place
threshed_temp = zeros(size(focal_image));
threshed_temp(binary_shift) = threshed_image;
threshed_image = threshed_temp;

puncta = bwlabel(threshed_image,8);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove adhesions outside mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:max(puncta(:))
    assert(any(any(puncta == i)), 'Error: can''t find ad number %d', i);
    this_ad = zeros(size(puncta));
    this_ad(puncta == i) = 1;
    if (sum(sum(this_ad & cell_mask)) == 0)
        puncta(puncta == i) = 0;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Renumber adhesions to be sequential
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ad_nums = unique(puncta);
assert(ad_nums(1) == 0, 'Background pixels not found after building adhesion label matrix')
for i = 2:length(ad_nums)
    puncta(puncta == ad_nums(i)) = i - 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Build adhesion perimeters image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
puncta_perim = zeros(size(puncta));
for i = 1:max(puncta(:))
    assert(any(any(puncta == i)), 'Error: can''t find ad number %d', i);
    this_ad = zeros(size(puncta));
    this_ad(puncta == i) = 1;
    puncta_perim(bwperim(this_ad)) = i;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Write the output files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imwrite(double(puncta)/2^16,fullfile(i_p.Results.output_dir, 'puncta_labeled.png'),'bitdepth',16);
imwrite(double(puncta_perim)/2^16,fullfile(i_p.Results.output_dir, 'puncta_labeled_perim.png'),'bitdepth',16);
imwrite(im2bw(puncta),fullfile(i_p.Results.output_dir, 'puncta_binary.png'));

addpath(genpath('..'))

scaled_image = double(imread(I_file));
scaled_image = scaled_image - min_max(1);
scaled_image = scaled_image .* (1/min_max(2));
scaled_image(not(binary_shift)) = 0;

imwrite(create_highlighted_image(scaled_image, im2bw(puncta),'color_map',[1 0 0], 'mix_percent',0.5), ...
    fullfile(i_p.Results.output_dir, 'puncta_highlight.png'));

if (i_p.Results.debug)
   scaled_high_pass = (high_passed_image - min(high_passed_image(:)))/(max(high_passed_image(:)) - min(high_passed_image(:)));
   imwrite(scaled_high_pass, fullfile(i_p.Results.output_dir, 'high_passed.png'));
end