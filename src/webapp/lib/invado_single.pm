package invado_single;
use Dancer ':syntax';
use Dancer::Session::YAML;
use strict;
use warnings;
use Cwd;
use Sys::Hostname;
use upload;
use exp_status;
use all_exp_status;
use thresh_testing;
use results_understanding;
use server_status;
use login;
use logout;
use Data::Dumper;

our $VERSION = '0.1';

get '/' => sub {
	if (not session('user_id')) {
    	template 'index';
	} else {
		my $user_id = session 'user_id';
		template 'index', {user_id=>$user_id};
	}
};

get '/metamorph_grid' => sub {
	template 'metamorph_grid';
};

post '/metamorph_grid' => sub {
	my %input = params;
	my $grid_file = upload('metamorph_file') or die $!;
	my $temp_file_name = $grid_file->tempname;

	system("../utilities/make_metamorph_grid_file.pl -corners $temp_file_name -dish_count $input{dish_count} -output_prefix ../public/metamorph_grid/");

	template 'metamorph_grid', {download_available => 1};
};

get '/deploy' => sub {
    template 'deployment_wizard', {
		directory => getcwd(),
		hostname  => hostname(),
		proxy_port=> 8000,
		cgi_type  => "fast",
		fast_static_files => 1,
	};
};

#The user clicked "updated", generate new Apache/lighttpd/nginx stubs
post '/deploy' => sub {
    my $project_dir = param('input_project_directory') || "";
    my $hostname = param('input_hostname') || "" ;
    my $proxy_port = param('input_proxy_port') || "";
    my $cgi_type = param('input_cgi_type') || "fast";
    my $fast_static_files = param('input_fast_static_files') || 0;

    template 'deployment_wizard', {
		directory => $project_dir,
		hostname  => $hostname,
		proxy_port=> $proxy_port,
		cgi_type  => $cgi_type,
		fast_static_files => $fast_static_files,
	};
};

get '/results_understanding' => sub {
	template 'results_understanding';
};

get '/results_understanding/' => sub {
	template 'results_understanding';
};

true;
