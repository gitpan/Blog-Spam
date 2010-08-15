
package Blog::Spam::Plugin::size;


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
