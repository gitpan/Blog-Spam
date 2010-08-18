#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use File::Temp qw! tempdir !;
use File::Path;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 8;



#
#  Stub package.
#
package Blog::Spam::Server;


sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    #
    #  Allow user supplied values to override our defaults
    #
    foreach my $key ( keys %supplied )
    {
        $self->{ lc $key } = $supplied{ $key };
    }

    bless( $self, $class );
    return $self;
}


sub getStateDir
{
    my ($self) = (@_);

    return ( $self->{ 'dir' } );
}



package main;

use_ok('Blog::Spam::Plugin::httpbl');
require_ok('Blog::Spam::Plugin::httpbl');

#
#  Create a stub server object.
#
my $dir = tempdir( CLEANUP => 1 );
my $stub = Blog::Spam::Server->new( dir => $dir );
isa_ok( $stub, "Blog::Spam::Server",
        "Stub object identifies itself correctly" );

#
#  Create some entries in the directory
#
mkpath( "$dir/cache/httpbl", { verbose => 0 } );

#
#  Ensure the directory is empty
#
is( countFilesInDir("$dir/cache/httpbl/"), 0, "New directory is empty" );

#
#  Add a file
#
open( TMP, ">", "$dir/cache/httpbl/foo" );
close(TMP);
is( countFilesInDir("$dir/cache/httpbl/"), 1, "New directory has an entry" );


#
#  Now try to cleanup.
#
my $bl = Blog::Spam::Plugin::httpbl->new();
isa_ok( $bl, "Blog::Spam::Plugin::httpbl",
        "httpbl object identifies itself correctly" );
$bl->expire( $stub, "daily" );

#
#  Since the file is recent the content should still be one file.
#
is( countFilesInDir("$dir/cache/httpbl/"),
    1, "New directory has an entry after cleaning - since it is 'recent'" );


#
#  Modify file
#
my $now = time;
$now -= 30 * ( 60 * 60 * 24 );
utime $now, $now, "$dir/cache/httpbl/foo";


#
#  Expire again.
#
$bl->expire( $stub, "daily" );

#
#  Since the file is recent the content should still be one file.
#
is( countFilesInDir("$dir/cache/httpbl/"),
    0, "New directory empty after file has been aged." );



#
#  Helper
#
sub countFilesInDir
{
    my ($dir) = (@_);

    my $count = 0;
    foreach my $file ( sort( glob( $dir . "/*" ) ) )
    {
        $count += 1;
    }
    return ($count);
}
