

package Blog::Spam::Plugin::rdns;


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

sub name
{
    my ($self) = (@_);
    return ( $self->{ 'name' } );
}



=begin doc

Test whether the IP address has a reverse DNS entry.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  IP is mandatory - we will always have it.
    #
    my $ip = $params{ 'ip' };


    #
    #  Reverse, so we can query.
    #
    my $rip = join( '.', reverse split( /\./, $ip ) ) . ".in-addr.arpa";


    my $res = Net::DNS::Resolver->new;
    my $query = $res->query( $rip, 'PTR' );
    if ($query)
    {

        # If the query was valid then get the answer.
        my $r = ( $query->answer )[0];

        if ( defined( $r->rdatastr ) )
        {
            return "OK";
        }
        else
        {
            return "SPAM:No reverse DNS entry for $ip";
        }
    }
    else
    {
        return "SPAM:No reverse DNS entry for $ip";
    }
}

1;
