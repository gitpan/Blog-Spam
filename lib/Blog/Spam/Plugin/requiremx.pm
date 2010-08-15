

package Blog::Spam::Plugin::requiremx;


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

If we've got an email address make sure that the domain :

   a.  Has an MX record.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  Email isn't mandatory
    #
    my $mail = $params{ 'email' };

    #
    #  No mail?  Can't test.
    #
    return "OK" if ( !defined($mail) );


    #
    #  No "@" is spam
    #
    return "SPAM:No \@" unless ( $mail =~ /.\@./ );

    #
    #  Split address
    #
    my ( $user, $domain ) = split( /@/, $mail );

    #
    #  Create lookup object.
    #
    my $res = new Net::DNS::Resolver;
    $res->tcp_timeout(30);
    $res->udp_timeout(30);

    #
    #  Look for MX record for the domain
    #
    my $packet = $res->query( $domain, "MX" );
    if ( !( defined($packet) ) ||
         !( defined( $packet->answer() ) ) )
    {
        return ("SPAM:No MX");
    }

    return ("OK");
}



1;
