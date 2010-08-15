
package Blog::Spam::Plugin::bayasian;


use strict;
use warnings;


use File::Path qw/mkpath/;
use IPC::Open2;


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

This code users the bayasian classification system "spambayes" to test
incoming comments.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  If we don't have the sb_filter program installed
    # then we can't test anything...
    #
    return "OK" if ( !-x "/usr/bin/sb_filter.py" );


    #
    #  Get access to our state directory.
    #
    my $state = $params{ 'parent' }->getStateDir();
    my $dbdir = $state . "/bayasian/";
    mkpath( $dbdir, { verbose => 0 } ) unless ( -d $dbdir );


    #
    #  The Spam database is derived from the site.  Remove malicious
    # characters
    #
    my $site = $params{ 'site' } || "unknown.example.org";
    $site =~ s/[^a-z0-9]/_/g;

    #
    #  Now we have the file.
    #
    my $db = $dbdir . "/" . $site . ".db";


    #
    #  If the database doesn't exist we must create it.
    #
    if ( !-e $db )
    {
        system("sb_filter.py -n -d $db");
    }

    #
    #  The comment
    #
    my $comment = $params{ 'comment' } || "";

    #
    #  Open the command for reading/writing.
    #
    my ( $chld_out, $chld_in );
    my $pid = open2( $chld_out, $chld_in, "sb_filter.py -d $db" );

    #
    #  Print the comment body for testing
    #
    print $chld_in $comment;
    close($chld_in);


    #
    #  Now read the result from the output.
    #
    my $result = "";

    while ( my $line = <$chld_out> )
    {
        if ( $line =~ /X-Spambayes-Classification: (.*)/ )
        {
            $result = $1;
        }
    }
    close($chld_out);


    #
    #  Wait for the process to finish
    #
    waitpid $pid, 0;

    #
    #  We'll not count an "unsure" result, so we're either
    # looking for a header of "ham" or "spam".
    #
    #  If it decides the comment was spam we'll agree.
    #
    if ( ($result) && ( $result =~ /spam/i ) )
    {
        return ("SPAM:SpamBayes");
    }

    #
    #  Must be either unsure, or ok.
    #
    return "OK";
}



=begin doc

  Train a comment as ham/spam

=end doc

=cut

sub classifyComment
{
    my ( $self, %params ) = (@_);

    #
    #  Make sure we know how we're training
    #
    my $train = $params{ 'train' } || "";
    if ( $train !~ /^(spam|ok)$/i )
    {
        return 0;
    }




    #
    #  Get access to our state directory.
    #
    my $state = $params{ 'parent' }->getStateDir();
    my $dbdir = $state . "/bayasian/";
    mkpath( $dbdir, { verbose => 0 } ) unless ( -d $dbdir );


    #
    #  The Spam database is derived from the site.  Remove malicious
    # characters
    #
    my $site = $params{ 'site' } || "unknown.example.org";
    $site =~ s/[^a-z0-9]/_/g;

    #
    #  Now we have the file.
    #
    my $db = $dbdir . "/" . $site . ".db";

    #
    #  If the file doesn't exist we cannot train.
    #
    return unless ( -e $db );

    #
    #  Get the comment body.
    #
    my $body = $params{ 'comment' };
    return 0 if ( !defined($body) || !length($body) );


    #
    #  Create the spambayes database if it is missing
    #
    if ( !-e $db )
    {
        system( "sb_filter.py", "-n", "-d", $db );
    }

    #
    #  Construct a logfile to record this against.
    #
    my $tmp = "/var/log/blogspam/trained-as-$train.$$." . localtime;

    #
    #  Map training to appropriate argument
    #
    if ( $train =~ /ok/i )
    {
        $train = "-g";
    }
    elsif ( $train =~ /spam/i )
    {
        $train = "-s";
    }

    #
    #  Now train
    #
    open( HANDLE, "|sb_filter.py -d $db $train -f >/dev/null" );
    print HANDLE $body;
    close HANDLE;

    #
    #  Log to see if we have malicious training.
    #
    if ( open( LOG, ">", $tmp ) )
    {
        print LOG $body;
        close(LOG);
    }

    #
    #  All done
    #
    return 1;
}


1;
