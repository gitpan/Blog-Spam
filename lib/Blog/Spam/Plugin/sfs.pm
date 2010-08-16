

package Blog::Spam::Plugin::sfs;

use strict;
use warnings;

use File::Path;
use LWP::Simple;


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


=begin doc

Return the name of this plugin.

=end doc

=cut

sub name
{
    my ($self) = (@_);
    return ( $self->{ 'name' } );
}




=begin doc

Test whether the IP address submitting the comment is listed
in the StopForumSpam.com database.

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
    #  Get the state directory which we'll use as a cache.
    #
    my $state = $params{ 'parent' }->getStateDir();
    my $cdir  = $state . "/cache/sfs/";

    #
    #  Is the result cached?
    #
    my $safe = $ip;
    $safe =~ s/[:\.]/-/g;
    if ( -e "$cdir/$safe" )
    {
        return ("SPAM:Listed in stopforumspam.com");
    }


    #
    #  The URL we fetch
    #
    my $link = "http://www.stopforumspam.com/api?ip=" . $ip;

    #
    #  Get it
    #
    my $content = get($link);

    #
    #  If it worked see if we're listed
    #
    if ( defined($content) )
    {

        # strip newlines
        $content =~ s/[\r\n]//g;

        if ( $content =~ /<appears>yes<\/appears>/i )
        {

            #
            #  Cache the result
            #
            if ( !-d $cdir )
            {
                mkpath( $cdir, { verbose => 0 } );
            }
            open( FILE, ">", "$cdir/$safe" ) or
              die "Failed to open $cdir/$safe - $!";
            print FILE "\n";
            close(FILE);

            #
            #  Return spam result
            #
            return ("SPAM:Listed in stopforumspam.com");
        }
    }
    else
    {
        print "\tFailed to fetch: $link\n";
    }

    return ("OK");
}



=begin doc

Expire our cached SFS entries once a week.

=end doc

=cut

sub expire
{
    my ( $self, $parent, $frequency ) = (@_);

    if ( $frequency eq "weekly" )
    {
        $self->{ 'verbose' } && print "Cleaning Cache\n";

        my $state = $parent->getStateDir();
        my $cdir  = $state . "/cache/sfs/";

        foreach my $entry ( glob( $cdir . "/*" ) )
        {

            #
            #  We're invoked once per week, but we
            # only want to remove files which are themselves
            # older than a week.
            #
            if ( -M $entry > 7 )
            {
                $self->{ 'verbose' } && print "\tRemoving: $entry\n";
                unlink($entry);
            }
        }
    }
}

1;
