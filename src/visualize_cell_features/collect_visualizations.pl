#!/usr/bin/env perl

###############################################################################
# Global Variables and Modules
###############################################################################

use strict;
use File::Path;
use File::Basename;
use Image::ExifTool;
use Math::Matlab::Local;
use Getopt::Long;
use File::Spec::Functions;

use lib "../lib";
use Config::Adhesions;
use Image::Stack;

#Perl built-in variable that controls buffering print output, 1 turns off 
#buffering
$| = 1;

my %opt;
$opt{debug} = 0;
GetOptions(\%opt, "cfg=s", "debug");

die "Can't find cfg file specified on the command line" if not exists $opt{cfg};

my @needed_vars =
  qw(data_folder results_folder exclude_file single_image_folder folder_divider exp_name single_image_folder matlab_errors_folder vis_config_file vis_errors_file extr_val_file bounding_box_file);
my $ad_conf = new Config::Adhesions(\%opt, \@needed_vars);
my %cfg = $ad_conf->get_cfg_hash;

my $matlab_wrapper;
if (defined $cfg{matlab_executable}) {
    $matlab_wrapper = Math::Matlab::Local->new({ cmd => "$cfg{matlab_executable} -nodisplay -nojvm -nosplash", });
} else {
    $matlab_wrapper = Math::Matlab::Local->new();
}

###############################################################################
#Main Program
###############################################################################

&write_matlab_config;

my $matlab_code = "make_movie_frames('".catfile($cfg{exp_data_folder},$cfg{vis_config_file})."')";

my $error_folder = catdir($cfg{exp_results_folder},$cfg{matlab_errors_folder});
if (not($matlab_wrapper->execute($matlab_code))) {
    mkpath($error_folder);
    print $error_folder;
    open ERR_OUT, ">".catdir($error_folder,$cfg{vis_errors_file});
    print ERR_OUT $matlab_wrapper->err_msg;
    print ERR_OUT "\n\nMATLAB COMMANDS\n\n$matlab_code";
    close ERR_OUT;

    print $matlab_wrapper->err_msg if $opt{debug};

    $matlab_wrapper->remove_files;
}

###############################################################################
#Functions
###############################################################################

sub build_matlab_visualization_config {
    my $adhesion_image = basename <$cfg{exp_data_folder}/$cfg{adhesion_image_prefix}*>;
    my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = localtime time;
    my @timestamp =  join("/",($mon + 1, $day, $year + 1900)) . " $hour:$min";
    
    my @config_lines = (
      "%Config file produced by collect_visualizations.pl\n",
      "%@timestamp\n\n",
      "%General Parameters\n",
      "exp_name = '$cfg{exp_name}'\n",
      "base_data_folder = fullfile('", join("\',\'", split($cfg{folder_divider},$cfg{data_folder})), "', exp_name)\n",
      "base_results_folder = fullfile('", join("\',\'",split($cfg{folder_divider},$cfg{results_folder})), "', exp_name)\n\n",

      "original_i_file = fullfile(base_data_folder, '$adhesion_image')\n\n",
      
      "I_folder = fullfile(base_results_folder, '$cfg{single_image_folder}')\n\n",
      
      "adhesions_filename = 'adhesions.png'\n",
      "edge_filename = 'cell_mask.png'\n",

      "tracking_seq_file = fullfile(base_results_folder,'$cfg{tracking_output_file}')\n\n",
        
      "out_path = fullfile(base_results_folder,'$cfg{movie_output_folder}')\n",
      "out_prefix = {'",join("\',\'",split(/\s/, $cfg{movie_output_prefix})),"'}\n\n",

      "excluded_frames_file = fullfile(base_data_folder,'$cfg{exclude_file}')\n",
      "extr_val_file = fullfile(base_data_folder,'$cfg{extr_val_file}')\n",
      "bounding_box_file = fullfile(base_data_folder,'$cfg{bounding_box_file}')\n",
      "path_folders = '$cfg{path_folders}'\n\n",

      "image_padding_min = $cfg{image_padding_min}\n\n",

      "%Comparison Specific Settings\n\n",
    );

}

sub write_matlab_config {
    my @config = &build_matlab_visualization_config;
    open VIS_CFG_OUT, ">" . catfile($cfg{exp_data_folder},$cfg{vis_config_file}) or 
      die "Unsuccessfully tried to open visualization config file: ". catfile(qw($cfg{exp_data_folder} $cfg{vis_config_file}));
    print VIS_CFG_OUT @config;
    close VIS_CFG_OUT;
}
