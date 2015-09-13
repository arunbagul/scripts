#!/usr/bin/perl

#Author: Arun Bagul

use strict;
use warnings;
use IO::Socket;
use Digest::MD5 qw(md5);
#use threads;
#use threads::shared;

# unix socket file
my $socketfile ="/var/run/ldapcached.sock";
my $pidfile="/var/run/ldapcached.pid";

# program name
my $prog="ldapcached";
$0=$prog;
# ignore unix socket
$SIG{PIPE} = sub { my $continue = 0 };

no warnings 'uninitialized';
#################################
if ( $ARGV[0] =~ m/-?daemon/ )
{	
	if ( -f $pidfile) 
	{ 
		print " $prog pidfile exist!";
		chomp(my $pid=`cat $pidfile`);
		chomp (my $tmp=`ps ax -o pid | egrep "$pid|$prog" | grep -v grep`);
    		print "\n $prog running - $tmp\n";
		exit 1;
	}
	my %cache;
	########### Server Code ###########
	unlink $socketfile;
	my $data;
	my $server = IO::Socket::UNIX->new( Local  => $socketfile,
					    Type   => SOCK_STREAM,
					    Listen => 500 
                                    ) or die $!;
	# sock file ownership
	chmod 0644, $socketfile;
	chown scalar getpwnam('prod'), 0, $socketfile;
	$server->autoflush(1);
	while ( my $connection = $server->accept() ) 
	{

		my $data= <$connection>;
		##print $data, $/;
		chomp $data;
		############################
		my $auth_status="DONT";
		my ($key,$value)=split(/\s=!=\s/,$data);
		my $md5_value = md5($value);

		if (exists $cache{$key}){
			##print "\nUser exist";
			##while (my ($key1,$value1)=  each(%cache)) {  print "\n $key1 => $value1"; }
            		if ($md5_value eq $cache{$key}) { 
				##print "\nPassword matched from Cache\n"; 
				$auth_status="Pass";
			}
			else {
				##print "\nGo to LDAP - No password match\n";
				chomp(my $result=`/usr/bin/php /usr/local/bin/php-ldap.php '$key' '$value'`);
				if ($result eq 0) {$auth_status="Pass";$cache{$key}=$md5_value;} else {$auth_status="Failed";}		
			}
		} else {
			##print "\nGo to LDAP";
			chomp(my $result=`/usr/bin/php /usr/local/bin/php-ldap.php '$key' '$value'`);
			if ($result eq 0) {$auth_status="Pass"; $cache{$key}=$md5_value;} else {$auth_status="Failed";}
        	}
		## send data to client 
		print $connection "$auth_status\n";
	} ## end of while loop
	########### Server Code end #######

} else { print " * Usage: $0 < --daemon >";}

#end
print "\n";

