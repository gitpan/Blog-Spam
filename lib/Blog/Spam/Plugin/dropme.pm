
package Blog::Spam::Plugin::dropme;


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

This plugin is a simple test one - if a comment mentions the
IP address it is coming from in the subject along with the term "drop-me"
then we'll always regard the submission as spam.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    my $subject = $params{ 'subject' };
    my $ip      = $params{ 'ip' };

    #
    #  Is there an option "fail" ?
    #
    my $options = $params{ 'options' } || "";
    foreach my $option ( split( /,/, $options ) )
    {
        if ( $option =~ /^fail$/i )
        {
            return ("SPAM:Manual Fail");
        }
    }

    #
    #  No subject?  Not going to be marked as spam by this plugin.
    #
    return "OK" if ( !defined($subject) );

    #
    #  If the subject contains "drop-me" *and* the IP then it is spam.
    #
    if ( ( $subject =~ /drop-me/i ) &&
         ( $subject =~ /\Q$ip\E/i ) )
    {
        return "SPAM:Self-dropped";
    }

    #
    #  There was a subject, but it wasn't a test one
    #
    return ("OK");
}


1;
