lsfunction adhesion_props = collect_adhesion_properties(orig_I,labeled_adhesions,varargin)
% COLLECT_ADHESION_PROPERTIES    using the identified adhesions, various
%                                properties are collected concerning the
%                                morphology and physical properties of the
%                                adhesions
%
%   ad_p = collect_adhesion_properties(ad_I,c_m,orig_I) collects the
%   properties of the adhesions identified in the binary image 'ad_I',
%   using the cell mask in 'c_m' and the original focal image data in
%   'orig_I', returning a structure 'ad_p' containing properties
%
%   Properties Collected:
%       -all of the properties collected by regioprops(...,'all')
%       -the distance of each adhesion's centroid from the nearest cell
%        edge
%       -the average and variance of the normalized fluorescence signal
%        within each adhesion

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Setup variables and parse command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i_p = inputParser;
i_p.FunctionName = 'COLLECT_ADHESION_PROPERTIES';

i_p.addRequired('orig_I',@isnumeric);
i_p.addRequired('labeled_adhesions',@(x)isnumeric(x));

i_p.addParamValue('cell_mask',0,@(x)isnumeric(x) || islogical(x));
i_p.addParamValue('background_border_size',5,@(x)isnumeric(x));
i_p.addParamValue('protrusion_data',0,@(x)iscell(x));
i_p.addOptional('i_num',0,@(x)isnumeric(x) && x >= 1);
i_p.addOptional('debug',0,@(x)x == 1 || x == 0);

i_p.parse(labeled_adhesions,orig_I,varargin{:});

%read in the cell mask image if defined in parameter set
if (isempty(strmatch('cell_mask',i_p.UsingDefaults)))
    cell_mask = i_p.Results.cell_mask;
end

if (isempty(strmatch('protrusion_data',i_p.UsingDefaults)))
    protrusion_data = i_p.Results.protrusion_data;
end

adhesion_props = regionprops(labeled_adhesions,'all');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
quiv_mat = zeros(max(labeled_adhesions(:)),4);
for i=1:max(labeled_adhesions(:))
    adhesion_props(i).Average_adhesion_signal = mean(orig_I(labeled_adhesions == i));
    adhesion_props(i).Variance_adhesion_signal = var(orig_I(labeled_adhesions == i));
    adhesion_props(i).Max_adhesion_signal = max(orig_I(labeled_adhesions == i));
    adhesion_props(i).Min_adhesion_signal = min(orig_I(labeled_adhesions == i));

    this_ad = labeled_adhesions;
    this_ad(labeled_adhesions ~= i) = 0;
    this_ad = logical(this_ad);
    background_region = logical(imdilate(this_ad,strel('disk',i_p.Results.background_border_size + 1,0)));
    background_region = and(background_region,not(labeled_adhesions));
    if (exist('cell_mask','var'))
        background_region = and(background_region,cell_mask);
    end
    adhesion_props(i).Background_adhesion_signal = mean(orig_I(background_region));
    adhesion_props(i).Background_area = sum(background_region(:));
    adhesion_props(i).Background_corrected_signal = adhesion_props(i).Average_adhesion_signal - adhesion_props(i).Background_adhesion_signal;

    shrunk_region = logical(imerode(this_ad,strel('disk',1,0)));
    if (sum(shrunk_region(:)) == 0), shrunk_region = this_ad; end
    adhesion_props(i).Shrunk_area = sum(shrunk_region(:));
    adhesion_props(i).Shrunk_adhesion_signal = mean(orig_I(shrunk_region));
    adhesion_props(i).Shrunk_corrected_signal = adhesion_props(i).Shrunk_adhesion_signal - adhesion_props(i).Background_adhesion_signal;
    
    if (mod(i,10) == 0 && i_p.Results.debug), disp(['Finished Ad: ',num2str(i), '/', num2str(max(labeled_adhesions(:)))]); end
end

if (exist('protrusion_data','var'))
    for i=1:size(protrusion_data,2)
        protrusion_matrix = protrusion_data{i};
        for j=1:max(labeled_adhesions(:))
            dists = sqrt((protrusion_matrix(:,1) - adhesion_props(j).Centroid(1)).^2 + (protrusion_matrix(:,2) - adhesion_props(j).Centroid(2)).^2);
            best_line_num = find(dists == min(dists),1,'first');
            
            adhesion_to_edge = [protrusion_matrix(best_line_num,1) - adhesion_props(j).Centroid(1), protrusion_matrix(best_line_num,2) - adhesion_props(j).Centroid(2)];
            edge_vector = protrusion_matrix(best_line_num,3:4);
            
            adhesion_props(j).Edge_speed(i,1) = sqrt(sum(edge_vector.^2))*(dot(edge_vector,adhesion_to_edge)/(sqrt(sum(edge_vector.^2)) * sqrt(sum(adhesion_to_edge.^2))));
        end
    end    
end

if (exist('cell_mask','var'))
    [dists, indices] = bwdist(~cell_mask);
    cell_centroid = regionprops(bwlabel(cell_mask),'centroid');
    cell_centroid = cell_centroid.Centroid;

    for i=1:max(labeled_adhesions(:))
        centroid_pos = round(adhesion_props(i).Centroid);
        centroid_unrounded = adhesion_props(i).Centroid;
        if(size(centroid_pos,1) == 0)
            warning('MATLAB:noCentroidFound','collect_adhesion_properties - centroid not found');
            adhesion_props(i).Centroid_dist_from_edge = NaN;
        else
            adhesion_props(i).Centroid_dist_from_edge = dists(centroid_pos(2),centroid_pos(1));
            [cep_x,cep_y] = ind2sub(size(cell_mask), indices(centroid_pos(2), centroid_pos(1)));
            adhesion_props(i).Closest_edge_pixel = [cep_x,cep_y]; 

            adhesion_props(i).Centroid_dist_from_center = sqrt((cell_centroid(1) - centroid_unrounded(1))^2 + (cell_centroid(2) - centroid_unrounded(2))^2);
            adhesion_props(i).Angle_to_center = acos((centroid_unrounded(1) - cell_centroid(1))/adhesion_props(i).Centroid_dist_from_center);
            assert(adhesion_props(i).Angle_to_center >= 0 && adhesion_props(i).Angle_to_center <= pi, 'Error: angle to center out of range: %d',adhesion_props(i).Angle_to_center);
            if (centroid_unrounded(2) - cell_centroid(2) < 0)
                if (centroid_unrounded(1) - cell_centroid(1) < 0)
                    assert(adhesion_props(i).Angle_to_center >= pi/2 && adhesion_props(i).Angle_to_center <= pi)
                    adhesion_props(i).Angle_to_center = 2*pi - adhesion_props(i).Angle_to_center;
                elseif (centroid_unrounded(1) - cell_centroid(1) >= 0)
                    assert(adhesion_props(i).Angle_to_center >= 0 && adhesion_props(i).Angle_to_center <= pi/2)
                    adhesion_props(i).Angle_to_center = 2*pi - adhesion_props(i).Angle_to_center;
                end
            end
        end
    end

    [border_row,border_col] = ind2sub(size(cell_mask),find(bwperim(cell_mask)));
    adhesion_props(1).Border_pix = [border_col,border_row];

    adhesion_props(1).Cell_size = sum(cell_mask(:));
end