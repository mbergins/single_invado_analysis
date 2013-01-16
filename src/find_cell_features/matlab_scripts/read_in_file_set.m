function data_set = read_in_file_set(this_dir,filenames)
data_set = struct;

data_set.this_dir = this_dir;

data_set.gel_range = csvread(fullfile(this_dir, filenames.gel_range));

data_set.gel_image  = double(imread(fullfile(this_dir, filenames.gel)));
data_set.gel_image_norm = (data_set.gel_image - data_set.gel_range(1))/range(data_set.gel_range);

data_set.objects = imread(fullfile(this_dir, filenames.objects));
data_set.objects_perim = imread(fullfile(this_dir, filenames.objects_perim));
data_set.puncta_range = csvread(fullfile(this_dir, filenames.puncta_range));
data_set.puncta_image  = double(imread(fullfile(this_dir, filenames.puncta)));
data_set.puncta_image_norm = (data_set.puncta_image - data_set.puncta_range(1))/range(data_set.puncta_range);

data_set.no_cells = imread(fullfile(this_dir, filenames.no_cell_regions));

%read in the cell mask file if defined
if(exist(fullfile(this_dir, filenames.cell_mask), 'file'))
    data_set.cell_mask = logical(imread(fullfile(this_dir, filenames.cell_mask)));
end
