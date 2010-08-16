
=head1 NAME

Blog::Spam::Plugin::emailtests - Reject email addresses which are bogus.

=cut

=head1 ABOUT

This plugin is designed to discard comments if they have been submitted
with a bogus Email address.

The tests are pretty simple; just making sure that the submitted domain
is not an example.{com org net} one, and that the mail address has an
"@" symbol in it.

In the future more thorough tests might be added, but currently email addresses
are rarely configured to be mandatory in comment submissions so further
work isn't a real useful way to spend time.

=cut

=head1 LICENSE

This code is licensed under the terms of the GNU General Public
License, version 2.  See included file GPL-2 for details.

=cut

=head1 AUTHOR

Steve
--
http://www.steve.org.uk/

=cut

=head1 LICENSE

Copyright (c) 2008-2010 by Steve Kemp.  All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut


package Blog::Spam::Plugin::emailtests;


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

Perform some simple tests on the submitted email address.

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  Get the mail address
    #
    my $mail = $params{ 'email' };

    #
    #  Must be OK if there is non submitted.
    #
    return "OK" unless ( defined($mail) );

    #
    #  @example.{com net org} is a spam.
    #
    return "SPAM:example.$1 domain" if ( $mail =~ /example.(com|org|net)$/i );

    #
    #  Null envelope is spam
    #
    return "SPAM:Null envelope" if ( $mail =~ /^<>$/ );

    #
    #  No "@" is spam
    #
    return "SPAM:No \@" unless ( $mail =~ /.\@./ );

    return "OK";
}


1;
