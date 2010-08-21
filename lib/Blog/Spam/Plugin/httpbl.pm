
=head1 NAME

Blog::Spam::Plugin::httpbl - Lookup submitters in the HTTP;bl list

=cut

=head1 ABOUT

This plugin is designed to test the submitters of comments against the
project honeypot RBL - HTTP;bl.

An IP which is listed in the service will be refused the ability to
submit comments - and this result will be cached for a week.

=cut

=head1 DETAILS

B<NOTE>: You must have an API key to use this function, and that
key should be stored in /etc/blogspam/httpbl.key.

You can find further details of the Project Honeypot via
http://www.projecthoneypot.org/httpbl_configure.php


=cut

=head1 AUTHOR

=over 4

=item Steve Kemp

http://www.steve.org.uk/

=back

=cut

=head1 LICENSE

Copyright (c) 2008-2010 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut



package Blog::Spam::Plugin::httpbl;

use strict;
use warnings;

use File::Path;
use Socket;


=begin doc

Constructor.  Called when this plugin is instantiated.

=end doc

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    # verbose?
    $self->{ 'verbose' } = $supplied{ 'verbose' } || 0;

    bless( $self, $class );
    return $self;
}




=begin doc

Test whether the IP address submitting the comment is listed
in the blacklist.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  IP is mandatory - we will always have it.
    #
    my $ip = $params{ 'ip' };

    #
    #  But we cannot cope with non-IPv4 addresses.
    #
    return "OK" unless ( $ip =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ );

    #
    #  Get the state directory which we'll use as a cache.
    #
    my $state = $params{ 'parent' }->getStateDir();
    my $cdir  = $state . "/cache/httpbl/";

    #
    #  Is the result cached?
    #
    my $safe = $ip;
    $safe =~ s/[:\.]/-/g;
    if ( -e "$cdir/$safe" )
    {

        #
        #  Update the modification time so that it
        # persists longer than the expected time since
        # we've had a fresh hit.
        #
        $self->touchCache("$cdir/$safe");

        #
        #  Return the cached result
        #
        return ("SPAM:Cached from HTTP;bl");
    }

    #
    #  Reverse for lookup
    #
    my $rev_ip = join( ".", reverse split( /\./, $ip ) );

    #
    #  Now lookup.
    #
    my $httpbl_key  = "keykeykeykey";
    my $httpbl_zone = "dnsbl.httpbl.org";
    my $name        = "$httpbl_key.$rev_ip.$httpbl_zone";

    #
    #  Get the key
    #
    if ( -e "/etc/blogspam/httpbl.key" )
    {
        if ( open( FILE, "<", "/etc/blogspam/httpbl.key" ) )
        {
            $httpbl_key = <FILE> || "";
            chomp($httpbl_key);
            close(FILE);
        }
    }

    #
    #  Fail?
    #
    my @a = gethostbyname($name);
    unless ( $#a > 3 )
    {
        return "OK";
    }

    #
    #  Work out what is going on.
    #
    @a = map {inet_ntoa($_)} @a[4 .. $#a];
    my ( undef, $days, $threat, $type ) = split( /\./, $a[0] );

    unless ( $type & 7 )
    {
        return "OK";
    }

    #
    #  Blocked.
    #
    #  Cache the result
    #
    if ( !-d $cdir )
    {
        mkpath( $cdir, { verbose => 0 } );
    }

    #
    #  Save in the cache.
    #
    $self->touchCache("$cdir/$safe");

    #
    #  Return spam result
    #
    return ("SPAM:Listed in HTTP;bl");
}




=begin doc

Create/Update the mtime of a file in the cache
directory.

=end doc

=cut

sub touchCache
{
    my ( $self, $file ) = (@_);

    open( FILE, ">", $file ) or
      return;
    print FILE "\n";
    close(FILE);
}




=begin doc

Expire our cached entries once a week.

=end doc

=cut

sub expire
{
    my ( $self, $parent, $frequency ) = (@_);

    #
    #  Max age of files to keep.
    #
    my $max = $self->{ 'age' } || 7;

    if ( $frequency eq "daily" )
    {
        my $state = $parent->getStateDir();
        my $cdir  = $state . "/cache/httpbl/";

        foreach my $entry ( glob( $cdir . "/*" ) )
        {

            #
            #  We're invoked once per day, but we only
            # cleanup once a month.
            #
            my $age = int( -M $entry );

            if ( $age >= $max )
            {
                $self->{ 'verbose' } && print "\tRemoving: $entry\n";
                unlink($entry);
            }
            else
            {
                $self->{ 'verbose' } &&
                  print "\tLeaving $entry - $age days old <= $max\n";
            }
        }
    }
}

1;
