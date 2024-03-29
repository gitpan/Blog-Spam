
=head1 NAME

Blog::Spam::Plugin::size - Size-Test submitted comments.

=cut

=head1 ABOUT

This plugin is designed to discard comments which are too small, or
too large.

By default this plugin will do nothing - it must be explicitly enabled
by the site which is submitting the comment for testing, via the use
of optional parameters submitted to the L<Blog::Spam::Server>.

The options are discussed as part of the L<Blog::Spam::API>, in the
section L<TESTING OPTIONS|Blog::Spam::API/"TESTING OPTIONS">.

If supplied this plugin will test the submitted comment against the
appropriate values:

=over 8

=item min-size

The minimum acceptible word-count for a valid comment.

=item max-size

The maximum acceptible word-count for a valid comment.

=back

If the submitted comment is either too small, or too large, then
it will be rejected and marked as SPAM.

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

package Blog::Spam::Plugin::size;


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

Is the given post too large, or too small?

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  The post body + options
    #
    my $body    = $params{ 'comment' };
    my $options = $params{ 'options' };

    #
    #  No size set?
    #
    return "OK" if ( !defined($options) || !length($options) );

    #
    #  Size of the body
    #
    my $size = length($body);

    #
    #  Split
    #
    foreach my $option ( split( /,/, $options ) )
    {
        if ( $option =~ /min-size=([0-9]+k?)/i )
        {
            my $min = $1;

            # convert from "2k" => "2048".
            if ( $min =~ /^([0-9]+)k/i )
            {
                $min = $1;
                $min *= 1024;
            }

            if ( $size < $min )
            {
                return "SPAM:Too small";
            }
        }
        if ( $option =~ /max-size=([0-9]+k?)/i )
        {
            my $max = $1;

            # convert from "2k" => "2048".
            if ( $max =~ /^([0-9]+)k/i )
            {
                $max = $1;
                $max *= 1024;
            }
            if ( $size >= $max )
            {
                return "SPAM:Too large";
            }
        }
    }

    return "OK";
}


1;
