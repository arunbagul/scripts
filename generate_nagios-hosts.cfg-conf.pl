#!/usr/bin/perl

# Author: Arun Bagul

use strict;
use Shell;

my $RS_CLOUD = "/etc/nagios/CLOUD-SERVER_LIST.list";
my $Host_File = "/etc/nagios/objects/hosts.cfg";

### base part
print "\n\t"."-" x 35;
print "\n\t| Welcome to Nagmon CLI tool |";
print "\n\t"."-" x 35;

print "\n\tScript to generate Nagios 'hosts.cfg' conf file\n\twhich is used by Nagios for Cloud hosts";
print "\n\tPlease add host/ip in file '$RS_CLOUD'\n";

##
my $no_of_argv = $#ARGV + 1;
if (($no_of_argv == 1) && (($ARGV[0] eq "public_addr") || ($ARGV[0] eq "private_addr"))) 
{
	print "\nTaking Backup of $Host_File ...";
	cp("$Host_File","${Host_File}-backup");

 	print "\nOpening $Host_File for writing ...";
	open(HOST_WRITE,">$Host_File") or die "Failed to open host list file, $!";
	my $mydate=`date`;chomp($mydate);

	print HOST_WRITE "## This File is Generate by Nagmon tool\n## Date - $mydate";
	print HOST_WRITE "\n\n########### Cloud Hosts ###########\n";	

	########################################################
	#Read host, public and private ipaddr...
	print "\nReading Host List from file $RS_CLOUD\n";
	open(HOST_NAME,"<$RS_CLOUD") or die "Failed to open host list file, $!";

	## read file line-by-line
	while (<HOST_NAME>) {
	    chomp;
	    #print $_ ;
	    if ((!m/^$/) && (!m/^#/)){
		 my @host_arr=split(/=/);
		 my $final_addr=undef;
		 ## choose pub/private
		 if ($ARGV[0] eq "public_addr") {$final_addr=$host_arr[1];}
		 elsif ($ARGV[0] eq "private_addr") {$final_addr=$host_arr[2];}
		 ## write to /etc/hosts file
		 print HOST_WRITE "\n\ndefine host {";
		 print HOST_WRITE "\n\tuse generic-host";
  		 print HOST_WRITE "\n\thost_name $host_arr[0]";
  		 print HOST_WRITE "\n\talias $host_arr[0]";
  		 print HOST_WRITE "\n\taddress ${final_addr}";
  		 print HOST_WRITE "\n\tmax_check_attempts 1 \n}";
	    }
	}
	print HOST_WRITE "\n## Done \n\n";
	## closing host_list file
	close(HOST_NAME);
	close(HOST_WRITE);
	########################################################
	print "Writing file $Host_File completed..";

}else { print "\n\tUsage: $0 { public_addr | private_addr }";}

print "\n\n";
#done
