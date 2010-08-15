
=head1 NAME

Blog::Spam::Plugin::surbl - Discard comments with surbl-listed URLs.

=cut

=head1 ABOUT

This plugin is designed to discard comments which contain URLS which
are listed in the surbl database.

For more details of the surbl service please consult:

=over 8

=item http://www.surbl.org/

=back

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


package Blog::Spam::Plugin::surbl;


use strict;
use warnings;
use URI::Find;
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

Lookup each URL in the body of the comment and test against surbl.org

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);



    #
    #  Get the body content, which will always be present.
    #
    my $body = $params{ 'comment' };

    #
    #  The URLs in the body, if any.
    #
    my %URLS;

    #
    #  Create the helper
    #
    my $finder = URI::Find->new(
        sub {
            my ( $uri, $orig_uri ) = @_;
            $URLS{ $uri } += 1;
            return $orig_uri;
        } );

    #
    #  Populate the hash of URLs with anything in the body.
    #
    my $count_found = $finder->find( \$body );


    #
    #  No URLS?  No further testing then.
    #
    return "OK" if ( $count_found < 1 );

    #
    #  Create the DNS helper
    #
    my $res = new Net::DNS::Resolver;
    $res->tcp_timeout(30);
    $res->udp_timeout(30);

    #
    #  Now test each URL
    #
    foreach my $url ( keys %URLS )
    {

        #
        #  Only HTTP sites.
        #
        if ( $url =~ /http:\/\/([^\/]+)\// )
        {
            $url = $1;

            #
            #  First attempt
            #
            my $packet = $res->query( "$url.multi.surbl.org", "A" );

            if ( ( defined($packet) ) &&
                 ( defined( $packet->answer() ) ) )
            {
                return ("SPAM:$url in surbl.org");
            }

            #
            #  Second attempt
            #
            if ( $url =~ /^([^\.]+)\.(.*)$/ )
            {
                $url = $2;
                $packet = $res->query( "$url.multi.surbl.org", "A" );
                if ( ( defined($packet) ) &&
                     ( defined( $packet->answer() ) ) )
                {
                    return ("SPAM:$url in surbl.org");
                }
            }
        }
    }

    #
    #  Should be clean.
    #
    return ("OK");
}



1;
