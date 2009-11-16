function [ind_max, ind_min]=extr_relevant_max(i_max, val_max, i_min, val_min, varargin)
% EXTR_RELEVANT_MAX extracts the relevant maximas
% 
%            Given a set of local maximas and minimas this function extracts the
%            relevant maximas and minimas based on two criterions:
%            1. Based on an absolute reference given by the absolute maximum
%            2. Based on an relative reference given by the next local
%            minimum either on the right or the left side.
%            The user has to define the fractions of the absolute and
%            relative criterions.
%            The input data is tipically generated by the function
%            "imregionalmin" applied on a 1D data set.
%
%            If no solution was found ind_max= -99 and ind_min = -99
%            is returned
%
% SYNOPSIS    [ind_max, ind_min]=extr_relevant_max(i_max, val_max, i_min, val_min)
%
% INPUT       i_max     : the index of the local maxima
%             val_max   : the values of the local maximas
%             i_min     : the index of the local minimas
%             val_min   : the values of the local minimas
% 
% OUTPUT      ind_max   : index of the relevant maximas
%             ind_min   : index of the relevant minima
%                           
% DEPENDENCES   imFindThresh is used by { imFindThreshFilt
%                                 } 
%
% Matthias Machacek 03/10/03

%%%%%%%%%%%%%%%%%%% Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
l=length(varargin);

for i=1:l
   if strcmp(varargin(i),'rel_relevance')
      REL_RELEVANCE=varargin{i+1};  
   elseif strcmp(varargin(i),'tot_relevance')
      TOT_RELEVANCE=varargin{i+1};       
   end
end

if ~exist('REL_RELEVANCE','var')
   REL_RELEVANCE=0.6;
end
if ~exist('TOT_RELEVANCE','var')
   TOT_RELEVANCE=0.005;
end
%%%%%%%%%%%%%%%%%%% End parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      
%find the absolute maximum
[total_max,i_total_max]=max(val_max);

index=1;
store_last=0;
while length(val_max) > 1 & ~store_last
   %find the temporary absolut maximum
	[max_0,i_0]=max(val_max);
	
	i_m=1;
    %check if there is a minima to the right
    right_min=1;
    left_min=0;
    while i_m <= length(i_min) && i_min(i_m) < i_max(i_0) 
      i_m=i_m+1;
	end
    if i_m > length(i_min)
        %if there is non, take the one on the left
        left_min=1;
        right_min=0;
        i_m=length(i_min);
        while i_m >=1 && i_min(i_m) > i_max(i_0) 
            i_m=i_m-1;
	    end
        if i_m < 1
            left_min=0; 
        end
    end
    
	%calculate the significance
    d_1 =(val_max(i_0)-val_min(i_m))/val_max(i_0);
	rel_relevance=d_1;
    if index>1
        total_relevance=val_max(i_0)/total_max;
    else
        total_relevance=1;
    end
	
	%if relevant, store in significant_list and delete from val_max list
	if rel_relevance > REL_RELEVANCE & total_relevance > TOT_RELEVANCE
        %store relevant index
        rel_max_ind(index)=i_max(i_0);
        %store relevant's index value
        rel_max_val(index) = val_max(i_0);
        if ~store_last;
            rel_min_ind(index)=i_min(i_m);
            rel_min_val(index) = val_min(i_m);          
        end
        index=index+1;
        %delete relevant maxima and minima
        val_max(i_0)=[];
	    i_max(i_0)=[];
        if length(val_min)==1
            store_last=1;
            last_val_min=val_min(1);
            last_i_min=i_min(1);
        end
        if ~store_last;
	        val_min(i_m)=[];
            i_min(i_m)=[];  
        end
	else
        %delte non-relevant minima and maxima
        if right_min && length(val_max) >= i_0+1
            val_max(i_0+1)=[];
	        i_max(i_0+1)=[];
        elseif left_min && i_0 >= 2
            val_max(i_0-1)=[];
	        i_max(i_0-1)=[];
        elseif length(val_max)>1 %new an maybe wrong
            val_max(i_0)=[];
	        i_max(i_0)=[];     
        end
        if length(val_min) > 1;  %new
	        val_min(i_m)=[];
	        i_min(i_m)=[];     %new
        end
    end
end

%check the remaining extremas
if length(val_min)==1
   %mat_  rel_min_ind(index)=i_min(i_m); 

   d_1 =(val_max(1)-val_min(1))/val_max(1);  
   rel_relevance=d_1;
   total_relevance=val_max(1)/total_max;
   if rel_relevance > REL_RELEVANCE & total_relevance > TOT_RELEVANCE
        %store relevant index
        %mat_  rel_max_ind(index)=i_max(i_0);
        %mat_  rel_min_ind(index)=i_min(i_m);
        rel_max_ind(index)=i_max(1);
        rel_min_ind(index)=i_min(1);
        rel_max_val(index) = val_max(1);
        rel_min_val(index) = val_min(1);        
        index=index+1;
   end
else
   %if there is no minima for comparison take only absolute
   total_relevance=val_max(1)/total_max;
   if total_relevance > TOT_RELEVANCE
        %store relevant index
        rel_max_ind(index) = i_max(1);
        rel_max_val(index) = val_max(1);
        index=index+1;
   end   
end

%check the last maxima against the total maxima
% this has to be done because there might be no minima left
% which is enough low. Acctually there is one but MATLAB
% does not find it with the local max , resp. min \
% function
if length(val_max)==1
    total_relevance=val_max(1)/total_max;
    if total_relevance > TOT_RELEVANCE
        rel_max_ind(index) = i_max(1);
        rel_max_val(index) = val_max(1);
    end
end
    
%%%%%%%%%%%%%%  now find the two main maxima %%%%%%%%%%%%%%%%%%%%%%%%%%
[first_max i_first_max]  = max(rel_max_val);
ind_max(1)               = rel_max_ind(i_first_max);
rel_max_val(i_first_max) = [];
rel_max_ind(i_first_max) = [];

found = 0;
while length(rel_max_val) > 0 
    [second_max i_second_max] = max(rel_max_val);
    ind_max(2)                = rel_max_ind(i_second_max);
    
    rel_max_val(i_second_max) = [];
    rel_max_ind(i_second_max) = [];       
    %now find the minima between this two maximas
    ind_max = sort(ind_max);
    for i=1:length(rel_min_ind)
        if rel_min_ind(i) > ind_max(1) & rel_min_ind(i) < ind_max(2)
            found = 1;
            ind_min = rel_min_ind(i);
            return
        end
    end
end


%check if there are any minimas
if ~exist('ind_min', 'var') | ~exist('ind_max', 'var')
    ind_min = -99;
    ind_max = -99;  
end

%the output values are:
% ind_max=rel_max_ind;
% ind_min=rel_min_ind;