

package Blog::Spam::Plugin::lotsaurls;


use URI::Find;



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

Block if we find more than a given number of links in message.

The default is 10 links, but this may be changed by the caller.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  User might have set "max-links".
    #
    my $max = 10;

    #
    #  See if the max-links flag was set.
    #
    my $options = $params{ 'options' } || "";
    foreach my $option ( split( /,/, $options ) )
    {
        if ( $option =~ /max-links=([0-9]+)/i )
        {
            $max = $1;
        }
    }

    #
    #  Get the body content.
    #
    my $body = $params{ 'comment' };

    #
    #  Create the helper
    #
    my $finder = URI::Find->new(
        sub {
            my ( $uri, $orig_uri ) = @_;
            return $orig_uri;
        } );

    #
    #  Count the links
    #
    my $count_found = $finder->find( \$body );

    if ( $count_found >= $max )
    {
        return "SPAM:Too many URLS";
    }
    else
    {
        return "OK";
    }
}


1;
