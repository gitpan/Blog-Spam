

package Blog::Spam::Plugin::strong;


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

Does this comment start with "<strong>foo</strong>" ?

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
    #  Split into lines
    #
    my @lines = split( /[\r\n]/, $body );

    #
    #  Ouptut
    #
    my $found = 0;
    foreach my $line (@lines)
    {

        # if we found the first line of content then we're done.
        return "OK" if ($found);

        if ( length($line) > 1 )
        {
            $found += 1;
            if ( $line =~ /<strong>(.*)<\/strong>/i )
            {
                return "SPAM:Strong";
            }
        }
    }

    return "OK";
}


1;
