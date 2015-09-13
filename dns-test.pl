#!/usr/bin/perl

#Author: Arun Bagul

use strict;
use warnings;

chomp(my $myhost=`hostname`);
my @arun_host=split(/\./, $myhost); $myhost=$arun_host[0];

######### function #######

sub hostname {

  my (@bytes, @octets,
    $packedaddr,
    $raw_addr,
    $host_name,
    $ip
  );

  if($_[0] =~ /[a-zA-Z]/g) {
    $raw_addr = (gethostbyname($_[0]))[4];
    @octets = unpack("C4", $raw_addr);
    $host_name = join(".", @octets);
  } else {
    @bytes = split(/\./, $_[0]);
    $packedaddr = pack("C4",@bytes);
    $host_name = (gethostbyaddr($packedaddr, 2))[0];
  }

  return($host_name);
}

######### main  #######
no warnings 'uninitialized';

if ($ARGV[0])
{	
	##print "\n DNS testing from Host ($myhost)";
	my $host_ip = hostname($ARGV[0]);
	print "\n'$ARGV[0]' is resolving to ipaddr = $host_ip";

} else { print " * Usage: $0 <domain name>";}

#end

print "\n";
