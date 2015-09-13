
#!/usr/bin/perl
# Nagios will send mail to Ticketing system
# creating ticket from email
# Author: Arun Bagul
#

use Getopt::Std;
use Mail::Mailer;
$script    = "creat_ticket.pl";
$script_version = "1.1.1";
$host = "";
$ackcomment = "";
$stateid = "";
$ackauthor = "Creat_Ticket";
$hostoutput = "";
$notificationtype = "";
$servicedesc = "";
$contactemail = "";

# from e-mail address below
$from = "nagios\@XYZ.com";

$cmdfile = "/usr/local/nagios/var/rw/nagios.cmd";
$logfile = "/tmp/test.txt";
$debug = 0;
$external = 1;
# Do we have enough information?
if (@ARGV < 1) {
     print "Too few arguments\n";
     usage();
}

getopts("hS:");
#print "$opt_h\n\n";
if ($opt_h){
    usage();
    exit(0);
}
elsif ($opt_S){
   ($host,$ackcomment,$ackauthor,$output,$stateid,$notificationtype,$servicedesc,$contactemail) = split /\^/, $opt_S;
    # print "Input String $opt_S\n";
}
else {
    print "No Input String specified\n";
    usage();
}

if ($debug){
   open (file, ">>".$logfile);
   print file "Host:$host, AckComment:$ackcomment, AckAuthor:$ackauthor, OutPut:$output, StateID:$stateid, NotificationType:$notificationtype, ServiceDesc:$servicedesc, E-Mail:$contactemail\n";
   close (file);
}
@state = ("OK", "Warning", "Critical", "Unknown");

if ($notificationtype eq "ACKNOWLEDGEMENT"){
  $type = 'sendmail';
  $mailprog = Mail::Mailer->new($type);
  # mail headers to use in the message
  %headers = (
      'To' => "$contactemail",
      'From' => "$from",
      'Subject' => "Event Notification - $host/$servicedesc: $state[$stateid]",
  );
  $mailprog->open(\%headers);
  print $mailprog "Host: $host\n";
  print $mailprog "Service: $servicedesc\n";
  print $mailprog "Service State: $state[$stateid]\n";
  print $mailprog "Event: $output\n";
  print $mailprog "Comment: $ackcomment\n";
  print $mailprog "Submit by: $ackauthor\n";
 $mailprog->close;
 if ($external){
  $now = (time);
  open (cmdf, ">>".$cmdfile);
  print cmdf "[$now] ADD_HOST_COMMENT;$host;1;$ackauthor;<a href=\"https://black.wightman.ca/rt/\" TARGET='_blank'>A Ticket is opened by $ackauthor<\/a>\n";
  close (cmdf);
}

}


sub usage {
    print << "USAGE";
--------------------------------------------------------------------
$script v$script_version

When an event is acknowledge in Nagios, this script will open a ticket in RT

Usage: $script -S "<hostname>^<ackcomment>^<ackauthor>^<output>^<stateid>^<notificationtype>^<servicedesc>^<contactemail>"

Options: -h       Shows this help
         -S       The sting that should contain the followings combined with "^" character.
                     Hostname (\$HOSTNAME\$) 
                     AckComment (\$HOSTACKCOMMENT\$ or \$SERVICEACKCOMMENT\$)
                     AckAuthor (\$HOSTACKAUTHOR\$ or \$SERVICEACKAUTHOR\$)
                     OutPut (\$HOSTOUTPUT\$ or \$SERVICEOUTPUT\$)
                     Notificationtype (\$NOTIFICATIONTYPE\$)
                     ServiceDescription (\$SERVICEDESC\$)
                     ContactE-Mail (\$CONTACTEMAIL\$)

USAGE
     exit 1;
}

