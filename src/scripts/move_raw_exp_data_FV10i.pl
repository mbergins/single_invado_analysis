#!/usr/bin/perl -w

###############################################################################
# Global Variables and Modules
###############################################################################
use strict;
use File::Spec::Functions;
use File::Basename;
use File::Path;
use File::Copy;
use Getopt::Long;
use Cwd;
use Data::Dumper;
use Config::General qw(ParseConfig);

#Perl built-in variable that controls buffering print output, 1 turns off
#buffering
$| = 1;

my %opt;
$opt{debug} = 0;
GetOptions(\%opt, "src=s", "target=s", "debug|d", "default_config=s") or die;
die "Can't find src folder on command line." if (not $opt{src});
die "Can't find target folder on command line." if (not $opt{target});

my $default_config_file_location = "../../data/config/Invado_default.cfg";
if (not exists $opt{default_config}) {
	$default_config_file_location = "../../data/config/Invado_default.cfg";
} else {
	$default_config_file_location = $opt{default_config};
}

my $relative_config_file;
if ($default_config_file_location =~ m#\.\./\.\./data/(.*)#) {
	$relative_config_file = $1;
} else {
	die "Unable to find ../../data/ in the default config file location: $default_config_file_location";
}

###############################################################################
# Main Program
###############################################################################

my @src_dirs = sort <$opt{src}/*>;
die "Couldn't find any files in $opt{src}." if scalar(@src_dirs) == 0;

#we will use this variable to parse out the exp_name value
my $data_folder = &determine_data_folder_name;

foreach my $dir (@src_dirs) {
	my $exp_num;
	if ($dir =~ /Image_\d+_(\d+)_\d+/) {
		$exp_num = $1;
	} else {
		die "Unable to find the experiment number in $_";
	}
	
	my @gel_images;
	my @lifeact_images;

	for my $exp_file (<$dir/*>) {
		
	}
}

# #sort through each of the file sets and move everything into place
# for (sort keys %file_sets) {
# 	my $exp_dir = catdir($opt{target}, $pos_code_to_date{$_} . "_" . $_);
# 	
# 	my $config_file = catfile($exp_dir, "analysis.cfg");
# 	
# 	my $exp_name;
# 	if ($exp_dir =~ /$data_folder(.*)/) {
# 		$exp_name = $1;
# 	} else {
# 		die "Unable to find the data folder in the specified target directory:
# 			data_folder: $data_folder
# 			exp_dir: $exp_dir\n";
# 	}
# 
# 	my $puncta_file = catfile($exp_dir, "Images", "puncta", "puncta.tiff");
# 	mkpath(dirname($puncta_file));
# 	my @src_puncta_file = grep /C0.*.tiff/, @{$file_sets{$_}};
# 	die "Found more than one puncta file in set, postion code: $_" if (scalar(@src_puncta_file) > 1);
# 	die "Didn't find any puncta files, postion code: $_" if (scalar(@src_puncta_file) < 1);
# 
# 	my $gel_file = catfile($exp_dir, "Images", "gel", "gel.tiff");
# 	mkpath(dirname($gel_file));
# 	my @src_gel_file = grep /C1.*.tiff/, @{$file_sets{$_}};
# 	die "Found more than one gel file in set, postion code: $_" if (scalar(@src_gel_file) > 1);
# 	die "Didn't find any gel files, postion code: $_" if (scalar(@src_gel_file) < 1);
# 	
# 	my $log_file = catfile($exp_dir, "collection_properties.log");
# 	mkpath(dirname($log_file));
# 	my @src_log_file = grep /.*.log/, @{$file_sets{$_}};
# 	die "Found more than one log file in set, postion code: $_" if (scalar(@src_log_file) > 1);
# 	die "Didn't find any log files, postion code: $_" if (scalar(@src_log_file) < 1);
# 	
# 	if ($opt{debug}) {
# 		print "mkpath($exp_dir)\n";
# 		print "copy($src_gel_file[0], $gel_file)\n";
# 		print "copy($src_puncta_file[0], $puncta_file)\n";
# 		print "copy($src_log_file[0], $log_file)\n";
# 		
# 		print "&write_standard_config_file($config_file, $exp_name)\n";
# 		print "\n";
# 	} else {
# 		mkpath($exp_dir);
# 		copy($src_gel_file[-1], $gel_file);
# 		copy($src_puncta_file[0], $puncta_file);
# 		copy($src_log_file[0], $log_file);
# 		&write_standard_config_file($config_file, $exp_name);
# 	}
# }
###############################################################################
# Functions
###############################################################################

sub write_standard_config_file {
	my $file_name = shift;
	my $exp_name = shift;

	my $default_config_depth = &find_main_config_depth($file_name);
	my $config_prefix = "../" x $default_config_depth;
	

	open OUTPUT, ">$file_name";
	print OUTPUT 
"<<include " . $config_prefix . $relative_config_file . ">>

###############################################################################
# Required Experiment Parameters
###############################################################################

exp_name = $exp_name 

###############################################################################
# Experiment Specific Parameters
###############################################################################
";

	close OUTPUT;
}

sub determine_data_folder_name {
	my %cfg = ParseConfig(
        -ConfigFile            => $default_config_file_location,
        -MergeDuplicateOptions => 1,
        -IncludeRelative       => 1,
	);
	
	return $cfg{data_folder};
}

sub find_main_config_depth {
	my $file_name = shift;

	my @split_file_parts = split(/\//,$file_name);
	
	while ($split_file_parts[0] eq "..") {
		@split_file_parts = @split_file_parts[1..$#split_file_parts];
	}
	
	return scalar(@split_file_parts) - 2;
}
