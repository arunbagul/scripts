#!/usr/bin/perl

#Author: Arun Bagul

use strict;
use warnings;
use DBI;
use DBD::mysql;
use POSIX qw(strftime);

no warnings 'uninitialized';

## DB details
my $db = "nagios_weekly_report";
my $db_host = "10.0.0.1";
my $db_user = "xxx";
my $db_pass = "xxxx";

##log file path
my $nagios_file = $ARGV[0];
my ($loc,$location) = split('=',$ARGV[2]);
my $goahead = "NO";
if ($location =~ m/ABC|UK|CLOUD/ ) { $goahead = "YES"; }

#####################################################
if ( ($ARGV[0]) && ($ARGV[1] eq "--load_to_db") && ($goahead eq "YES") ) {
	print "\nProcess to Load Nagios weekly or daily csv logs with summary to MySQL DB\n";
	## open DB connection
	my $dbconn = DBI->connect("DBI:mysql:database=$db:host=$db_host",$db_user,$db_pass) or die "\nDB Error $DBI::errstr\n";
	## open nagios csv log file
	open (MYFILE, "<$nagios_file") or die "Faied to open 'nagios_file'file $?";
	my $summary_flag ="NO"; my $count = undef; my $week_date =  strftime "%Y-%m-%d %H:00:00",localtime();
	my $myquery = $dbconn->prepare("desc nagios_log;");
	while (<MYFILE>) {
		chomp($_);
		if ($_ !~ /^\s*$/) {
			if ( ($_ !~ m/^Total\s+Nagios\s+logs\s+files\s+to\s+read:\s+\d+/) && ($_ !~ m/^Reading\s+nagios\s+log\s+files\s+from\s+file-.*/) && ($_ !~ m/^-+.*/) && ($_ !~ m/^Summary\s+Report/) ) {
				print "\n".$_;
				##Fri Sep 23 00:00:40 2011 [1316761240],app140,DaemonCompare.end_timestamp,WARNING
				my ($f1,$f2,$f3,$f4) = split(',',$_);
				#$f1 =~ m/\w+\s+\w+\s+\d\d\s+\d\d:\d\d:\d\d \d\d\d\d\s+\[(.*)\]/;
				$f1 =~ m/\w+\s+\w+\s+\d+\s+\d\d:\d\d:\d\d \d\d\d\d\s+\[(.*)\]/;
				my $time=$1; my $host = $f2; my $service_name = $f3; my $alert_type = $f4; 
				##my $mydate = scalar(localtime($time));
				my $mydate = strftime "%Y-%m-%d %H:%M:%S",localtime($time);
				##print "\n$mydate  $time\n";
				if ($_ =~ m/Alert_Type,Total_Count/) { $summary_flag = "nagios_report_summary"; }
				elsif ($_ =~ m/Service_Name,Total_Count/) { $summary_flag = "service_report"; }	
				elsif ($_ =~ m/Total\s+Alerts\s+=\s+\d+/) { (my $tmp, $count) = split('=',$f1);  $summary_flag = "LAST"; }	
				elsif ($_ =~ m/Total\s+Service\s+Failed\s+=\s+\d+/) {
					 $summary_flag = "LAST"; 
					 (my $tmp1, $f2) = split ('=',$f1);
					 ##print "\nINSERT INTO nagios_report_summary (date, loc, alert_summary, total_alert,total_service_failed) VALUES ('$week_date','$location','ALL',$count,$f2)\n";
					 $myquery = $dbconn->prepare("INSERT INTO nagios_report_summary (date, loc, alert_summary, total_alert,total_service_failed) VALUES ('$week_date','$location','ALL',$count,$f2);");					 
				}	
				######### db insert start #########
				if ($summary_flag eq "nagios_report_summary") {
					if (($f1 ne "Alert_Type") && ($f2 ne "Total_Count")) {
					 ##print "\nINSERT INTO nagios_report_summary (date, loc, alert_summary, total_alert) VALUES ('$week_date','$location','$f1',$f2)\n";
					 $myquery = $dbconn->prepare("INSERT INTO nagios_report_summary ( date, loc, alert_summary, total_alert) VALUES ('$week_date','$location','$f1',$f2);");
					}
				} elsif ($summary_flag eq "service_report") {
					if (($f1 ne "Service_Name") && ($f2 ne "Total_Count")) {
					 ##print "\nINSERT INTO service_report VALUES ('$week_date','$location','$f1',$f2)\n";
					 $myquery = $dbconn->prepare("INSERT INTO service_report VALUES ('$week_date','$location','$f1',$f2);");
					} 
				} elsif ($summary_flag ne "LAST") {
					##print "\nINSERT INTO nagios_log VALUES ('', '$mydate','$location',$time,'$host','$service_name','$alert_type');\n"; 
					$myquery = $dbconn->prepare("INSERT INTO nagios_log VALUES ('$mydate','$location',$time,'$host','$service_name','$alert_type');"); 
				}	
				my $qry_status=$myquery->execute();
				if ($qry_status) { print "\nNagios log inserted";} else { print "\nLog insert failed\n";}$myquery->finish;				
				######### end #########
			 }
			#print "\n".$_;
		}
	} #while end
	close(MYFILE);
	## close db connection
	$dbconn->disconnect;
} else { print "\n * Usage: $0 { <nagios weekly or daily csv log file> | --load_to_db } | --loc=[COLO, RS, RSUK, RSC, OMD]\n";}


#end
print "\n";
