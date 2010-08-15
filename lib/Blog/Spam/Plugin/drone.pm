package Blog::Spam::Plugin::drone;


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

Test whether the IP address submitting the comment is listed
in the drone blacklist:

     http://www.dronebl.org/

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
    # We cannot lookup IPv6 addresses.
    #
    return "OK" if ( $ip =~ /:/ );

    #
    #  Malformed IP?
    #
    return "SPAM" unless ( $ip =~ /^([0-9\.]+)$/ );

    #
    #  Reverse for querying.
    #
    my $reversed_ip = join( ".", reverse( split( /\./, $ip ) ) );


    my $res = new Net::DNS::Resolver;
    $res->tcp_timeout(30);
    $res->udp_timeout(30);

    my $packet = $res->query( "$reversed_ip.dnsbl.dronebl.org.", "A" );
    if ( ( defined($packet) ) &&
         ( defined( $packet->answer() ) ) )
    {
        return ("SPAM:dronebl");
    }

    return ("OK");
}



1;
