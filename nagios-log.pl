#!/usr/bin/perl

#
# Read nagios.log file and show log with
# converted date field in human-readable format
# Author: Arun Bagul

$numArgs = $#ARGV + 1;
if ( $ARGV[0] eq "-h")
{
print " * Usage: cat  <nagios.log file path> like '/usr/local/nagios/var/nagios.log' | $0 \n"; exit 1;
}

sub epochtime
{
  my $epoch_time = shift;
  ($sec,$min,$hour,$day,$month,$year) = localtime($epoch_time);

  # correct the date and month for humans
  $year = 1900 + $year;
  $month++;

  return sprintf("%02d/%02d/%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec);
}


while (<>)
{
  my $epoch = substr $_, 1, 10;
  my $remainder = substr $_, 13;
  my $human_date = &epochtime($epoch);
  printf("[%s] %s", $human_date, $remainder);
}
exit;
