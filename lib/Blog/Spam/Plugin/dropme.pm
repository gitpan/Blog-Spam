
=head1 NAME

Blog::Spam::Plugin::dropme - A plugin for self-dropping comments.

=cut

=head1 ABOUT

This plugin is designed to allow a remote user to verify the
L<Blog::Spam::Server> is working correctly, by allowing them to
submit a comment which is known to fail.

In order to submit a comment to this plugin you must include two
things:

=over 8

=item dropme
The subject of your message must contain the literal term "drop-me".

=item IP
The subject of your message must contain the IP address from which you're
submitting your comment.

=back

Assuming the owner of the IP address 1.2.3.4 were to wish to test
their server they would thus submit a comment like this:

=for example begin

    Subject: drop-me 1.2.3.4 please?
    Comment: Any comment here.

=for example end

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


package Blog::Spam::Plugin::dropme;


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

This plugin is a simple test one - if a comment mentions the
IP address it is coming from in the subject along with the term "drop-me"
then we'll always regard the submission as spam.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    my $subject = $params{ 'subject' } || undef;
    my $ip      = $params{ 'ip' }      || undef;

    #
    #  No subject?  No IP?  Then we ignore.
    #
    return "OK" if ( !defined($subject) || !defined($ip) );

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
