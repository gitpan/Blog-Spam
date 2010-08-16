
=head1 NAME

Blog::Spam::Server - A description of the XML-RPC API.

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

Each of these methods will be discussed in order of important, and
additional documentation is available online via http://api.blogspam.net/

=cut


=head1 API

=head2 testComment

The testComment method has the following XML-RPC signature:

=for example begin

   string testComment( struct );

=for example end

(This means the method takes a "struct" as an argument, and returns
a string.  In perl terms the struct is a hash.)

When calling this method you should pass the following parameters to
the method:

   agent   - The user-agent of the submitting browser, if any.
   comment - The body of the comment
   email   - The email address submitted
   ip      - The IP the comment was submitted from.
   name    - The name the user chose, if any.

   options - Discussed later, see "TESTING OPTIONS".

The only mandatory arguments are "comment" and "IP", the rest are
optional but may be useful and it is recommended you pass them if
you can.

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

(This means the method takes a "struct" as an argument, and returns
a string.  In perl terms the struct is a hash.)

=cut

=head2 getPlugins

The getPlugins method has the following XML-RPC signature:

=for example begin

   array getPlugins( );

=for example end

(This means the method takes no arguments, and returns an array.)

=cut

=head2 getStats

The getStats method has the following XML-RPC signature:

=for example begin

   struct getStats( string );

=for example end

(This method returns a struct and takes a string as its only argument.)

=cut

=cut


=head1 TESTING OPTIONS

You may pass the optional "options" string to the server, if you
wish finer control.

This option string should consist of comma-separated tokens.

The permissible values are:

         whitelist=1.2.3.0/24    - Whitelist the given IP / CIDR range.
         blacklist=1.2.3.3/28    - Blacklist the given IP / CIDR range.

         exclude=plugin          - Don't run the plugin with name "plugin".

         mandatory=subject,email - Specify the given field should always be
                                   present.

         max-links=20            - The maximum number of URLs.

         min-size=1024           - Minimum body size.

         max-size=2k             - Maximum body size

         fail                    - Always return "spam"

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


package Blog::Spam::API;



#
#  This "module" exists for documentation purposes only.
#


1;
