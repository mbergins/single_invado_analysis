#!/usr/bin/perl -w

###############################################################################
# Global Variables and Modules
###############################################################################
use strict;
use File::Path;
use File::Find;
use File::Spec::Functions;
use Getopt::Long;
use IO::File;
use Benchmark;
use Data::Dumper;

use lib "../lib";
use Config::ImageSet;

#Perl built-in variable that controls buffering print output, 1 turns off
#buffering
$| = 1;

my %opt;
$opt{debug} = 0;
GetOptions(\%opt, "cfg|config=s", "debug|d") or die;
die "Can't find cfg file specified on the command line" if not exists $opt{cfg};

print "Collecting Overall Configuration\n\n" if $opt{debug};

my $ad_conf = new Config::ImageSet(\%opt);
my %cfg = $ad_conf->get_cfg_hash;

###############################################################################
# Main Program
###############################################################################
my ($t1, $t2);

#Collecting Visualizations
chdir "../visualize_cell_features";

#Build Movies 

my @commands = (
	# "ffmpeg -v 0 -y -r $cfg{movie_frame_rate} -i $cfg{individual_results_folder}/%0" . $image_num_length . "d/gel.png -sameq $cfg{exp_results_folder}/gel.mov 2>&1",
	# "ffmpeg -v 0 -y -r $cfg{movie_frame_rate} -i $cfg{individual_results_folder}/%0" . $image_num_length . "d/puncta_highlight.png -sameq $cfg{exp_results_folder}/puncta_highlight.mov 2>&1",
	# "ffmpeg -v 0 -y -r $cfg{movie_frame_rate} -i $cfg{individual_results_folder}/%0" . $image_num_length . "d/invado_and_not.png -sameq $cfg{exp_results_folder}/visualizations/invado_and_not.mp4 2>&1",
	# "ffmpeg -v 0 -y -r $cfg{movie_frame_rate} -i $cfg{individual_results_folder}/%0" . $image_num_length . "d/puncta_binary.png -sameq $cfg{exp_results_folder}/visualizations/puncta_binary.mp4 2>&1",
	# "ffmpeg -v 0 -y -r $cfg{movie_frame_rate} -i $cfg{individual_results_folder}/%0" . $image_num_length . "d/cell_mask.png -sameq $cfg{exp_results_folder}/visualizations/cell_mask.mp4 2>&1",
	# "ffmpeg -v 0 -y -r $cfg{movie_frame_rate} -i $cfg{individual_results_folder}/%0" . $image_num_length . "d/highlighted_mask.png -sameq $cfg{exp_results_folder}/visualizations/highlighted_mask.mp4 2>&1",
	# "ffmpeg -v 0 -y -r $cfg{movie_frame_rate} -i $cfg{individual_results_folder}/%0" . $image_num_length . "d/invader_and_not.png -sameq $cfg{exp_results_folder}/visualizations/invader_and_not.mp4 2>&1",
	# "ffmpeg -v 0 -y -r $cfg{movie_frame_rate} -i $cfg{individual_results_folder}/%0" . $image_num_length . "d/raw_images.png -sameq $cfg{exp_results_folder}/visualizations/raw_images.mp4 2>&1",
);

for (@commands) {
	if ($opt{debug}) {
		print $_, "\n";
	} else {
		print "\n\nBuild Movies\n\n" if $opt{debug};
		$t1 = new Benchmark;
		system "$_ > /dev/null 2> /dev/null";
		$t2 = new Benchmark;
		# print "Runtime: ",timestr(timediff($t2,$t1)), "\n";
	}
}

###############################################################################
# Functions
###############################################################################
