function find_pre_birth_diffs(exp_dir,varargin)
%FIND_PRE_BIRTH_DIFFS    Searches through a given tracking matrix and a
%                        data set to produce local diff values for each
%                        puncta immediately before the puncta's birth, if
%                        such a time is available

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_all=tic;
i_p = inputParser;
i_p.FunctionName = 'FIND_PRE_BIRTH_DIFFS';

i_p.addRequired('exp_dir',@(x)exist(x,'dir') == 7);
i_p.addParamValue('debug',0,@(x)x == 1 || x == 0);

i_p.parse(exp_dir,varargin{:});

%Add the folder with all the scripts used in this master program
addpath(genpath('../find_cell_features/'));

filenames = add_filenames_to_struct(struct());

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
base_dir = fullfile(exp_dir,'individual_pictures');

%find all the image directories
image_dirs = dir(base_dir);

assert(strcmp(image_dirs(1).name, '.'), 'Error: expected "." to be first string in the dir command')
assert(strcmp(image_dirs(2).name, '..'), 'Error: expected ".." to be second string in the dir command')
assert(str2num(image_dirs(3).name) == 1, 'Error: expected the third string to be image set one') %#ok<ST2NM>

image_dirs = image_dirs(3:end);

tracking_seq = load(fullfile(base_dir,image_dirs(1).name,filenames.tracking_matrix))+1;
pre_birth_diffs = NaN*ones(size(tracking_seq));

% tracking_seq = tracking_seq(:,1:20);
% image_dirs = image_dirs(1:20);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read In Data Set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_reading = tic;
image_sets = cell(size(image_dirs,1),1);
for i = 1:size(image_dirs,1)
    image_sets{i} = read_in_file_set(fullfile(base_dir,image_dirs(i).name),filenames);
end
reading_time = toc(start_reading);
fprintf('It took %d seconds to read the image sets.\n',round(reading_time));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find Pre-birth diffs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_process = tic;
for lineage_num = 1:size(tracking_seq,1)
    pre_birth_i_num = find(tracking_seq(lineage_num,:) >= 1,1,'first') - 1;
    %if the puncta is born in image number 1, we don't have a pre-birth
    %image to look at for calculations, so we do the next best thing and
    %use the first image of the data set
    if (pre_birth_i_num < 1)
        pre_birth_i_num = 1;
    end
    
    pre_birth_image_data = image_sets{pre_birth_i_num};
    
    for i_num = 1:size(tracking_seq,2)
        if (tracking_seq(lineage_num,i_num) <= 0)
            continue;
        end
        
        puncta_num = tracking_seq(lineage_num,i_num);
        
        this_puncta = image_sets{i_num}.objects == puncta_num;
        diff_props = collect_local_diff_properties(pre_birth_image_data,this_puncta);
        
        pre_birth_diffs(lineage_num,i_num) = diff_props.Local_gel_diff;
    end
    
    if (mod(lineage_num,100) == 0)
        disp(['Processed ',num2str(lineage_num),'/',num2str(size(tracking_seq,1))]);
    end    
end
fprintf('It took %d seconds to process the pre-birth diffs.\n',round(toc(start_process)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
local_diffs = csvread(fullfile(exp_dir,'puncta_props','lin_time_series','Local_gel_diff.csv'));

output_dir = fullfile(exp_dir,'puncta_props','lin_time_series');
if (not(exist(output_dir,'dir')))
    mkdir(output_dir);
end
dlmwrite(fullfile(output_dir,'Pre_birth_diff.csv'), pre_birth_diffs);

dlmwrite(fullfile(output_dir,'Local_diff_corrected.csv'), local_diffs - pre_birth_diffs);

toc(start_all);
end

function birth_i_num = find_birth_i_num(puncta_present_logical)
%FIND_BIRTH_I_NUM    Searches through a logical matrix for switches from
%                    positive to negative and vice versa that indicate
%                    birth and death events

birth_i_num = NaN;
for i=2:length(puncta_present_logical)
    if (puncta_present_logical(i) == 0 && puncta_present_logical(i-1) == 1)
        %if the birth_i_num is not nan, we have an error since we should
        %only see one transition from 1 to 0
        assert(isnan(birth_i_num))
        
        birth_i_num = i;
    end
end

end
