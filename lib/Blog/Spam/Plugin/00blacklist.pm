
=head1 NAME

Blog::Spam::Plugin::00blacklist - Reject comments from known-bad IP addresses.

=cut

=head1 ABOUT

This plugin is designed to discard comments which have been submitted
from blacklisted IP addresses.

This plugin allows the XML-RPC connection which arrived to contain the
blacklisted IP addresses - it doesn't blacklist addresses which are
recorded upon the server this code is running upon.  (For that see
the module L<Blog::Spam::Plugin::badip>.


=cut

=head1 DETAILS

When an incoming comment is submitted for SPAM detection a number of
optional parameters may be included.  One of the optional parameters
is a list of CIDR ranges to automatically blacklist, and always return
a "SPAM" result from.

For full details of the available options please consult http://api.blogspam.net/

=cut

=head1 LICENSE

This code is licensed under the terms of the GNU General Public
License, version 2.  See included file GPL-2 for details.

=cut

=head1 AUTHOR

Steve
--
http://www.steve.org.uk/

=cut

=head1 LICENSE

Copyright (c) 2008-2010 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut


package Blog::Spam::Plugin::00blacklist;


use Net::CIDR::Lite;


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

Is the given IP blacklisted?

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);


    #  Get the IP - this is mandatory, but it might be ipv6.
    #
    my $ip = $params{ 'ip' };


    #
    #  See if there are any options in place.
    #
    my $options = $params{ 'options' };
    return "OK" if ( !defined($options) || !length($options) );

    #
    #  Split the options up.
    #
    foreach my $option ( split( /,/, $options ) )
    {

        #
        #  Blacklisted?
        #
        if ( $option =~ /blacklist=(.*)/i )
        {
            my $val = $1;

            my $cidr = Net::CIDR::Lite->new;
            $cidr->add_any($val);

            return "SPAM:Blacklisted" if ( $cidr->find($ip) );
        }
    }

    return "OK";
}


1;
