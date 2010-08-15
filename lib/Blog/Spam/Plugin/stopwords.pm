

package Blog::Spam::Plugin::stopwords;


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

Block if we find some particular stop-words in the body of the message.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  Get the body content, and split it by the
    # whitespace.
    #
    my $body = lc( $params{ 'comment' } );

    #
    #  If we have a name or subject append that too.
    #
    foreach my $term (qw! subject name !)
    {
        my $extra = $params{ $term };
        if ( defined($extra) && length($extra) )
        {
            $body .= " " . lc($extra) . " ";
        }
    }

    #
    #  The stop-words come from this file.
    #
    my $file = "/etc/blogspam/stopwords";

    #
    #  Get the mtime of the file.
    #
    my ( $dev,  $ino,   $mode,  $nlink, $uid,     $gid, $rdev,
         $size, $atime, $mtime, $ctime, $blksize, $blocks
       ) = stat($file);

    #
    #  If we've not loaded, or the file modification time has
    # changed then reload.
    #
    if ( !$self->{ 'wmtime' } ||
         $self->{ 'wmtime' } < $mtime )
    {
        $self->{ 'words' } = undef;

        if ( open( WORDS, "<", $file ) )
        {
            while (<WORDS>)
            {
                my $word = $_;
                chomp($word);
                next if ( !length($word) );

                $self->{ 'words' }{ $word } = 1;
            }
            close(WORDS);
            $self->{ 'wmtime' } = $mtime;
        }
    }

    #
    #  Split the comment into tokens.  Simplistically.
    #
    foreach my $word ( split( /[ \t\r\n]/, $body ) )
    {

        #
        # remove non letters - we already lower-cased so
        # this just removes leading/trailing punctution,etc.
        #
        $word =~ s/[^a-z]//g;

        next if ( !length($word) );

        if ( $self->{ 'words' }{ $word } )
        {
            return "SPAM:$word";
        }
    }

    return "OK";
}


1;
