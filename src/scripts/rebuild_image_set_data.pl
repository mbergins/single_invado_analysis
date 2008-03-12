#!/usr/bin/perl -w

###############################################################################
# Global Variables and Modules
###############################################################################
use strict;
use File::Path;
use File::Spec::Functions;
use Getopt::Long;
use IO::File;
use Benchmark;

use lib "../lib";
use Config::Adhesions;
use Image::Data::Collection;

#Perl built-in variable that controls buffering print output, 1 turns off
#buffering
$| = 1;

my %opt;
$opt{debug} = 0;
GetOptions(\%opt, "cfg|config=s", "debug|d");

die "Can't find cfg file specified on the command line" if not exists $opt{cfg};

print "Collecting Overall Configuration\n\n" if $opt{debug};

my @needed_vars =
  qw(data_folder results_folder exp_name single_image_folder raw_data_folder general_data_files tracking_files tracking_output_file);
my $ad_conf = new Config::Adhesions(\%opt, \@needed_vars);
my %cfg = $ad_conf->get_cfg_hash;

###############################################################################
# Main Program
###############################################################################

if (-e $cfg{exp_results_folder}) {
    File::Path::rmtree($cfg{exp_results_folder});
}

my $debug_string = "";
$debug_string = "-d" if $opt{debug};
my ($t1, $t2);


#Find Features
chdir "../find_cell_features";
print "\n\nSetting Up Results Directory\n\n" if $opt{debug};
$t1 = new Benchmark;
system "./setup_results_folder.pl -cfg $opt{cfg} $debug_string";
$t2 = new Benchmark;
print "Runtime: ",timestr(timediff($t2,$t1)), "\n" if $opt{debug};

print "\n\nCollecting Cell Mask Set\n\n" if $opt{debug};
$t1 = new Benchmark;
system "./collect_mask_set.pl -cfg $opt{cfg} $debug_string";
$t2 = new Benchmark;
print "Runtime: ",timestr(timediff($t2,$t1)), "\n" if $opt{debug};

print "\n\nFinding Focal Adhesions\n\n" if $opt{debug};
$t1 = new Benchmark;
system "./collect_fa_image_set.pl -cfg $opt{cfg} $debug_string";
$t2 = new Benchmark;
print "Runtime: ",timestr(timediff($t2,$t1)), "\n" if $opt{debug};


#Building the Tracking Matrix
chdir "../analyze_cell_features";
print "\n\nTracking Focal Adhesions\n\n" if $opt{debug};
$t1 = new Benchmark;
system "./track_adhesions.pl -cfg $opt{cfg} -o data.stor -i data.stor $debug_string";
$t2 = new Benchmark;
print "Runtime: ",timestr(timediff($t2,$t1)), "\n" if $opt{debug};

#Analyze the Adhesions
print "\n\nAnalyzing Focal Adhesions\n\n" if $opt{debug};
$t1 = new Benchmark;
system "./gather_tracking_results.pl -cfg $opt{cfg} $debug_string";
$t2 = new Benchmark;
print "Runtime: ",timestr(timediff($t2,$t1)), "\n" if $opt{debug};

#Collecting Visualizations
chdir "../visualize_cell_features";
print "\n\nBuilding Tracking Visualization\n\n" if $opt{debug};
$t1 = new Benchmark;
system "./collect_visualizations.pl -cfg $opt{cfg} $debug_string";
$t2 = new Benchmark;
print "Runtime: ",timestr(timediff($t2,$t1)), "\n" if $opt{debug};

#Build Movies 
my @image_numbers = &Image::Data::Collection::gather_sorted_image_numbers(\%cfg);
my $image_num_length = length(scalar(@image_numbers));

print "\n\nBuild Movies\n\n" if $opt{debug};
$t1 = new Benchmark;
foreach (split(/\s/, $cfg{movie_output_prefix})) {
    my $input_folder = "$cfg{exp_results_folder}/$cfg{movie_output_folder}/$_";
    system "ffmpeg -y -r 5 -b 100000 -i $input_folder/%0" . $image_num_length . "d.png $cfg{exp_results_folder}/$_.mp4";
}
$t2 = new Benchmark;
print "Runtime: ",timestr(timediff($t2,$t1)), "\n" if $opt{debug};