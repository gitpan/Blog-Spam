#!/usr/bin/perl -w
#
# This is a simple script which will read the entries from the
# log/spam/ directory and allow the admin to blacklist any
# IP addresses which submitted bogus comments.
#

# Steve
# --
#


use strict;
use warnings;
use CGI;

use File::Path;
use File::Basename;


#
#  Always show the MIME type.
#
print "Content-type: text/html\n\n";


#
#  Log directory.
#
my $log = "/home/www/www.blogspam.net/state/logs/ok";

#
#  Blacklist directory.
#
my $blacklist = "/home/www/www.blogspam.net/state/blacklist.d";

#
#  We might have been submitted files.
#
my $cgi  = new CGI;
my $ip   = $cgi->param("ip") || undef;
my $res  = $cgi->param("result") || undef;
my $file = $cgi->param("file") || undef;

#
#  If we were process the result
#
if ( defined($ip) && defined($res) )
{

    #
    #  Get the blacklist directory.
    #
    mkpath( $blacklist, { verbose => 0 } )
      unless ( -d $blacklist );


    #
    #  Create the blacklist entry.
    #
    if ( $res =~ /spam/i )
    {
        open( LOG, ">", "$blacklist/$ip" );
        print LOG;
        close(LOG);
    }

    if ( $file &&  $file =~ /^([a-z0-9_-]+)$/ )
    {
        unlink( $log . "/" . $file) if ( -e $log . "/" . $file );
    }
}



#
#  OK either we weren't submitting, or we've done so, so show the
# rest.
#


#
#  Only look at the ones that got through ..
#
foreach my $name ( sort( glob( $log . "/*" ) ) )
{

    #
    # The details from the submission header.
    #
    my $details = undef;

    #
    #  The comment
    #
    my $txt    = undef;
    my $header = 1;


    #
    #  Read.
    #
    open my $file, "<", $name;
    while ( my $line = <$file> )
    {
        chomp($line);
        $header = 0 if ( $line =~ /^$/ );

        if ( $header && ( $line =~ /^([^:]+):(.*)/ ) )
        {
            my $key = $1;
            my $val = $2;

            if ( $key && $val )
            {
                $key =~ s/^\s+|\s+$//g;
                $val =~ s/^\s+|\s+$//g;
                $details->{ $key } = $val;
            }
        }
        if ( !$header )
        {
            $txt .= $line;
        }
    }
    close($file);

    #
    #  Already blacklisted?  Ignore it.
    #
    next
      if ( ( !defined $details->{ 'ip' } ) ||
           ( !length( $details->{ 'ip' } ) ) );
    next if ( -e "$blacklist/$details->{'ip'}" );

    if ( $details && $details->{ 'ip' } && $txt )
    {

        print <<EOF;
<html>
<head><title>$details->{'ip'}</title></head>
 <body>
<h3>$details->{'ip'}</h3>
<blockquote>
EOF

        if ($details)
        {
            print "<table>\n";
            foreach my $key ( sort keys %$details )
            {
                my $val = $details->{ $key };
                print "<tr><td>$key</td><td>$val</td></tr>\n";
            }
            print "</table>\n";
        }

        $name = basename($name);

        print <<EOF;
<form>
<textarea rows="20" cols="80">
$txt
</textarea>
</form>
[<a href="/cgi-bin/mark.cgi?ip=$details->{'ip'};file=$name;result=spam">SPAM</a> |
<a href="/cgi-bin/mark.cgi?ip=$details->{'ip'};file=$name;result=good">GOOD</a> ]
</blockquote>
</body>
</html>
EOF

        exit 1;
    }
}


print "<p>No moderation left.  Check back later.</p>\n";
exit 0;

