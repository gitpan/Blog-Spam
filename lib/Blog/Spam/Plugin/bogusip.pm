
=head1 NAME

Blog::Spam::Plugin::bogusip - Reject comments from bogus IP addresses.

=cut

=head1 ABOUT

This plugin is designed to discard comments which have been submitted
from "internal-only" IP addresses.

In the real world such things shouldn't be seen, but since we present
an API which is open to callers around the world we cannot control what
details they send to us.

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



package Blog::Spam::Plugin::bogusip;


use strict;
use warnings;

use Net::CIDR::Lite;


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

Is this an internal IP?

That might be fine for local use, but in the real world such IPs
are not going to be seen and can be safely marked as spam.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  Get the IP - this is mandatory, but it might be ipv6.
    #
    my $ip = $params{ 'ip' };
    return "OK" if ( $ip =~ /:/ );


    #
    #  Quick test on leading octet
    #
    return "OK" unless ( $ip =~ /^(10|172|192)\./ );


    #
    #  For each internal range, test.
    #
    foreach my $range (qw! 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 !)
    {
        my $cidr = Net::CIDR::Lite->new;
        $cidr->add_any($range);

        return "SPAM:Internal Only IP"
          if ( $cidr->find($ip) );
    }

    return "OK";
}


1;
