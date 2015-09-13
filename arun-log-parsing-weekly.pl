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
my @nag_logfiles;

########################################################
#my $file = "/usr/local/nagios/var/nagios.log";
my $filelist = $ARGV[1] || "/tmp/nagios.filelist";
my $total_logfiles = undef;
########################################################
sub nagioslog_filelist {
	my ( $list, $arr_ref ) = (@_);
	my $tmp_count = 0;
	print "\nReading nagios log files from file- $list\n";
	## reading nagios log filelist from $list file
	open (MYFILE, "<$list" ) or die "Can't open $list file";
	while(<MYFILE>) {
		chomp;
		if ($_ !~ m/^$/) { 
			my $myfile = $_;
			##print $myfile."\n";
			if ( ! -e $myfile) { print "\nCan't read nagios log file '$myfile', all logfiles must be readable!\n"; exit(1);} 
			else { ${$arr_ref}[$tmp_count] = "$myfile"; $tmp_count++;}
		} ## if end,testing for not blank line
	}	
	## close list file
	close(MYFILE);
	print "\nTotal Nagios logs files to read: $tmp_count";
	return($tmp_count);
}
########################################################
if ($ARGV[0] eq "--summary") {
	
  $total_logfiles = nagioslog_filelist($filelist,\@nag_logfiles);
  foreach my $myfile (@nag_logfiles) {
	##print "\nFile=$myfile";	
	## reading nagios log 
	open (LOGFILE, "<$myfile" ) or die "Can't open $myfile nagios log file";
	while(<LOGFILE>) {
		 ## time diff 609000 
		 chomp;
		 my $line = $_;
		 ##print "\n".$line;
		if ($line =~ m/\[(.*)\]\s+SERVICE\sNOTIFICATION:\s\w+;(.*);.*/) {
			my $time = $1;
			my $arun_diff = 1314362145 - $time ;
		if ( $arun_diff < 609000 ) {
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
		  } ## arun diff end
		} elsif ($line =~ m/\[(.*)\]\s+HOST\sNOTIFICATION:\s\w+;(.*);.*/) {
			my $time = $1;
			my $arun_diff = 1314362145 - $time ;
			if ( $arun_diff < 609000 ) {
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
		 } #arun diff end
		} ## elsif end
	}	
	## close myfile
	close(LOGFILE);
  } ## reading logfiles end	
  ############## Summary #################	
    ## summary
    my $total_counter = 0;
    my $total_service = keys(%ALERT);
    if ($ARGV[0] eq "--summary") {
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
  ############## Summary end #############	
  
  
} else { print "\n * Usage: $0 { < --summary >  [nagios_log filelist default is '/tmp/nagios.filelist'] }";}
########################################################

#end
print "\n\n";
