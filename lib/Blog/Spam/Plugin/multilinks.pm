

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
