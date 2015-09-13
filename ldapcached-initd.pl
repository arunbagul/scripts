#!/usr/bin/perl

#Author: Arun Bagul

use strict;
use warnings;
use Proc::Daemon;

no warnings 'uninitialized';
if ( $ARGV[0] =~ m/start/ )
{

Proc::Daemon::Init;
my $continue = 1;
$SIG{TERM} = sub { $continue = 0 };

while ($continue) {  eval { `/usr/local/ldapcached.pl --daemon`;};}

} else { print " * Usage: $0 {start}";}

#end
print "\n";

