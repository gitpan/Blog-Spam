
=head1 NAME

Blog::Spam::Plugin::drone - Lookup comment submissions in dronebl.org

=cut

=head1 ABOUT

This plugin is designed to test the submitters of comments against the
dropnbl.org realtime blacklist service.

An IP which is listed in the service will be refused the ability to
submit comments - and this result will be cached for a week.

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


package Blog::Spam::Plugin::drone;


use strict;
use warnings;

use File::Path;
use Net::DNS::Resolver;



=begin doc

Constructor.  Called when this plugin is instantiated.

This merely saves away the name of our plugin.

=end doc

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{ 'name' } = $proto;

    # verbose?
    $self->{ 'verbose' } = $supplied{ 'verbose' } || 0;

    bless( $self, $class );
    return $self;
}


sub name
{
    my ($self) = (@_);
    return ( $self->{ 'name' } );
}



=begin doc

Test whether the IP address submitting the comment is listed
in the drone blacklist:

     http://www.dronebl.org/

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
    # We cannot lookup IPv6 addresses.
    #
    return "OK" if ( $ip =~ /:/ );

    #
    #  Malformed IP?
    #
    return "SPAM" unless ( $ip =~ /^([0-9\.]+)$/ );

    #
    #  Get the state directory which we'll use as a cache.
    #
    my $state = $params{ 'parent' }->getStateDir();
    my $cdir  = $state . "/cache/drone/";

    #
    #  Is the result cached?
    #
    my $safe = $ip;
    $safe =~ s/[:\.]/-/g;
    if ( -e "$cdir/$safe" )
    {
        return ("SPAM:Listed in dronebl.org");
    }


    #
    #  Not found in the cache.  Query DNS, then add any
    # positive result to the cache
    #

    #
    #  Reverse the IP for querying.
    #
    my $reversed_ip = join( ".", reverse( split( /\./, $ip ) ) );


    my $res = new Net::DNS::Resolver;
    $res->tcp_timeout(30);
    $res->udp_timeout(30);

    my $packet = $res->query( "$reversed_ip.dnsbl.dronebl.org.", "A" );
    if ( ( defined($packet) ) &&
         ( defined( $packet->answer() ) ) )
    {

        #
        #  Cache the result
        #
        if ( !-d $cdir )
        {
            mkpath( $cdir, { verbose => 0 } );
        }
        open( FILE, ">", "$cdir/$safe" ) or
          die "Failed to open $cdir/$safe - $!";
        print FILE "\n";
        close(FILE);

        return ("SPAM:dronebl");
    }

    return ("OK");
}




=begin doc

Expire our cached drone entries once a week.

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
        my $cdir  = $state . "/cache/drone/";

        foreach my $entry ( glob( $cdir . "/*" ) )
        {

            #
            #  We're invoked once per day, but we only
            # cleanup files older than a week.
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
