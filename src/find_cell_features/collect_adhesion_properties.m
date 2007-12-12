function adhesion_props = collect_adhesion_properties(ad_I,cell_mask,orig_I)
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

i_p.addRequired('ad_I',@(x)isnumeric(x) || islogical(x));
i_p.addRequired('cell_mask',@(x)isnumeric(x) || islogical(x));
i_p.addRequired('orig_I',@isnumeric);

i_p.parse(ad_I,cell_mask,orig_I);

labeled_adhesions = bwlabel(ad_I,4);
adhesion_props = regionprops(labeled_adhesions,'all');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dists = bwdist(~cell_mask);
cell_centroid = regionprops(bwlabel(cell_mask),'centroid');
cell_centroid = cell_centroid.Centroid;

for i=1:max(labeled_adhesions(:))
    adhesion_props(i).Average_adhesion_signal = mean(orig_I(find(labeled_adhesions == i)));
    adhesion_props(i).Variance_adhesion_signal = var(orig_I(find(labeled_adhesions == i)));

    centroid_pos = round(adhesion_props(i).Centroid);
    if(size(centroid_pos,1) == 0)
        warning('collect_adhesion_properties - centroid not found');
        adhesion_props(i).Centroid_dist_from_edge = NaN;
    else
        adhesion_props(i).Centroid_dist_from_edge = dists(centroid_pos(2),centroid_pos(1));
        hypo = sqrt((cell_centroid(1) - centroid_pos(1))^2 + (cell_centroid(2) - centroid_pos(2))^2);
        adhesion_props(i).Angle_to_center = acos((centroid_pos(2) - cell_centroid(2))/hypo);
        if (centroid_pos(2) - cell_centroid(2) < 0)
            adhesion_props(i).Angle_to_center = adhesion_props(i).Angle_to_center + pi;
        end
    end
end