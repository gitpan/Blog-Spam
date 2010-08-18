
=head1 NAME

Blog::Spam::Plugin::logger - Log the contents of our messages.

=cut

=head1 ABOUT

This plugin is designed to log the messages which have passed through
our server for training purposes.

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



package Blog::Spam::Plugin::logger;

use strict;
use warnings;

use File::Path;
use Time::HiRes qw(gettimeofday);



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

Expire our log entries older than a month.

=end doc

=cut

sub expire
{
    my ( $self, $parent, $frequency ) = (@_);

    #
    #  Max age of files to keep.
    #
    my $max = $self->{ 'age' } || 30;

    if ( $frequency eq "daily" )
    {
        my $state = $parent->getStateDir();

        foreach my $name (qw! ok spam !)
        {
            my $dir = $state . "/logs/$name/";

            foreach my $entry ( glob( $dir . "/*" ) )
            {

                #
                #  We're invoked once per day, but we only
                # cleanup once a month.
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
}


=begin doc

Log the contents of the message away safely, in a per-result
subdirectory.

=end doc

=cut

sub logMessage
{
    my ( $self, $server, %struct ) = (@_);

    #
    #  Get our state.
    #
    my $state = $server->getStateDir();

    #
    #  The directory we write to.
    #
    my $result = $struct{ 'result' } || "unknown";

    #
    #  Strip trailing reason
    #
    if ( $result =~ /^spam:/i )
    {
        $result = "SPAM";
    }

    $result = lc($result);
    my $dir = $state . "/logs/$result/";
    mkpath( $dir, { verbose => 0 } ) unless ( -d $dir );

    #
    #  Get the time
    #
    my ( $time, $microseconds ) = gettimeofday;
    $time = ( $time =~ m/(\d+)/ )[0];
    $microseconds =~ s/\D//g;

    #
    #  Make sure the filename doesn't have any bogus characters
    # in it.
    #
    my $file = $struct{ 'ip' };
    $file =~ s/[^a-zA-Z0-9]/_/g;
    $file = $dir . $file . ".$time";

    open( LOG, ">", $file );
    foreach my $key ( sort keys %struct )
    {
        if ( $key !~ /^(comment|parent)$/i )
        {
            print LOG "$key: " . $struct{ $key } . "\n";
        }
    }
    print LOG "\n";
    print LOG $struct{ 'comment' } . "\n";
    close(LOG);
}



1;
