function ad_zamir = find_ad_zamir(high_passed_image,i_p)
if (i_p.Results.debug == 1), profile on; end
start_count = 0;

if (start_count > 0)
    ad_zamir = imread(fullfile('ad_zamir_samples',[num2str(start_count),'.png']));
else
    ad_zamir = zeros(size(high_passed_image));
end

sorted_pix_vals = sort(unique(high_passed_image(:)),'descend');

count = start_count;

for i = (start_count + 1):length(sorted_pix_vals)
    if (sorted_pix_vals(i) <= i_p.Results.filter_thresh)
        continue
    end

    if (count > numel(high_passed_image) && i_p.Results.debug == 1)
        continue
    end

    lin_ind = find(high_passed_image == sorted_pix_vals(i));

    for j = 1:length(lin_ind)
        assert(ad_zamir(lin_ind(j)) == 0, 'Error: Adhesion already assigned in this position %d',lin_ind(j))
        ad_zamir = add_single_pixel(ad_zamir,lin_ind(j),i_p.Results.min_size);
    end

    count = count + 1;
    if (i_p.Results.debug)
        if (not(exist('ad_zamir_samples','dir'))), mkdir('ad_zamir_samples'); end
        imwrite(double(ad_zamir)/2^16,fullfile('ad_zamir_samples',[num2str(count),'.png']),'bitdepth',16)
    end

    if (mod(count,100) == 0 && i_p.Results.debug)
        disp(['Count: ',num2str(count),'/',num2str(sum(sorted_pix_vals > i_p.Results.filter_thresh))])
    end
end


filled_ad_zamir = imfill(ad_zamir);
filled_pix = find(and(filled_ad_zamir > 0, ad_zamir == 0));
for i = 1:length(filled_pix)
    ad_zamir = add_single_pixel(ad_zamir,filled_pix(i),i_p.Results.min_size);
end

ad_nums = unique(ad_zamir);
assert(ad_nums(1) == 0, 'Background pixels not found after building adhesion label matrix')
for i = 2:length(ad_nums)
    ad_zamir(ad_zamir == ad_nums(i)) = i - 1;
end

profile off;
if (i_p.Results.debug), profile viewer; end


function ad_zamir = add_single_pixel(ad_zamir,pix_pos,min_size)

[pix_pos_ind(1),pix_pos_ind(2)] = ind2sub(size(ad_zamir),pix_pos);

%save the number of pixels in currently in adhesions, this will be compared
%at the end of processing to make sure another pixel has been added
initial_size = sum(sum(im2bw(ad_zamir,0)));

%now locate the adhesions in the current adhesions that touch the newest
%selected pixel
connected_ad = false(size(ad_zamir));
connected_ad(pix_pos) = 1;
ad_nums = zeros(4);
%wrap these calls in try, since they could attempt to access indexes
%outside the accepted 1-size range
try ad_nums(1) = ad_zamir(pix_pos_ind(1) - 1,pix_pos_ind(2)); end
try ad_nums(2) = ad_zamir(pix_pos_ind(1) + 1,pix_pos_ind(2)); end    
try ad_nums(3) = ad_zamir(pix_pos_ind(1),pix_pos_ind(2) - 1); end
try ad_nums(4) = ad_zamir(pix_pos_ind(1),pix_pos_ind(2) + 1); end

for i = 1:length(ad_nums)
    if (ad_nums(i) ~= 0)
        connected_ad(ad_zamir == ad_nums(i)) = 1;
    end
end

%build a binary image of the current touching adhesions
old_ad = false(size(ad_zamir));
old_ad(and(ad_zamir > 0,connected_ad)) = 1;

relabeled_old_ad = ad_zamir;
relabeled_old_ad(old_ad ~= 1) = 0;
ad_nums = unique(relabeled_old_ad);
assert(ad_nums(1) == 0, 'Error in collecting relabeled_old_ad unique ad numbers')
for i = 2:length(ad_nums)
    relabeled_old_ad(relabeled_old_ad == ad_nums(i)) = i - 1;
end
assert(all(unique(relabeled_old_ad)' == 0:(length(ad_nums) - 1)), 'Error in old ad relabeling')

assert(sum(connected_ad(:)) == (sum(old_ad(:)) + 1),'Error in connected ad finding: %d, %d ',sum(connected_ad(:)),sum(old_ad(:)))

%if there aren't any pixels which were connected to newest pixel, add the
%newest pixel as a new adhesion, otherwise, start a more complicated
%procedure
if (sum(old_ad(:)) == 0)
    ad_zamir(connected_ad) = max(ad_zamir(:)) + 1;
else
    props = regionprops(relabeled_old_ad,'Area','Centroid');

    %if there is only one set of props, we know there was only one adhesion
    %connected to the newest pixel, otherwise, trigger a more complicated
    %procedure
    if (length(props) == 1)
        %pick out the adhesion number from the first entry in find, then
        %check that all other pixels have the same adhesion number and
        %assign the newest pixel to the old adhesion
        ad_number = ad_zamir(find(relabeled_old_ad == 1,1));
        assert(ad_number > 0, 'Error in old ad filtering: adhesion number less than 1');
        assert(all(ad_number == ad_zamir(relabeled_old_ad >= 1)),'Error in old ad filtering: single adhesion with different numbers');

        ad_zamir(pix_pos) = ad_number;
    else
        %Check if all the connected adhesions are below the minimum size,
        %if they are, merge all the adhesions, otherwise, trigger a more
        %complicated procedure
        meets_min = [props.Area] >= min_size;
        if (all([props.Area] < min_size))
            ad_zamir(connected_ad) = min(ad_zamir(old_ad == 1));
        elseif (sum(meets_min) == 1)
            large_area_ad = ismember(relabeled_old_ad,find([props.Area] >= min_size));

            ad_number = ad_zamir(find(large_area_ad == 1,1));
            assert(ad_number > 0, 'Error in large ad filtering: adhesion number less than 1');
            assert(all(ad_number == ad_zamir(large_area_ad == 1)),'Error in large ad filtering: single adhesion with different numbers');

            ad_zamir(connected_ad) = ad_number;
        else
            large_area_ads = ismember(relabeled_old_ad,find([props.Area] >= min_size));
            large_area_nums = unique(relabeled_old_ad(large_area_ads));

            closest_relabeled_info = [0,inf];

            for i = 1:length(large_area_nums)
                dist = sqrt((pix_pos_ind(1) - props(i).Centroid(2))^2 + (pix_pos_ind(2) - props(i).Centroid(1))^2);
                if (dist < closest_relabeled_info(2))
                    closest_relabeled_info = [i,dist];
                end
            end
            assert(closest_relabeled_info(1) ~= 0, 'Error in identifying the closest of the large adhesions')

            ad_number = ad_zamir(find(relabeled_old_ad == closest_relabeled_info(1),1));
            assert(ad_number > 0, 'Error in largest ad filtering: adhesion number less than 1');
            assert(all(ad_number == ad_zamir(relabeled_old_ad == closest_relabeled_info(1))),'Error in largest ad filtering: single adhesion with different numbers');

            ad_zamir(pix_pos) = ad_number;
        end

    end
end

assert(initial_size + 1 == sum(sum(im2bw(ad_zamir,0))), 'Error in adding single pixel: Adhesion set did not grow')