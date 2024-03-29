
=head1 NAME

Blog::Spam::Plugin::bayesian - Bayesian analysis of submitted comments.

=cut

=head1 ABOUT

This plugin is designed to perform Bayesian analysis upon the content of
submitted comments, with an aim of automatically rejecting comments which
have spammy contents.

=cut

=head1 DETAILS

The plugin relies upon a system-wide installation of the B<spambayes>
tool, which is used to analyse contents and judge comment SPAM/HAM
ratios.

Each site which submits comments against the server will have its own
unique Spambayes database - so our server doesn't store all comments
within a single database, and thus suffer from global poisoning
attacks.

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



package Blog::Spam::Plugin::bayesian;


use strict;
use warnings;


use Fcntl qw(:flock);
use File::Path qw/mkpath/;
use IPC::Open2;


=begin doc

Constructor.  Called when this plugin is instantiated.

=end doc

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    # verbose?
    $self->{ 'verbose' } = $supplied{ 'verbose' } || 0;

    bless( $self, $class );
    return $self;
}


=begin doc

This code users the bayesian classification system "spambayes" to test
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
    my $dbdir = $state . "/bayesian/";
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
    #  Create a lock
    #
    open( FILE, ">", $db . ".lock" );
    flock( FILE, LOCK_EX );

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
    #  Unlock
    #
    flock( FILE, LOCK_UN );
    close(FILE);

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
    my $dbdir = $state . "/bayesian/";
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
    #  If the file doesn't exist we must create it.
    #
    #  TODO:
    #  TODO: Is it an error to train against an empty DB?
    #  TODO:
    #
    if ( !-e $db )
    {
        system("sb_filter.py -n -d $db");
    }

    #
    #  Get the comment body.
    #
    my $body = $params{ 'comment' };
    return 0 if ( !defined($body) || !length($body) );


    #
    #  Map training to appropriate argument
    #
    my $flag = "";
    if ( $train =~ /ok/i )
    {
        $flag = "-g";
    }
    elsif ( $train =~ /spam/i )
    {
        $flag = "-s";
    }

    #
    #  Now train
    #
    open( HANDLE, "|sb_filter.py -d $db $flag -f >/dev/null" );
    print HANDLE $body;
    close HANDLE;

    #
    #  Log to see if we have malicious training.
    #
    my $trained = $state . "/retrained/$train/";
    mkpath( $trained, { verbose => 0 } ) unless ( -d $trained );

    my $tmp = $trained . time . ".$$";
    if ( open( LOG, ">", $tmp ) )
    {
        foreach my $key ( keys %params )
        {
            next if ( $key =~ /^comment$/i );

            print LOG $key . ": " . $params{ $key } . "\n";
        }
        print LOG "\n" . $body . "\n";
        close(LOG);
    }

    #
    #  All done
    #
    return 1;
}


1;
