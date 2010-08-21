
=head1 NAME

Blog::Spam::API - A description of Blog-Spam XML-RPC API.

=cut

=head1 ABOUT

This document discusses the API which is presented by the
L<Blog::Spam::Server>.  This API is exposed via XML-RPC
such that it may be called by remote locations.

=cut

=head1 XML-RPC METHODS

The L<Blog::Spam::Server> exposes several methods to clients from
remote locations.  The following methods are documented:

=over 8

=item testComment

This is the method which is used to test a submitted comment from
a blog or server.

=item getPlugins

This returns the names of the internal plugins we use - it is used
such that a remote machine may selectively disable some of them.

=item getStats

Return the statistics for SPAM detection for a given domain.

=item classifyComment

This allows a limited amount of re-training for a submitted comment.

=back

Each of these methods will be discussed in order of importance, and
additional documentation is available online via http://api.blogspam.net/

=cut


=head1 API

=head2 testComment

The testComment method has the following XML-RPC signature:

=for example begin

   string testComment( struct );

=for example end

This means the method takes a "struct" as an argument, and returns
a string.  In Perl terms the struct is a hash.

When calling this method the hash of options may contain the following
keys:

=over 8

=item agent
The user-agent of the submitting browser, if any.

=item comment
The body of the comment

=item email
The email address submitted along with the comment.

=item fail
If this key is present your comment will always be returned as SPAM; useful
for testing if nothing else.  This handling is implemented by L<Blog::Spam::Plugin::fail>.

=item ip
The IP address the comment was submitted from.

=item name
The name the user chose, if any.

=item subject
The subject the user chose, if any.

=item site
A HTTP link to I<your> site.  (Use $ENV{'SERVER_NAME'} if possible.)

=item options
Customization options for the testing process, discussed in the section L<TESTING OPTIONS|Blog::Spam::API/"TESTING OPTIONS">.

=back

The only mandatory arguments are "comment" and "ip", the rest are
optional but may be useful and it is recommended you pass them if
you can.  (Each key should be lower-cased.)

The return value from this method will either be "OK", or "SPAM".

Optionally a reason may be returned in the case a comment is judged as
SPAM, for example:

=for example begin

    SPAM:I don't like comments submitted before 9AM.

=for example end

=cut

=head2 classifyComment


The classifyComment method has the following XML-RPC signature:

=for example begin

   string classifyComment( struct );

=for example end

This means the method takes a "struct" as an argument, and returns
a string.  In Perl terms the struct is a hash.

The keys to this method are identical to those in the testComment
method - the only difference is that the "train" key is mandatory:

=over 8

=item train
Either "ok" or "spam" to train the comment appopriately.

=back

If the comment was permitted to pass, but should have been rejected
as SPAM set the train parameter to "spam".

=cut

=head2 getPlugins

The getPlugins method has the following XML-RPC signature:

=for example begin

   array getPlugins( );

=for example end

This means the method takes no arguments, and returns an array.

This method does nothing more than return the names of each of the plugins
which the server has loaded.

These plugins are modules beneath the Blog::Spam::Plugin:: namespace,
and L<the sample plugin|Blog::Spam::Plugin::Sample> provides a good
example.

=cut

=head2 getStats

The getStats method has the following XML-RPC signature:

=for example begin

   struct getStats( string );

=for example end

This method returns a struct and takes a string as its only argument.

This method returns a hash containing two keys "OK" and "SPAM".  These
keys will have statistics for the given domain - or global statistics
if the method is passed a zero-length string.

B<Note:> The string here should match that given as the "site" key to the method
testComment - as that is how sites are identified.

=cut


=head1 TESTING OPTIONS

You may pass the optional "options" key to the hash of arguments provided
to the testComment method.  This is useful to provide you with the ability
to tune the behaviour of tests which are made.

This option string should consist of comma-separated tokens.

The permissible values are:

         whitelist=1.2.3.0/24    - Whitelist the given IP / CIDR range.
         blacklist=1.2.3.3/28    - Blacklist the given IP / CIDR range.

         exclude=plugin          - Don't run the plugin with name "plugin".  (You may find a list of plugins via the getPlugins() method.)

         mandatory=subject,email - Specify the given field should always be present.

         max-links=20            - The maximum number of URLs, as used by L<Blog::Spam::Plugin::loadsalinks>

         min-size=1024           - Minimum body size, as used by L<Blog::Spam::Plugin::size>.

         min-words=4            - Minimum word count, as used by L<Blog::Spam::Plugin::wordcount>.

         max-size=2k             - Maximum body size,  as used by L<Blog::Spam::Plugin::size>.

         fail                    - Always return "SPAM".

These options may be repeated, for example the following is a valid
value for the "options" setting:

=for example begin

   mandatory=subject,mandatory=name,whitelist=1.2.3.4,exclude=surbl

=for example end

That example will:

1.  Make the "subject" field mandatory.

2.  Makes the "name" field mandatory.

3.  Whitelists any comments subitted from the IP 1.2.3.4

4.  Causes the server to not run the surbl test.

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


package Blog::Spam::API;



#
#  This "module" exists for documentation purposes only.
#


1;
