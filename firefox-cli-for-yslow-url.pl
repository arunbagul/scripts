#!/usr/bin/perl

# Author: Arun
# Date: 2011

use strict;
use warnings;
use WWW::Mechanize::Firefox;
use Firefox::Application;
use Getopt::Long;
use Data::Dumper;

my $user_profile = "/home/arunb/firefox-yslow/yslow-profile";
my $firefox_bin = "/home/arunb/firefox-yslow/yslow-firefox.sh";
##my $firefox_bin = "/var/firefox-4.0.1/firefox/firefox  -no-remote -P 'yslow'";

#################################

my $numArgs = $#ARGV + 1;

if ( $numArgs ne 0 ) {

	my ($myurl) = (@ARGV);
		
	#################### Open URL #########################
	## creating firefox obj
	my $mech = WWW::Mechanize::Firefox->new(
		launch => $firefox_bin,
		create => 1,
		autoclose => 0,
	);		 
	# open page/url
	$mech->get($myurl);
	print "\nRequest- sucessfully" if $mech->success(); ## Request status
        my $http_status = $mech->status(); ## http status
     	if ( $http_status eq 200 ) {
		print "\nHTTP_Status- OK";  
	 } elsif ( $http_status eq 404) {
		print "\nHTTP_Status- Not Found";  
	 } else {
		print "\nHTTP_Status- Error";  
	 }
	#######################################################

	####### Profile and Tab list #######
	my $ffobj = Firefox::Application->new();
	my $profile_name = $ffobj->current_profile->{name};
	if ($profile_name eq "yslow") { 
		print "\nFirefox profile_name - $profile_name";
	} else { print "\nFirefox profile is wrong! will die\n"; exit(2);}
	## tab list
	my @tab_info = $ffobj->openTabs();
	my $tab_count = @tab_info;
	print "\nTotal no of Tab - $tab_count";
	if ($tab_count > 50 ) {
		print "\n Clossing the all Tabs";
		foreach my $hash_tab (@tab_info) {
			 my ($tab_title,$tab_location) = ($hash_tab->{title},$hash_tab->{location});
			print "\n $tab_title => $tab_location | $hash_tab"; 
			shift(@tab_info);
			$ffobj->closeTab($ffobj->selectedTab()); 
		}			
	} else { 
		#my $tabobj = $ffobj->addTab(autoclose => 0); 
		print "\nYou can create new Tab";		
	}
	#### playing with firefox tab ####
	@tab_info = $ffobj->openTabs();
	my $arraySize = $#tab_info;
	my $LastTab = $tab_info[$arraySize];
	print "\nSubmitting Yslow results to showslow...\n";
	my $LastTabRef = $LastTab->{'tab'};
	$ffobj->activateTab($LastTabRef);
	#### 
}  else { print "\n * Usage: $0 <url_name>\n\n"; exit 1; }

#end
print "\n";

