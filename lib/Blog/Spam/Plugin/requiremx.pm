
=head1 NAME

Blog::Spam::Plugin::requiremx - Reject email addresses to have an MX record.

=cut

=head1 ABOUT

This plugin is designed to discard comments which have been submitted with
an email address which has no MX record listed in DNS.

B<Note>: We don't actually do anything with the MX record - we'll just
look it up, and reject the comment if one is not found.

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



package Blog::Spam::Plugin::requiremx;


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

If we've got an email address make sure that the domain which it is
hosted upon has an MX record listed in DNS.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  Email isn't mandatory
    #
    my $mail = $params{ 'email' };

    #
    #  No mail?  Can't test.
    #
    return "OK" if ( !defined($mail) );


    #
    #  No "@" is spam
    #
    return "SPAM:No \@" unless ( $mail =~ /.\@./ );

    #
    #  Split address
    #
    my ( $user, $domain ) = split( /@/, $mail );

    #
    #  Create lookup object.
    #
    my $res = new Net::DNS::Resolver;
    $res->tcp_timeout(30);
    $res->udp_timeout(30);

    #
    #  Look for MX record for the domain
    #
    my $packet = $res->query( $domain, "MX" );
    if ( !( defined($packet) ) ||
         !( defined( $packet->answer() ) ) )
    {
        return ("SPAM:No MX");
    }

    return ("OK");
}



1;
