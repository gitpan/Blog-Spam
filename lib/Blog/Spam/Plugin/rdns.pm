
=head1 NAME

Blog::Spam::Plugin::rdns - Reject content from hosts with no RDNS.

=cut

=head1 ABOUT

This plugin is designed to discard comments which have been submitted
by IP addresses with no reverse DNS entries defined.

Although many home ADSL/broadband providers will configure reverse DNS
of some generic form this plugin is liable to have a higher chance than
most others of creating false-positives.

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




package Blog::Spam::Plugin::rdns;


use strict;
use warnings;

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


=begin doc

Return the name of this plugin.

=end doc

=cut

sub name
{
    my ($self) = (@_);
    return ( $self->{ 'name' } );
}



=begin doc

Test whether the IP address has a reverse DNS entry.

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
    #  Reverse, so we can query.
    #
    my $rip = join( '.', reverse split( /\./, $ip ) ) . ".in-addr.arpa";


    my $res = Net::DNS::Resolver->new;
    my $query = $res->query( $rip, 'PTR' );
    if ($query)
    {

        # If the query was valid then get the answer.
        my $r = ( $query->answer )[0];

        if ( defined( $r->rdatastr ) )
        {
            return "OK";
        }
        else
        {
            return "SPAM:No reverse DNS entry for $ip";
        }
    }
    else
    {
        return "SPAM:No reverse DNS entry for $ip";
    }
}

1;
