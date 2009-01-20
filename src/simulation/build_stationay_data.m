function build_stationary_data(varargin)
% BUILD_SIMULATED_DATA    Builds simulated focal adhesion data with known
%                         properties for use in analyzing the quality of
%                         the designed algorithms for studying focal
%                         adhesions
%
%   Options:
%
%       -debug: set to 1 to output debugging information, defaults to 0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

i_p = inputParser;
i_p.FunctionName = 'BUILD_SIMULATED_DATA';

i_p.addParamValue('debug',0,@(x)x == 1 || x == 0);
i_p.addParamValue('output_dir', '.', @ischar);

i_p.parse(varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ad_mean_intensity = 0.4237;
ad_int_steps = 10;

background_mean_intensity = 0.1220;

background_noise_var = 0.004;

max_ad_size = 10;

ad_padding = ceil(max_ad_size*0.8);

start_ad_size = 1;

field_size = [2*ad_padding+max_ad_size, ... 
              max_ad_size^2 - max_ad_size*(start_ad_size - 1) + ad_padding*(max_ad_size - start_ad_size + 2)];

output_dir = fullfile('..','..','data','simulation','stationary','Images','Paxillin');

image_number = 25+2;

%Clear out the directory currently holding the adhesions
png_files = dir(fullfile(output_dir, '*.png'));
for i = 1:size(png_files,1), delete(fullfile(output_dir, png_files(i).name)); end

image_size = [];
for this_i_num = 2:(image_number - 1)
    image = [];
    for ad_intensity = background_mean_intensity:(ad_mean_intensity - background_mean_intensity)/(ad_int_steps - 1):ad_mean_intensity
        this_row = imnoise(zeros(field_size),'gaussian',background_mean_intensity,background_noise_var);
        for this_ad_size = start_ad_size:max_ad_size
            temp_ad = fspecial('gaussian',this_ad_size,this_ad_size/3);
            temp_ad = temp_ad * (1/mean(mean(temp_ad))) * ad_intensity;
            assert(size(temp_ad,1) == size(temp_ad,2));

            row_range = floor(size(this_row,1)/2)-floor((size(temp_ad,1) - 1)/2):floor(size(this_row,1)/2)+ceil((size(temp_ad,1) - 1)/2);
            assert(size(row_range,2) == size(temp_ad,1), '%d, %d',size(row_range,2), size(temp_ad,1));

            col_range_start = ad_padding*(this_ad_size - start_ad_size + 1) + max_ad_size*(this_ad_size - start_ad_size) + ...
                (max_ad_size/2) - floor((size(temp_ad,1) - 1)/2);
            col_range = col_range_start : col_range_start + ceil((size(temp_ad,1) - 1)/2) + floor((size(temp_ad,1) - 1)/2);
            assert(size(col_range,2) == size(temp_ad,1), '%d, %d',size(col_range,2), size(temp_ad,1));

             this_row(row_range,col_range) = temp_ad;
        end
        image = [image; this_row];
    end
    image_size = size(image);

    if (not(exist('side_image','var')))
        %Create an image to be placed on the side apart from all the other images
        side_ad_size = 3;
        assert(side_ad_size <= max_ad_size, 'Side adhesion size must be less than or equal to the max adhesion size');
        temp_ad = fspecial('gaussian',side_ad_size,side_ad_size/3);
        temp_ad = temp_ad * (ad_mean_intensity/mean(mean(temp_ad)));

        side_image = zeros(size(image,1),2*ad_padding+size(temp_ad,2));
        row_range = 1:size(temp_ad,1);
        row_shift = floor((size(side_image,1) - size(temp_ad,1))/2);
        row_range = row_range + row_shift;

        col_range = 1:size(temp_ad,2);
        col_shift = floor((size(side_image,2) - size(temp_ad,2))/2);
        col_range = col_range + col_shift;

        side_image(row_range,col_range) = temp_ad;
    end
    
    sprintf_format = ['%0', num2str(length(num2str(image_number))), 'd'];
    if (not(exist(output_dir,'dir'))); mkdir(output_dir); end
    imwrite([image,side_image], fullfile(output_dir,[sprintf(sprintf_format,this_i_num), '.png']))

end

%Build the initial and final blank image
sprintf_format = ['%0', num2str(length(num2str(image_number))), 'd'];
if (not(exist(output_dir,'dir'))); mkdir(output_dir); end
imwrite([zeros(image_size), side_image], fullfile(output_dir,[sprintf(sprintf_format,1), '.png']))

sprintf_format = ['%0', num2str(length(num2str(image_number))), 'd'];
if (not(exist(output_dir,'dir'))); mkdir(output_dir); end
imwrite([zeros(image_size), side_image], fullfile(output_dir,[sprintf(sprintf_format,image_number), '.png']))