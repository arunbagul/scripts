#!/usr/bin/perl

#Author: Arun Bagul

my $file = $ARGV[0];
my $stime = 0;
my $htime = 0;
my ($s_alert,$h_alert ) = (undef,undef);

my $STATE_OK;
my $STATE_WARNING;
my $STATE_CRITICAL;
my $STATE_UNKNOWN;
my %STATE_COUNTER;
my %ALERT;

############################

if ($ARGV[0]) {
#my $file = "/usr/local/nagios/var/nagios.log";

open (MYFILE, "<$file" ) or die "Can;t open nagios file";
while(<MYFILE>) {
	chomp;
	my $line = $_;
        ##print "\n".$line;
	if ($line =~ m/\[(.*)\]\s+SERVICE\sNOTIFICATION:\s\w+;(.*);.*/) {
		my $time = $1;
		my $mydate = scalar(localtime($time));
		my ($host,$service,$alert)  = split(';',$2);
		#print "\nARUN=>$1 = $host,$service,$alert";
		if ($s_alert eq $service) {
		  my $time_diff = $time - $stime;
		  if ($time_diff > 600 ) {
			 if ($alert ne "OK") {
			   if (exists $ALERT{"$service"}) { $ALERT{"$service"} = $ALERT{"$service"} + 1;}
			   else { $ALERT{"$service"} = 1 ; } 
			   $STATE_COUNTER{"$alert"} = $STATE_COUNTER{"$alert"} + 1;
			   print "\n$mydate [$time],$host,$service,$alert";
			 }
		  } 
		} else {
			 if ($alert ne "OK") {
			   if (exists $ALERT{"$service"}) { $ALERT{"$service"} = $ALERT{"$service"} + 1;}
			   else { $ALERT{"$service"} = 1 ; }			
			   $STATE_COUNTER{"$alert"} = $STATE_COUNTER{"$alert"} + 1;
			   print "\n$mydate [$time],$host,$service,$alert";
			 }
		}
		$stime = $time;
		$s_alert = $service;

	} elsif ($line =~ m/\[(.*)\]\s+HOST\sNOTIFICATION:\s\w+;(.*);.*/) {
		my $time = $1;
		my $mydate = scalar(localtime($time));
		my ($host,$hdown,$alert)  = split(';',$2);
		#print "\nARUN=>$1 = $host,$hdown";
		if ($hdown eq "DOWN") {
		   if ($h_alert eq $host) {
		      my $time_diff = $time - $htime;
		      if ($time_diff > 600 ) {
			$STATE_COUNTER{"$hdown"} = $STATE_COUNTER{"$hdown"} + 1;
			print "\n$mydate [$time],$host,$hdown";
		      }
		   } else {	
			$STATE_COUNTER{"$hdown"} = $STATE_COUNTER{"$hdown"} + 1;
			print "\n$mydate [$time],$host,$hdown";
		   }
		}
		$htime = $time;
		$h_alert = $host;
	}
}
	close(MYFILE);
    ## summary
    my $total_counter = 0;
    my $total_service = keys(%ALERT);
    if ($ARGV[1] eq "--summary") {
	print "\n\n"."-" x 20;
	print "\nSummary Report\n";
	print "-" x 20 . "\n";
	print "\nAlert_Type,Total_Count";
	while (my ($key,$value)=  each(%STATE_COUNTER)) {  print "\n$key,$value"; }
	print "\n\nService_Name,Total_Count";
	while (my ($key,$value)=  each(%ALERT)) { print "\n$key,$value"; $total_counter = $total_counter + $value; }
	print "\n\nTotal Alerts = $total_counter";
	print "\nTotal Service Failed = $total_service";
    }

} else { print " * Usage: $0 { <nagios_log file>  [ --summary ] }";}

#end
print "\n";

