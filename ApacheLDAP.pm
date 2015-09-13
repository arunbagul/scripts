package Apache::ApacheLDAP;

##################################
# Apache Basic Auth
# Handler file -Apache/ApacheLDAP.pm
# Author: Arun Bagul
##################################

use strict;
use Apache2::Const qw(:common);
use Apache2::Access;
use Apache2::RequestRec;
use Apache2::Log;

use strict;
use warnings;
use Net::LDAP;

sub LDAP_auth
{
    my ($login_user,$login_pass)=@_;

    my $ldap_pass='MYPASS';
    my $ldap = Net::LDAP->new('192.168.0.1', port=>389, scheme => 'ldap', timeout =>10, version =>3, debug=>0 ) or die "Can't bind to ldap: $!\n";
    my $mesg = $ldap->bind( "CN=nagios,CN=Users,DC=XYZ,DC=com", password =>"$ldap_pass");

    no warnings 'uninitialized';
    $mesg = $ldap->search (
          base  => "DC=XYZ,DC=com",
          filter => "(&(sAMAccountName=$login_user)(objectClass=user))",
          scope => 'sub'
 	);

  if ($mesg->count == 1){ 
	chomp(my $result=`/usr/bin/php /usr/local/bin/php-ldap.php '$login_user' '$login_pass'`);
	if ($result eq 0) {return "Passed";} else { return "Failed";}
	return "Passed";
  } else { return "Failed";}

}
#####################

sub handler {
   my $r = shift;

    my($res, $sent_pw) = $r->get_basic_auth_pw;
   return $res if $res != OK;

    #my $user = $r->connection->user;
    my $user = $r->user;
   unless($user and $sent_pw) {
       $r->note_basic_auth_failure;
       $r->log_reason("Please provide username and password",$r->filename);
       return AUTH_REQUIRED;
   }
   if (LDAP_auth($user,$sent_pw) eq "Failed") { $r->note_basic_auth_failure; return AUTH_REQUIRED;}; 
   return OK;    
}

1;
