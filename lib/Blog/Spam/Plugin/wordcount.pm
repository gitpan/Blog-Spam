
=head1 NAME

Blog::Spam::Plugin::wordcount - Discard comments with too few words.

=cut

=head1 ABOUT

This plugin is designed to discard comments which have either too
few or too many words.

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


package Blog::Spam::Plugin::wordcount;


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


=begin doc

Return the name of our plugin, as saved in the constructor.

=end doc

=cut

sub name
{
    my ($self) = (@_);
    return ( $self->{ 'name' } );
}




=begin doc

Block posts that are only a few words long.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  The post body + options
    #
    my $body = $params{ 'comment' };
    my $options = $params{ 'options' } || "";

    my $min = 4;

    #
    #  Split the options and look for a min-words option
    #
    foreach my $option ( split( /,/, $options ) )
    {
        if ( $option =~ /min-words=([0-9]+)/i )
        {
            $min = $1;
        }
    }

    #
    #  Flatten
    #
    $body =~ s/[\r\n]/ /g;

    #
    #  Remove leading/trailing whitespace.
    #
    $body =~ s/^\s+|\s+$//g;

    #
    #  Convert tabs to spaces
    #
    $body =~ s/\t/ /g;

    #
    #  Flatten multiple spaces
    #
    $body =~ s/ +/ /g;

    #
    #  Now split
    #
    my @words = split( / /, $body );
    my $count = scalar(@words);

    #
    #  Arbitrary threshold
    #
    if ( $count >= $min )
    {
        return "OK";
    }
    else
    {
        return "SPAM:Too few words";
    }
}


1;
