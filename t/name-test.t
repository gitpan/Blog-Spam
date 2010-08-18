#!/usr/bin/perl -w
#
#  Test that each plugin we have can be created and has a name.
#
# Steve
# --
#

use strict;
use warnings;
use diagnostics;


use File::Find;
use File::Basename;
use Test::More qw( no_plan );

use FindBin qw($Bin);
use lib "$FindBin::Bin/../lib";


#
#  Find files.
#
find( { wanted => \&checkFile, no_chdir => 1 },
      $Bin . "/../lib/Blog/Spam/Plugin/" );


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
    return if ( !-f $file );
    return unless ( $file =~ /\.pm$/i );

    #
    #  Get the module name
    #
    my $name = basename($file);
    my $pkg  = "Blog::Spam::Plugin::$name";
    $pkg =~ s/\.pm$//g;

    eval {
        require $file;

        my $x = $pkg->new();
        ok( $x,              "Loaded package $pkg" );
        ok( $x->can("name"), "The package implements name();" );
        isa_ok( $x, $pkg, "The object has the correct type" );

        is( $x->name(), $pkg, "The method name() returned $pkg" );
    };
    if ($@)
    {
        print "FAILED: $@\n";
    }

}
