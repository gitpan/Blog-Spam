
=head1 NAME

Blog::Spam::Plugin::hashcash - Block comments which have bogus Wordpress values

=cut

=head1 ABOUT

This plugin is designed to test the submitters of comments which were
left upon Wordpress blogs, with erroneous contents.

There exists a HashCash plugin for Wordpress which will update the body
of the comments in the case where failures are observed - we take advantage
of that and block the ones which have been identified.

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



package Blog::Spam::Plugin::hashcash;


use strict;
use warnings;
use URI::Find;


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

Block if we find a warning generated by the Wordpress HashCash plugin.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  Get the body content.
    #
    my $body = $params{ 'comment' };

    #
    #  Strip newlines, etc.
    #
    $body =~ s/[\r\n]//g;

    #
    #  Bogus?
    #
    if ( $body =~
        /\[WORDPRESS HASHCASH\] The poster sent us .* which is not a hashcash value/i
       )
    {
        return "SPAM:Hashcash warning";
    }
    else
    {
        return "OK";
    }
}


1;