
package Blog::Spam::Plugin::bogusip;


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

Is this an internal IP?

That might be fine for local use, but in the real world such IPs
are not going to be seen and can be safely marked as spam.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  Get the IP - this is mandatory, but it might be ipv6.
    #
    my $ip = $params{ 'ip' };

    #
    #  Skip a couple of ranges.
    #
    return "SPAM:Internal IP"
      if ( ( $ip =~ /^10\.0/ ) ||
           ( $ip =~ /^192\.168\./ ) );

    return "OK";
}


1;
