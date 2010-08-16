
=head1 NAME

Blog::Spam::Plugin::lotsaurls - Reject comments containing multiple URLs.

=cut

=head1 ABOUT

This plugin is designed to discard comments which contain a significant
number of URLs.

By default 10 URLs is the threshold, but this may be changed by the
submitter via the optional parameters submitted to the server - see
http://api.blogspam.net for details of those parameters.


All URLS are detected via the L<URI::Find> module.

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



package Blog::Spam::Plugin::lotsaurls;


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

Block if we find more than a given number of links in message.

The default is 10 links, but this may be changed by the caller.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  User might have set "max-links".
    #
    my $max = 10;

    #
    #  See if the max-links flag was set.
    #
    my $options = $params{ 'options' } || "";
    foreach my $option ( split( /,/, $options ) )
    {
        if ( $option =~ /max-links=([0-9]+)/i )
        {
            $max = $1;
        }
    }

    #
    #  Get the body content.
    #
    my $body = $params{ 'comment' };

    #
    #  Create the helper
    #
    my $finder = URI::Find->new(
        sub {
            my ( $uri, $orig_uri ) = @_;
            return $orig_uri;
        } );

    #
    #  Count the links
    #
    my $count_found = $finder->find( \$body );

    if ( $count_found >= $max )
    {
        return "SPAM:Too many URLS";
    }
    else
    {
        return "OK";
    }
}


1;
