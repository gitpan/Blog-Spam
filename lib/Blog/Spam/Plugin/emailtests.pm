

package Blog::Spam::Plugin::emailtests;


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

Perform some simple tests on the submitted email address.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  Get the mail address
    #
    my $mail = $params{ 'email' };

    #
    #  Must be OK if there is non submitted.
    #
    return "OK" unless ( defined($mail) );

    #
    #  @example.{com net org} is a spam.
    #
    return "SPAM:example.$1 domain" if ( $mail =~ /example.(com|org|net)$/i );

    #
    #  Null envelope is spam
    #
    return "SPAM:Null envelope" if ( $mail =~ /^<>$/ );

    #
    #  No "@" is spam
    #
    return "SPAM:No \@" unless ( $mail =~ /.\@./ );

    return "OK";
}


1;
