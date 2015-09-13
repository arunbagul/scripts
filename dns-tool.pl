#!/usr/bin/perl

#Author: Arun Bagul

sub BEGIN {
        unshift (@INC, '/usr/local/openlsm/lib/perl_module');
        unshift (@INC, '/usr/lib/perl5/');
}

use strict;
use warnings;
use POSIX qw(strftime);
use File::Slurp;

# global setting
my $BasePath = "/root/main-dns";
my $namedConf_Path = "${BasePath}/etc/named.conf";
my $ZoneDir = "${BasePath}";

## global variables
my %F_ZONE; my %R_ZONE; my %F_REC; my %R_REC; my %Hash_IPAddr;
my $Zone1;  my $Zone2; 

no warnings 'uninitialized';

################################
## functions
sub trim($) {
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}

## list of all available 
# ipaddrs in forward zone
sub IPList {	
	while (my ($z_name,$h_ref)=  each(%F_REC)) {
		while (my ($myhost,$h_info)=  each(%{$h_ref})) { 
			my $ipaddr = $h_info->{'A'};
			$Hash_IPAddr{"$ipaddr"}{'zone'} = $z_name;
		} #				
	} #zones	
}	
################################
my $GoAhead = "NO";

if ( (($ARGV[0] =~ m/-+compare/) && ($ARGV[1]) && ($ARGV[2])) || ($ARGV[0] =~ m/-+stats/) || ($ARGV[0] =~ m/-+verify/) ) {
	print "\nWelcome to dnsTool\n"; print "-" x 50 ."\n";
	$Zone1 = $ARGV[1]; $Zone2 = $ARGV[2]; $GoAhead = "YES"; 
} else { print "\n * Usage: $0  { --stats | --verify [<zone> | --reverse] | --compare <zone1> <zone2>}\n\n"; exit 1;}

#Parse named.conf file
my @text = read_file($namedConf_Path);
my $filter=0; my $z_name;
foreach my $line (@text) {
  chomp($line);
  if (($line !~ /^\s*$/) && ($line !~ /^\s*#.*/) && ($line !~ /^\s*;.*/)) {
	#print "\nL-$line";
	## forward and reverse zone
	if ($line =~ m/^\s?zone\s+("|')(\d+).(\d+).(\d+).in-addr.arpa("|')\s+{/) {
	   $filter=2; $z_name = "$4.$3.$2";
	   #print "\nReverse START- $4.$3.$2";
	} elsif (($line =~ m/^\s?zone\s+("|')(.*)("|')\s+.*{/) && ($line !~ m/arpa("|')\s+(IN|)\s+{/)) {
	  $filter=1; $z_name = "$2";
	   #print "\nForward START- $2";
	} elsif ($line =~ m/^\s?};.*$/ ) {
    	   if (($filter == 2) || ($filter == 1)) {
	   	#print "\n$line - END";
	   	$filter=0;  $z_name = undef;
	   }
        } else { 
	   if (($filter == 2) || ($filter == 1)) {
	  	#print "\nL-$line"; 
		if ($line =~ m/^\s+(\w+)\s+(.*);/) {
	  	   if ($z_name ne '.') { 
			my $field = "$2";
			my $field_key = "$1";
			$field =~ s/"//;
			$field =~ s/"//;
			#print "\n\tField[$z_name]- $1 - $2";
			if ($filter == 1) { $F_ZONE{"$z_name"}{"$field_key"} = $field; }
			if ($filter == 2) { $R_ZONE{"$z_name"}{"$field_key"} = "$field"; }
		   } #ignore zone-if
		}
	   }
	} #zone-if-else
  } #line-if
}
############### Action here ###############
while (my ($z_name,$h_ref)=  each(%F_ZONE)) {  
	#print "\nZone- $z_name => $h_ref->{'type'} => $h_ref->{'file'}"; 
	my $z_file = "${ZoneDir}/$h_ref->{'file'}";
	#print "\n\t File- $z_file";
	my @zoneData = read_file($z_file);
	## read-zonefile
	foreach my $line (@zoneData) {
		chomp($line);
		if (($line !~ /^\s*$/) && ($line !~ /^\s*#.*/) && ($line !~ /^\s*;.*/)) {
		if (($line !~ /^\$.*/) && ($line !~ /^\@.*/) && ($line !~ /^\s.*$/)) {
			if ($line =~ m/(.*)\s+.*IN\s+(A|PTR|CNAME)\s+(.*)/) {
				my @arr = split('\s+',$1);
				my ($record,$rec_type,$dns_info) = (trim($arr[0]), trim($2), trim($3));
				#print "\n\tZ[$z_name]=>'$record,$rec_type,$dns_info'";
				$F_REC{"$z_name"}{"$record"}{"$rec_type"} = "$dns_info";
			}
		}}
	}
	#read-zonefile-if	
}
while (my ($z_name,$h_ref)=  each(%R_ZONE)) {  
	#print "\nZone- $z_name => $h_ref->{'type'} => $h_ref->{'file'}";
	my $z_file = "${ZoneDir}/$h_ref->{'file'}";
	#print "\n\t File- $z_file";
	my @zoneData = read_file($z_file);
	## read-zonefile
	foreach my $line (@zoneData) {
			chomp($line);
			if (($line !~ /^\s*$/) && ($line !~ /^\s*#.*/) && ($line !~ /^\s*;.*/)) {
			if (($line !~ /^\$.*/) && ($line !~ /^\@.*/) && ($line !~ /^\s.*$/)) {
				if ($line =~ m/(.*)\s+.*IN\s+(A|PTR|CNAME)\s+(.*)/) {
					my @arr = split('\s+',$1);
					my ($record,$rec_type,$dns_info) = (trim($arr[0]), trim($2), trim($3));
					$dns_info =~ s/.$//;
					#print "\n\tZ[$z_name]=>'$record,$rec_type,$dns_info'";
					$R_REC{"$z_name"}{"$record"}{"$rec_type"} = "$dns_info";
				}
			}}
	}
	#read-zonefile-if
}
################################
if ($GoAhead eq "YES") {
	if ($ARGV[0] =~ m/-+verify/) {
		my $myloop = "NO";
		while (my ($z_name,$h_ref)=  each(%F_REC)) {
			if ($Zone1) { if ($Zone1 eq $z_name) { $myloop = "YES"; } } else { $myloop = "YES"; }
			if ($myloop eq "YES") {
				print "\nVerifying Zones: $z_name";
				print "\n\tReverse DNS entry Missing for hosts";
				while (my ($myhost,$h_info)=  each(%{$h_ref})) { 
					my $ipaddr;
					if ($h_info->{'A'}) {
						$ipaddr = $h_info->{'A'};
						my ($ip1, $ip2, $ip3,$ip4) = split('\.', $ipaddr);
						my $rev_zone = "${ip1}.${ip2}.${ip3}";
						if (not exists $R_REC{$rev_zone}{$ip4}{'PTR'}) {
							printf "\n\t%s = %s",$myhost, $ipaddr;
						}
					} elsif ($h_info->{'CNAME'}) {
						my $cname = $h_info->{'CNAME'};
						$ipaddr = $h_ref->{$cname}->{'A'} ;
						my ($ip1, $ip2, $ip3,$ip4) = split('\.', $ipaddr);
						my $rev_zone = "${ip1}.${ip2}.${ip3}";
						if (not exists $R_REC{$rev_zone}{$ip4}{'PTR'}) {
							if ($cname !~ m/www.*/) { printf "\n\t%s = %s (ip- %s)",$myhost,$cname, $ipaddr; }
						}
					}
				} #
				$myloop = "NO"; 
			} #myloop-if				
		} #zones
		## Check extra reverse lookup
		if ($Zone1 eq "--reverse") {
			IPList();
			while (my ($z_name,$h_ref)=  each(%R_REC)) {
				print "\nVerifying Zones: $z_name";
				print "\n\tExtra Reverse DNS entries";
				while (my ($myhost,$h_info)=  each(%{$h_ref})) {
					my $ipaddr = "${z_name}.$myhost";
					if (not exists $Hash_IPAddr{"$ipaddr"}) {
						print "\n\t${z_name}.$myhost";
					}	
				}#
			} #zones
		} ##reverse-loop	
	} elsif ($ARGV[0] =~ m/-+stats/) {
		my $F_Total = keys %F_REC;
		my $R_Total = keys %R_REC;
		my $TotalZone = $F_Total + $R_Total;
		print "\nDNS Summary:";
		print "\n\nTotal Zones- $TotalZone (Forward: $F_Total Reverse: $R_Total)\n";
		print "\nForward Zones\n";
		while (my ($z_name,$h_ref)=  each(%F_REC)) { 
			my $myTotal = keys %{$F_REC{$z_name}};
			printf("\n Zone Info: %s\t(Total_Records: %d)",$z_name, $myTotal);
		}
		print "\n\nReverse Zones\n";
		while (my ($z_name,$h_ref)=  each(%R_REC)) { 
			my $myTotal = keys %{$R_REC{$z_name}};
			printf("\n Zone Info: %s.0\t(Total_Records: %d)",$z_name, $myTotal);
		}		
	} elsif ($ARGV[0] =~ m/-+compare/) {
		print "\nComparing Zone: $Zone1 with $Zone2";
	}	
}

#end
print "\n\n";
