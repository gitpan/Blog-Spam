
=head1 NAME

Blog::Spam::Plugin::multilinks - Reject opportunistic use of URLs.

=cut

=head1 ABOUT

This plugin is designed to discard comments which have bodies including
links formatted in multiple senses.

A standard comment might have multiple valid URLs included in it,
(but see L<Blog::Spam::Plugin::lotsaurls> for restricting the number
of submitted URLs per comment, but they will all be in one format.

Many SPAM comments contain links in multiple formats such as:

=for example begin

   [url=http://spam.example.org]SPAM[/url],
   <a href="http://spam.example.org/">spam</a>,
   [LINK=http://spam.example.org]SPAM[/link]

=for example end

THis plugin will recognise links in multiple encodings and reject
as SPAM.

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



package Blog::Spam::Plugin::multilinks;


use strict;
use warnings;


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

Many comments exist to promote links to sites, because they don't know
the markup they might try something like:

--
<a href="http://foo.com/">foo.com>/a>
[url=http://foo.com]foo[/url]
--

If we see two types of link attempts then we'll drop the message.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  The post body
    #
    my $body = $params{ 'comment' };

    #
    #  Strip newlines
    #
    $body =~ s/[\r\n]//g;

    #
    #  Look for links:
    #
    my $count = 0;

    $count += 1 if ( $body =~ /<a href="/i );
    $count += 1 if ( $body =~ /\[url=http/i );
    $count += 1 if ( $body =~ /\[link=http/i );

    if ( $count > 1 )
    {
        return "SPAM:Multiple linking methods";
    }

    return "OK";
}


1;
