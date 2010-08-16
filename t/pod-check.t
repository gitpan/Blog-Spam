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
#  Check a file for POD syntax.
#
#  If this is a perl file then call "podcheck $name", otherwise
# return.
#
sub checkFile
{
    # The file.
    my $file = $File::Find::name;

    # We don't care about directories
    return if ( ! -f $file );

    # We have some false positives which fail our test but
    # are actually ok.  Skip them.
    my @false = qw( ~ tests/ );

    foreach my $err ( @false )
    {
	return if ( $file =~ /$err/ );
    }

    # See if it is a perl file.
    my $isPerl = 0;

    #
    #  Files with a .pm, .cgi, and .t suffix are perl.
    #
    if ( ( $file =~ /\.pm$/ ) ||
         ( $file =~ /blogspam$/ ) )
    {
        $isPerl = 1;
    }

    #
    #  Return if it wasn't a perl file.
    #
    return if ( ! $isPerl );


    ok( -e $file, "$file" );

    if ( ( -x $file ) && ( ! -d $file ) )
    {
        #
        #  Execute the command giving STDERR to STDOUT where we
        # can capture it.
        #
        my $cmd           = "podchecker $file";
        my $output = `$cmd 2>&1`;
        chomp( $output );

        is( $output, "$file pod syntax OK.", " File has correct POD syntax: $file" );
    }
}

