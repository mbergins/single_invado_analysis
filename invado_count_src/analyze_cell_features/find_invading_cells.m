function find_invading_cells(exp_dir,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

i_p = inputParser;

i_p.addRequired('exp_dir',@(x)exist(x,'dir') == 7);

i_p.addParamValue('debug',0,@(x)x == 1 || x == 0);

i_p.parse(exp_dir,varargin{:});

if (i_p.Results.debug == 1), profile off; profile on; end

addpath(genpath('..'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in the data files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


raw_data = struct();
files = struct();

files.p_vals = fullfile(exp_dir,'adhesion_props','lin_time_series','Cell_gel_diff_p_val.csv');
files.cell_diffs = fullfile(exp_dir,'adhesion_props','lin_time_series','Cell_gel_diff.csv');
files.overlap_area = fullfile(exp_dir,'adhesion_props','lin_time_series','Overlap_region_size.csv');
files.tracking = fullfile(exp_dir,'tracking_matrices','tracking_seq.csv');

these_types = fieldnames(files);
for j = 1:length(these_types)
    this_file = files.(these_types{j});
    
    %matlab doesn't like you to reference fields that haven't been
    %created, so create files that aren't present yet before loading
    %data in
    if(isempty(strmatch(these_types{j},fieldnames(raw_data))))
        raw_data.(these_types{j}) = [];
    end
    
    if (exist(this_file,'file'))
        raw_data.(these_types{j}) = load(this_file);
    else
        error('Invado:MissingFile',['Can''t find ',this_file])
    end
end

%check that all the raw data files are the same size
these_names = fieldnames(raw_data);
poss_name_combinations = combnk(1:length(these_names),2);
for j=1:size(poss_name_combinations,1)
    assert(all(size(raw_data.(these_names{poss_name_combinations(j,1)})) == ...
        size(raw_data.(these_names{poss_name_combinations(j,2)}))))
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process and Output data files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
processed_data = process_raw_data(raw_data);

output_dir = fullfile(exp_dir,'adhesion_props');

csvwrite(fullfile(output_dir,'active_degrade.csv'),processed_data.active_degrade);
csvwrite(fullfile(output_dir,'longevity.csv'),processed_data.longevities);
% csvwrite(fullfile(output_dir,'degrade_percentage.csv'),longev_filtered_data.degrade_percentage);
1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function process_data = process_raw_data(raw_data,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

i_p = inputParser;

i_p.addRequired('raw_data',@isstruct);

i_p.addParamValue('filter_set',NaN,@islogical);

i_p.parse(raw_data,varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (isempty(strmatch('filter_set',i_p.UsingDefaults)))
    these_names = fieldnames(raw_data);
    for j=1:size(these_names,1)
        raw_data.(these_names{j}) = raw_data.(these_names{j})(i_p.Results.filter_set,:);
    end
end

bonferroni_correction = sum(sum(not(isnan(raw_data.p_vals))));

process_data = struct();

process_data.active_degrade = not(isnan(raw_data.p_vals)) & raw_data.p_vals < 0.05/bonferroni_correction ...
    & not(isnan(raw_data.cell_diffs)) & raw_data.cell_diffs < 0;

process_data.live_cells = raw_data.tracking > -1;
process_data.longevities = sum(process_data.live_cells,2)/2;

process_data.ever_degrade = [];
for i=1:size(raw_data.tracking,1)
    process_data.ever_degrade = [process_data.ever_degrade, any(process_data.active_degrade(i,:))];
end

process_data.has_degraded = zeros(size(raw_data.tracking));
for i=1:size(raw_data.tracking,1)
    for j = 1:size(raw_data.tracking,2)
        process_data.has_degraded(i,j) = process_data.active_degrade(i,j) | any(process_data.has_degraded(i,1:j));
    end
end

process_data.degrade_percentage = sum(process_data.has_degraded)/size(raw_data.tracking,1);