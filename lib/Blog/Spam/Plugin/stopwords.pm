
=head1 NAME

Blog::Spam::Plugin::stopwords - Reject comments which contain known-bad words.

=cut

=head1 ABOUT

This plugin is designed to discard comments which contain terms listed
in a local blacklist.

=cut

=head1 DETAILS

The blacklist must be created and updated by the maintainer of the
local system, and will be found at B</etc/blogspam/stoplist>.

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




package Blog::Spam::Plugin::stopwords;


use strict;
use warnings;


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

    # the file of stop-words
    $self->{ 'stopwords' } = "/etc/blogspam/stopwords";

    bless( $self, $class );
    return $self;
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
    my $file = $self->{ 'stopwords' } || undef;

    #
    #  No file?  Then return.
    #
    return "OK" if ( !defined($file) || !-e $file );


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

            $self->{ 'words' } = undef;
            $self->{ 'verbose' } &&
              print "re-reading stopwords from $file\n";

            while ( my $line = <WORDS> )
            {

                # skip blank lines
                next unless ( $line && length($line) );

                # Skip lines beginning with comments
                next if ( $line =~ /^([ \t]*)\#/ );

                # strip spaces
                $line =~ s/^\s+|\s+$//g;

                # strip newline
                chomp($line);

                # empty now?
                next unless length($line);

                $self->{ 'words' }{ lc $line } = 1;

                $self->{ 'verbose' } && print "Blacklisting term: $line\n";

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
            return "SPAM:stopwords:$word";
        }
    }

    return "OK";
}


1;
