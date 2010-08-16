#!/usr/bin/perl -w
#
#  Test that the POD we include in our scripts is valid, via the external
# podcheck command.
#
# Steve
# --
#

use strict;
use warnings;
use diagnostics;


use File::Find;
use Test::More qw( no_plan );

use FindBin qw($Bin);
use lib "$FindBin::Bin/../lib";


#
#  Find files.
#
find( { wanted => \&checkFile, no_chdir => 1 }, $Bin . "/../" );


#
#  Check a file.
#
#  If this is a perl file then call "perl -c $name", otherwise
# return
#
sub checkFile
{
    # The file.
    my $file = $File::Find::name;

    # We don't care about directories
    return if ( ! -f $file );
    return if ( $file =~ /\.hg/ );
    return if ( $file =~ /\/articles\// );

    # We have some false positives which fail our test but
    # are actually ok.  Skip them.
    my @false = qw(  ~ blogspam Makefile );

    foreach my $err ( @false )
    {
	return if ( $file =~ /$err/ );
    }

    # See if it is a perl file.
    my $isPerl = 0;

    # If the file has a '.pm' or '.cgi' suffix it is automatically perl.
    $isPerl = 1 if ( $file =~ /\.pm$/ );
    $isPerl = 1 if ( $file =~ /\.cgi$/ );

    # Read the file if we have to.
    if ( ! $isPerl )
    {
	open( INPUT, "<", $file );
	foreach my $line ( <INPUT> )
	{
	    if ( $line =~ /\/usr\/bin\/perl/ )
	    {
		$isPerl = 1;
	    }
	}
	close( INPUT );
    }

    #
    #  Return if it wasn't a perl file.
    #
    return if ( ! $isPerl );

    #
    #  Now run 'perl -c $file' to see if we pass the syntax
    # check.
    #
    my $retval = system( "perl -c $file 2>/dev/null >/dev/null" );


    is( $retval, 0, "Perl file passes our syntax check: $file" );
}
