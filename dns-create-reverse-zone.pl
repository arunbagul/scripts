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
use POSIX qw(strftime);

# global setting
my $BasePath = "/var/named/chroot";
my $namedConf_Path = "${BasePath}/etc/named.conf";
my $ZoneDir = "${BasePath}/var/named";

## global variables
my %F_ZONE; my %R_ZONE; my %F_REC; my %R_REC; my %Hash_IPAddr;
my $Zone1;  my $Zone2; 

my $mydate = strftime "%Y%m%d%H",localtime();

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

if ( $ARGV[0] =~ m/-+generate/ ) {
	print "\nWelcome to dnsTool\n"; print "-" x 50 ."\n";
	$Zone1 = $ARGV[1]; $Zone2 = $ARGV[2];
} else { print "\n * Usage: $0  { --generate [<zone> }\n\n"; exit 1;}

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
my %Gen_Reverse;
while (my ($z_name,$h_ref)=  each(%F_REC)) {
	if ($Zone1 eq $z_name) {
		print "\nGenerating Reverse zone file for Zones: $z_name";
		while (my ($myhost,$h_info)=  each(%{$h_ref})) { 
			my $ipaddr;
			if ($h_info->{'A'}) {
				$ipaddr = $h_info->{'A'};
				my ($ip1, $ip2, $ip3,$ip4) = split('\.', $ipaddr);
				my $rev_zone = "${ip3}.${ip2}.${ip1}.in-addr.arpa";
				#printf "\n$rev_zone = $ip4\tIN\tPTR\t${myhost}. => $ipaddr";
				if ($myhost =~ m/^(app|netapp|file|oracle).*/) {
					$Gen_Reverse{$rev_zone}{$ip4} = $myhost;
					if ("$ip2" eq "28" ) {
						my $tmp_zone = "${ip3}.29.${ip1}.in-addr.arpa";
						$Gen_Reverse{$tmp_zone}{$ip4} = $myhost;
					} elsif ("$ip2" eq "29" ) {
						my $tmp_zone = "${ip3}.28.${ip1}.in-addr.arpa";
						$Gen_Reverse{$tmp_zone}{$ip4} = $myhost;
					} elsif ("$ip2" eq "30" ) {
						my $tmp_zone = "${ip3}.31.${ip1}.in-addr.arpa";
						$Gen_Reverse{$tmp_zone}{$ip4} = $myhost;
					} elsif ("$ip2" eq "31" ) {
						my $tmp_zone = "${ip3}.30.${ip1}.in-addr.arpa";
						$Gen_Reverse{$tmp_zone}{$ip4} = $myhost;
					} else {
						if ("$ip3" eq "3" ) {
							my $tmp_zone = "4.${ip2}.${ip1}.in-addr.arpa";
							$Gen_Reverse{$tmp_zone}{$ip4} = $myhost;
						} elsif ("$ip3" eq "4" ) {
							my $tmp_zone = "3.${ip2}.${ip1}.in-addr.arpa";
							$Gen_Reverse{$tmp_zone}{$ip4} = $myhost;
						}
					} #ip2-if				
				}
				if ($myhost =~ m/^(production|smtp|servepath|router).*/) {
					$Gen_Reverse{$rev_zone}{$ip4} = $myhost;
				}				
			}	
		} #while-loop
	} #myloop-if				
} #zones

### Generate Reverse Zone file

while (my ($z_name,$h_ref)=  each(%Gen_Reverse)) {

my $SOA = qq{
\$TTL    86400
${z_name}.             IN SOA  localhost      root (
                                        $mydate      ; serial (d. adams)
                                        3H              ; refresh
                                        15M             ; retry
                                        1W              ; expiry
                                        1D )            ; minimum

@                               IN      NS              appmon1.XYX.colo.
@                               IN      NS              appmon2.XYX.colo.
};	
	print "\n\nFILE- $z_name";
	open (MYMAP, ">/tmp/${z_name}");
	print MYMAP ";Reverse DNS files\n";
	print MYMAP "$SOA";
	#foreach my $key (reverse sort keys %{$h_ref}) {
	foreach my $key (sort {$a <=> $b} (keys %{$h_ref})) {
		print MYMAP "\n$key\t IN \t PTR \t $h_ref->{$key}.";
	}
	print MYMAP "\n";
	close (MYMAP);	
}

#end
print "\n\n";
