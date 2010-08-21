
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

    #
    #  Skip a couple of ranges.
    #
    return "SPAM:Internal IP"
      if ( ( $ip =~ /^10\.0/ ) ||
           ( $ip =~ /^192\.168\./ ) );

    return "OK";
}


1;
