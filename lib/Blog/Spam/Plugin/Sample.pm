
=head1 NAME

Blog::Spam::Plugin::Sample - A sample plugin.

=cut

=head1 ABOUT

This is a sample plugin which is designed to demonstrate the functionality
which a plugin may implement to be usefully called by L<Blog::Spam::Server>.

As this is an example plugin it does nothing useful.

=cut

=head1 OVERVIEW

The B<Blog::Spam::Server> receives comment data, via XML::RPC, from
remote clients.

These incoming comments, and associated meta-data, will be examined
by each known plugin in turn.  If a single plugin determines the comment
is SPAM then all further testing is ceased.

This module is an example of one such plugin, and when the server is
installed it will be called in order, along with any others.

=cut


=head1 PLUGIN METHODS

For a plugin to be loaded it must live beneath the L<Blog::Spam::Plugin>
namespace.

There are only a single mandatory method which must be implemented ("new"),
and several optional methods ("classifyComment", "testComment", "expire",
"logMessage").

The B<new> method is required for the plugin loading to succeed.  The
optional methods are invoked at various points in the servers lifecycle,
if they are present.

For example the B<testComment> method will be called to test the state
of an incoming comment "SPAM" or "OK".  The B<expire> method will be
called periodically, if available, to carry out house-keeping tasks.

The B<classifyComment> method is called only when a request to
retrain a comment is received.

Finally the B<logMessage> method will be invoked when the server has
determined an incoming message is either SPAM or OK.

=cut


package Blog::Spam::Plugin::Sample;

use strict;
use warnings;


=head1 METHODS


=head2 new

This method is called when the server is started, and all plugins
are loaded.

This method is mandatory.

A given plugin will only be initialised once when the server is launched,
which permits the plugin to cache state internally if it wishes.

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



=head2 testComment

This method is invoked upon the reception of an incoming comment to
test.

The arguments are a pointer to the server object, and a hash of values
read from the remote client.  (These remote keys include such things
as the IP address of the comment submitter, their name, their email
address and the comment itself.  For a complete list of available
keys please consult L<Blog::Spam::API>.)

=over 8

=item ip

The IP address of the comment submitter.

=item comment

The text of the comment received.

=back

There are two valid return values "OK", which means the comment should
be allowed to continue, and "SPAM" which means the plugin has determined
the comment to be SPAM.

Optionally the SPAM result may be qualified with a human-readable
explanation:

=for example begin

   return "SPAM:This comment defames me";

=for example end

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    return "OK";
}



=head2 expire

This method is B<optional>.

Some plugins maintain state which must be expired.   If this method is
implemented it will be invoked upon a regular frequency, with the intention
that a plugin may expire its state at that time.

There are two arguments, the first is a handle to the L<Blog::Spam::Server>
object, and the second is a frequency label:

=over 8

=item hourly

This method has been called once per hour.

=item daily

This method has been called once per day.

=item weekly

This method has been called once per week.

=back

=cut

sub expire
{
    my ( $self, $parent, $duration ) = (@_);

    if ( $duration eq "hourly" )
    {

        # do stuff.
    }
    elsif ( $duration eq "daily" )
    {

        # do stuff.
    }
    elsif ( $duration eq "weekly" )
    {

        # do stuff.
    }
    else
    {
        print "UNKOWN DURATION: $duration\n";
    }
}



=head2 classifyComment

This method is B<optional>.

This method is called whenever a comment is submitted for retraining,
because the server was judged to return the wrong result.

The parameters received are identical to those of the B<testComment>
method - with the addition of a new key "train":

=over 8

=item spam

The comment was returned by the server as being OK but it should have
been marked as SPAM.

=item ok

The comment was previously judged as SPAM, but this was an error and the
comment was actually both welcome and valid.


=back

=cut

sub classifyComment
{

    # NOP
}



=head2 logMessage

This method is B<optional>.

This method will be called when the server wishes to log a result
of a connection.  ie. It will be called once for each comment
at the end of the B<testComment> function.

The message structure, as submitted to testing, will be supplied as
a hash, and this hash will contain a pair of additional keys:

=over 8

=item result

The result of the test "OK" or "SPAM:[reason]".

=item blocker

If the result of the test was not "OK" then the name of the plugin
which caused the rejection will be saved in this key.

=back

=cut

sub logMessage
{
    my ( $self, $parent, %message ) = (@_);

    # NOP
}




1;


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
