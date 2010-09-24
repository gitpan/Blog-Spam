
=head1 NAME

Blog::Spam::API - A description of Blog-Spam API.

=cut

=head1 ABOUT

This document discusses the API which is presented by the
L<Blog::Spam::Server> to remote clients via XML::RPC.

The server itself has two APIs:

=over 8

=item The XML::RPC API

This is the API which is presented to remote callers.

=item The Plugin API

The API that the server itself uses, and which plugins must
conform to, in order to be both used and useful.  The internal
plugin API is documented and demonstrated in the L<the sample plugin|Blog::Spam::Plugin::Sample>.

=back

=cut

=head1 The XML-RPC API

The L<Blog::Spam::Server> exposes several methods to clients via
XML::RPC.

The following methods L<are documented|http://api.blogspam.net/> as being available:

=over 8

=item testComment

This is the method which is used to test a submitted comment from
a blog or server.  Given a structure containing information about
a single comment submission it will return a result of either
"spam" or "ok".

=item getPlugins

This returns the names of the internal plugins we use - it is used
such that a remote machine may selectively disable some of them.

=item getStats

Return the number of spam vs. non-spam comments which have been
submitted by the current site.

=item classifyComment

If a previous "testComment" invocation returned the wrong result then
this method allows it to be reset.

=back

Each of these methods will be discussed in order of importance, and
L<additional documentation is available online|http://api.blogspam.net/>.

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

The body of the comment the remote user submitted.

=item email

The email address submitted along with the comment.

=item fail

If this key is present your comment will always be returned as SPAM; useful
for testing if nothing else.  This handling is implemented by the plugin
L<Blog::Spam::Plugin::fail>.

=item ip

The IP address the comment was submitted from.

=item name

The name of the comment submitter, if any.

=item subject

The subject the comment submitter chose, if any.

=item site

A HTTP link to I<your> site which received the comment submission.
In most cases using $ENV{'SERVER_NAME'} is the correct thing to do.

=item options

Customization options for the testing process, discussed in the section L<TESTING OPTIONS|Blog::Spam::API/"TESTING OPTIONS">.

=back

The only mandatory structure members are "comment" and "ip", the rest are
optional but recommended.

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
method - the only difference is that an additional key, "train",
is recognised and it is mandatory:

=over 8

=item train
Either "ok" or "spam" to train the comment appopriately.

=back

If the comment was permitted to pass, but should have been rejected
as SPAM set the train parameter to "spam", if it was rejected and
should not have been set the train parameter to "ok".

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
and their names are the module names minus the prefix.

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

When a comment is submitted for testing, via the testComment XML::RPC
method it may have an "options" key in the structure submitted.

The options string allows the various tests to be tweaked or changed
from their default behaviours.

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

3.  Whitelists any comment(s) submitted from the IP 1.2.3.4

4.  Causes the server to not run the L<surbl plugin|Blog::Spam::Plugin::surbl>.

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
