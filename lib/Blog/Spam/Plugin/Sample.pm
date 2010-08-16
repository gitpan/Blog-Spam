
=head1 NAME

Blog::Spam::Plugin::Sample - A sample plugin.

=cut

=head1 ABOUT

This is a sample plugin which is designed to demonstrate the functionality
which a plugin may implement to be usefully called by L<Blog::Spam::Server>.

=cut

=head1 OVERVIEW

The B<Blog::Spam::Server> receives comment data, via XML::RPC, from
remote clients.

These incoming comments, and associated meta-data, will be examined
by each known plugin in turn.  If a single plugin determines the comment
is SPAM then all further testing is ceased.

=cut


=head1 PLUGIN METHODS

For a plugin to be loaded it must live beneath the L<Blog::Spam::Plugin>
namespace.

There are two mandatory methods ("new" + "name"), and two optional methods
("testComment", "expire").

=cut


package Blog::Spam::Plugin::Sample;

use strict;
use warnings;


=head1 METHODS


=head2 new

This method is called when the server is started, and all plugins
are loaded.

This method is B<mandatory>.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    # plugin name
    $self->{ 'name' } = $proto;

    # verbose?
    $self->{ 'verbose' } = $supplied{ 'verbose' } || 0;

    bless( $self, $class );
    return $self;
}



=head2 name

Return the name of this plugin.

This method is B<mandatory>.

=cut

sub name
{
    my ($self) = (@_);
    return ( $self->{ 'name' } );
}



=head2 testComment

This method is invoked upon the reception of an incoming comment to
test.  It is given a hash of options, with notable keys including:

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

Some plugins maintain state which must be expired.

If this method is implemented it will be invoked upon a regular
frequency.

There are two arguments, the first is a handle to the L<Blog::Sample::Server>
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
