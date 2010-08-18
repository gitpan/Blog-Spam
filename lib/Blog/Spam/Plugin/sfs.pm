
=head1 NAME

Blog::Spam::Plugin::sfs - Lookup comment submissions in stopforumspam.com

=cut

=head1 ABOUT

This plugin is designed to test the submitters of comments against the
stopforumspam.com service.

An IP which is listed in the service will be refused the ability to
submit comments - and this result will be cached for a week.

=cut

=head1 AUTHOR

=over 4

=item Steve Kemp

http://www.steve.org.uk/

=back

=cut

=head1 LICENSE

Copyright (c) 2008-2010 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut



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
        return ("SPAM:Cached from stopforumspam.com");
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

Expire any cached SFS entries older than 7 days.

=end doc

=cut

sub expire
{
    my ( $self, $parent, $frequency ) = (@_);

    #
    #  Max age of files to keep.
    #
    my $max = $self->{ 'age' } || 7;

    #
    #  We're only interested in being called daily.
    #
    if ( $frequency eq "daily" )
    {
        my $state = $parent->getStateDir();
        my $cdir  = $state . "/cache/sfs/";

        foreach my $entry ( glob( $cdir . "/*" ) )
        {

            #
            #  We're invoked once per day, but we only care about files
            # older than 7 days.
            #
            my $age = int( -M $entry );

            if ( $age >= $max )
            {
                $self->{ 'verbose' } && print "\tRemoving: $entry\n";
                unlink($entry);
            }
            else
            {
                $self->{ 'verbose' } &&
                  print "\tLeaving $entry - $age days old <= $max\n";
            }
        }
    }
}

1;
