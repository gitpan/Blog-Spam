
=head1 NAME

Blog::Spam::Server - An RPC server which detects comment spam.

=cut

=head1 ABOUT

This program implements a plugin-based XML-RPC server which may be
queried from almost all languages.

The intention is that clients will query this server to detect whether
their comment submissions are spam or genuine, using the API we present
over the network via XML::RPC - that API is documented in L<Blog::Spam::API>.

The actual testing of submitted comments is handled by a series of
plugins, each living beneath the 'Blog::Spam::Plugin::' namespace.

For a description of the plugin methods please consult the
L<sample plugin|Blog::Spam::Plugin::Sample>.

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


package Blog::Spam::Server;


use vars qw($VERSION);
our $VERSION = "0.9.1";

#
#  The modules we require
#
use Sys::Syslog qw(:standard :macros);
use RPC::XML::Server;
use File::Path;
use File::Basename;
use File::Copy;


#
#  Control the loading of our plugins
#
use Module::Pluggable
  search_path => ['Blog::Spam::Plugin'],
  require     => 1,
  instantiate => 'new';


#
#  Standard pragmas.
#
use strict;
use warnings;




=begin doc

Create a new instance of this object.

=end doc

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    #
    #  Allow user supplied values to override our defaults
    #
    foreach my $key ( keys %supplied )
    {
        $self->{ lc $key } = $supplied{ $key };
    }

    #
    #  Open syslog
    #
    my $name = $0;
    $name = $2 if ( $name =~ /(.*)\/(.*)$/ );
    openlog( $name, "pid", "local0" );

    bless( $self, $class );

    return $self;

}



=begin doc

Create our child XML-RPC server.

=end doc

=cut

sub createServer
{
    my ( $self, %params ) = (@_);

    my %options = ();
    $options{ 'port' } = $params{ 'port' } || 8888;
    $options{ 'host' } = $params{ 'host' } if ( $params{ 'host' } );

    $self->{ 'verbose' } && print "Creating RPC server.\n";

    #
    # Create the server object.
    #
    $self->{ 'daemon' } = RPC::XML::Server->new(%options);

    #
    # Did we fail to bind?
    #
    if ( ( !$self->{ 'daemon' } ) ||
         ( !$self->{ 'daemon' }->can("add_method") ) )
    {
        print "ERROR: Failed to bind!\n";
        return undef;
    }

    $self->{ 'verbose' } && print "Adding RPC methods.\n";

    #
    # Add our 'testComment' method.
    #
    $self->{ 'daemon' }->add_method( {
          name      => 'testComment',
          signature => ['string struct'],
          code      => sub {$self->testComment(@_)}
        } );

    #
    # Add our (re)train comment method
    #
    $self->{ 'daemon' }->add_method( {
          name      => 'classifyComment',
          signature => ['string struct'],
          code      => sub {$self->classifyComment(@_)}
        } );

    #
    # Add our 'getStats' method.
    #
    $self->{ 'daemon' }->add_method( {
          name      => 'getStats',
          signature => ['struct string'],
          code      => sub {$self->getStats(@_)}
        } );

    #
    # Add our 'getPlugins' method.
    #
    $self->{ 'daemon' }->add_method( {
          name      => 'getPlugins',
          signature => ['array'],
          code      => sub {$self->getPlugins(@_)}
        } );

}



=begin doc

Load the plugins we might have present.

The return value to this method will be the number of plugins which
were successfully loaded.

=end doc

=cut

sub loadPlugins
{
    my ($self) = (@_);

    $self->{ 'verbose' } && print "Loading plugins.\n";

    my $count = 0;

    #
    #  Load our plugins, passing allong the verbosity
    # value.
    #
    my @plugins = $self->plugins( verbose => $self->{ 'verbose' } );

    #
    #  Ignore plugins that don't implement "name()".
    #
    my @valid;

    foreach my $plugin (@plugins)
    {

        #
        #  Make sure the exported method is there.
        #
        push( @valid, $plugin );
        $count += 1;
    }


    #
    #  Sort by name.
    #
    if ($count)
    {
        my @sorted = map {$_->[0]}
          sort {$a->[1] cmp $b->[1]}
          map {[$_, ( ref $_ )]} @valid;

        #
        #  Squirrel them away for invokation later.
        #
        @{ $self->{ 'plugins' } } = @sorted;
    }
    else
    {
        print
          "ERROR: Failed to load any plugins from Blog::Spam::Plugin namespace\n";
    }


    #
    #  Return the count.
    #
    $self->{ 'verbose' } && print "Loaded $count plugins\n";
    return ($count);
}



=begin doc

Run any scheduled tasks.

It is assumed this method will be called from cron.  Something like:

=for example begin

  my $server = Blog::Spam::Server->new()
  $server->loadPlugins();
  $server->runTasks( "daily" );
  exit 0;

=for example end

=end doc

=cut

sub runTasks
{
    my ( $self, $label ) = (@_);

    $self->{ 'verbose' } && print "Running tasks: $label\n";

    foreach my $plugin ( @{ $self->{ 'plugins' } } )
    {

        #
        #  Ignore plugins which don't implement an 'expire' method.
        #
        my $name = ref $plugin;
        next unless ( $plugin->can("expire") );

        #
        #  Call plugin.
        #
        $self->{ 'verbose' } && print "$name - starting\n";
        $plugin->expire( $self, $label );
        $self->{ 'verbose' } && print "$name - done\n";
    }

    $self->{ 'verbose' } && print "All registered scheduler tasks executed.\n";
}




=begin doc

Run the main loop of our L<RPC::XML::Server> object and don't return.

=end doc

=cut

sub runLoop
{
    my ($self) = (@_);

    $self->{ 'verbose' } && print "Starting server loop\n";

    if ( ( !$self->{ 'daemon' } ) ||
         ( !$self->{ 'daemon' }->can("add_method") ) )
    {
        print "ERROR: Server not loaded!\n";
        return undef;
    }

    $self->{ 'daemon' }->server_loop();

}




=begin doc

This method is invoked for each incoming SPAM test.

=end doc

=cut

sub testComment
{
    my ( $self, $xmlrpc, $struct ) = (@_);

    #
    #  The parameters the user submitted, as a hash so
    # they're easy to work with.
    #
    my %struct;


    #
    #  Copy each supplied value to the struct we'll use
    # from here on in - but lower-case the key-names.
    #
    foreach my $key ( keys %$struct )
    {
        my $lkey = lc($key);

        $struct{ $lkey } = $struct->{ $key };
    }

    #
    #  Log the peer.
    #
    if ( $xmlrpc->{ 'peerhost' } )
    {
        $struct{ 'peer' } = $xmlrpc->{ 'peerhost' };

        $self->{ 'verbose' } &&
          print "Connection from " . $struct{ 'peer' } . "\n";

    }



    #
    #  If we've got an IPv6 prefix remove it.
    #
    if ( $struct{ 'ip' } && ( $struct{ 'ip' } =~ /^::ffff:(.*)/i ) )
    {
        $struct{ 'ip' } = $1;
    }


    #
    #  Pass ourself over to the plugin - primarily so that
    # a plugin may call L<getState> to find a location to
    # persist data to.
    #
    $struct{ 'parent' } = $self;


    #
    #  The mandatory values we expect by default.
    #
    my $options = "mandatory=ip,mandatory=comment";

    #
    #  The submission source might have added more options.
    #
    if ( defined( $struct{ 'options' } ) )
    {
        $options .= "," . $struct{ 'options' };
    }

    #
    #  A list of plugin calls to skip
    #
    my %skip;

    #
    #  Test for any mandatory parameters - if any are missing
    # it is an immediate fail.
    #
    foreach my $option ( split( /,/, $options ) )
    {
        $option =~ s/^\s+|\s+$//g;
        next unless ( length($option) );

        if ( $option =~ /^mandatory=(.*)/i )
        {
            my $key = $1;

            if ( !defined( $struct{ $key } ) ||
                 !length( $struct{ $key } ) )
            {
                return "SPAM:Missing $key";
            }
        }
        if ( $option =~ /^exclude=(.*)/i )
        {
            $skip{ $1 } = 1;
        }
    }

    #
    #  The result of this test + the name of the plugin that rejected
    # the comment, if any.
    #
    my $result  = undef;
    my $blocker = undef;


    #
    #  Call each plugin in sorted order - so we know that
    # 00-whitelist will run first.
    #
    foreach my $plugin ( @{ $self->{ 'plugins' } } )
    {

        #
        #  Ignore plugins that don't implement testComment.
        #
        next unless ( $plugin->can("testComment") );

        #
        #  The name of the plugin
        #
        my $name = ref $plugin;


        my $skipThis = 0;

        #
        # skip further plugins if we've previously received either
        #
        #  "good"  -> Means all further tests should be skipped.
        #
        # or
        #
        #  "spam"  -> The message was spam.
        #
        if ( defined($result) &&
             ( ( $result =~ /^spam/i ) ||
                ( $result =~ /^good/i ) ) )
        {
            $skipThis = 1;
        }


        #
        #  Are we to exclude this particular plugin?
        #
        foreach my $skip ( keys %skip )
        {
            if ( $name =~ /\Q$skip\E/ )
            {
                $self->{ 'verbose' } &&
                  print "\tSkipping: $name\n";

                $skipThis = 1;
            }

        }

        #
        #  Skip all further tests if either:
        #
        #   1.  We already ahve a result.
        #
        #   2.  This particular plugin is to be excluded, as
        #      decided by the caller.
        #
        next if ($skipThis);


        #
        #  Call the plugin
        #
        $self->{ 'verbose' } && print "Calling plugin: $name\n";

        $result = $plugin->testComment(%struct);

        if ( !defined($result) )
        {
            print "\tPLUGIN DIDN'T RETURN VALUE: $name\n";
        }
        else
        {
            $self->{ 'verbose' } && print "\t=> $result\n";
        }


        #
        #  If the result of calling the plugin was that the
        # comment was spam then record the name of the plugin.
        #
        #  This might be useful information in the future for
        # evaluating effectiveness.
        #
        if ( $result =~ /^spam:/i )
        {
            $blocker = ref $plugin;
            if ( $blocker =~ /(.*)::(.*)/ )
            {
                $blocker = $2;
            }
        }

    }


    #
    #  If we're not testing then log the message / log the stats.
    #
    if ( !$struct{ 'test' } )
    {

        #
        #  Log the blocking plugin.
        #
        $struct{ 'blocker' } = $blocker
          if ( defined($blocker) && length($blocker) );

        #
        #  The result.
        #
        $struct{ 'result' } = $result
          if ( defined($result) && length($result) );


        #
        #  Bump the statistics for the appropriate domain.
        #
        $self->bumpStats(%struct);

        #
        #  See if any plugin will handle the logging too.
        #
        foreach my $plugin ( @{ $self->{ 'plugins' } } )
        {

            #
            #  Ignore plugins that don't implement logMessage
            #
            next unless ( $plugin->can("logMessage") );

            #
            #  Call any loggin plugins
            #
            $self->{ 'verbose' } &&
              print "\tLogging result with " . ref $plugin . "\n";
            $plugin->logMessage( $self, %struct );
        }
    }


    #
    #  OK so if we weren't testing we'll have logged
    # the message, the result, and the blocker to
    # a file which will get rotated out.
    #
    #  If we're running with --verbose we should
    # now log a summary to the console.
    #
    #  Either way, verbose or not, we will log a summary
    # to syslog.
    #
    my $time = "[" . localtime(time) . "] ";

    #
    # Build up a message.
    #
    my $msg = "";
    $msg .= "TEST "                 if ( $struct{ 'test' } );
    $msg .= "PEER:$struct{'peer'} ";
    $msg .= "SITE:$struct{'site'} " if ( $struct{ 'site' } );
    $msg .= "IP:$struct{'ip'} ";
    $msg .= " BLOCKER:" . $blocker  if ($blocker);
    $msg .= " RESULT:" . $result    if ($result);

    #
    #  Show to console if we're verbose.
    #
    print "\t$time $msg\n" if ( $self->{ 'verbose' } );

    #
    #  But always log to syslog
    #
    syslog( "info|local0", $msg );


    #
    # We remap "good" to be "OK" so that we need only document
    # "OK" + "SPAM:[reason]" to the callers.
    #
    $result = "OK" if ( ( !defined($result) ) ||
                        ( $result =~ /^good$/i ) );

    #
    # Return the result to the caller.
    #
    return ($result);

}




=begin doc

This method is invoked when a comment is to be re-trained.

=end doc

=cut

sub classifyComment
{
    my ( $self, $xmlrpc, $struct ) = (@_);

    #
    #  The parameters the user submitted, as a hash so
    # they're easy to work with.
    #
    my %struct;


    #
    #  Copy each supplied value to the struct we'll use
    # from here on in - but lower-case the key-names.
    #
    foreach my $key ( keys %$struct )
    {
        my $lkey = lc($key);

        $struct{ $lkey } = $struct->{ $key };
    }

    #
    #  Log the peer.
    #
    if ( $xmlrpc->{ 'peerhost' } )
    {
        $struct{ 'peer' } = $xmlrpc->{ 'peerhost' };

        $self->{ 'verbose' } &&
          print "classifyComment: connection from " . $struct{ 'peer' } . "\n";

    }



    #
    #  If we've got an IPv6 prefix remove it.
    #
    if ( $struct{ 'ip' } && ( $struct{ 'ip' } =~ /^::ffff:(.*)/i ) )
    {
        $struct{ 'ip' } = $1;
    }


    #
    #  Pass ourself over to the plugin - primarily so that
    # a plugin may call L<getState> to find a location to
    # persist data to.
    #
    $struct{ 'parent' } = $self;


    #
    #  Call each plugin, which implements the classifycomment method,
    # in sorted order.
    #
    foreach my $plugin ( @{ $self->{ 'plugins' } } )
    {

        #
        #  Ignore plugins that don't implement testComment.
        #
        next unless ( $plugin->can("classifyComment") );

        #
        #  The name of the plugin
        #
        my $name = ref $plugin;

        #
        #  Call the plugin
        #
        $self->{ 'verbose' } && print "Calling plugin: $name\n";

        my $result = $plugin->classifyComment(%struct);

        if ( defined($result) && length($result) )
        {
            $self->{ 'verbose' } && print "\t=> $result\n";
        }
        else
        {
            $self->{ 'verbose' } && print "\t=> No result returned.\n";
        }
    }

    #
    # Return the result to the caller.
    #
    return ("TRAINED");

}


=begin doc

This method will return the SPAM/OK counts either globally or for the
given site.

=end doc

=cut

sub getStats
{
    my ( $self, $xmlrpc, $site ) = (@_);

    #
    #  Values we're going to read.
    #
    my $spam = 0;
    my $good = 0;

    #
    #  The local state directory.
    #
    my $state = $self->getStateDir();


    #
    #  Read per-site stats
    #
    if ( defined($site) && length($site) )
    {
        my $site = lc( $site || "unknown.example.org" );
        $site =~ s/[^a-z0-9]/_/g;

        $spam = $self->readCount( $state . "/stats/SPAM/$site/count" );
        $good = $self->readCount( $state . "/stats/OK/$site/count" );
    }
    else
    {

        #
        # Global stats
        #
        $spam = $self->readCount( $state . "/stats/SPAM/_global/count" );
        $good = $self->readCount( $state . "/stats/OK/_global/count" );
    }

    #
    #  Format the results
    #
    my $results;
    $results->{ 'spam' } = $spam;
    $results->{ 'ok' }   = $good;

    return ($results);
}




=begin doc

This method will return the list of loaded plugin names.

=end doc

=cut

sub getPlugins
{
    my ( $self, $xmlrpc ) = (@_);

    my $results;


    foreach my $plugin ( sort $self->plugins() )
    {
        my $name = ref $plugin || $plugin;

        if ( $name =~ /::([^:]+)$/ )
        {
            $name = $1;
        }
        push( @$results, $name );
    }
    return ($results);
}



=begin doc

Increase the global and per-domain SPAM/OK stats.

=end doc

=cut

sub bumpStats
{
    my ( $self, %struct ) = (@_);

    #
    #  The result should be stripped back.
    #
    my $result = $struct{ 'result' } || '';
    if ( $result =~ /^([^:]+):(.*)/ )
    {
        $result = $1;
    }

    #
    #  Get the state-storage directory.
    #
    my $state = $self->getStateDir();

    #
    #  Is the result OK?
    #
    if ( $result =~ /(ok|good)/i )
    {
        my $dir = $state . "/stats/OK/";

        # increase global
        $self->increaseCount( $dir . "/_global/count" );

        my $site = lc( $struct{ 'site' } || "unknown.example.org" );
        $site =~ s/[^a-z0-9]/_/g;

        # increase site
        $self->increaseCount( $dir . "/$site/count" );
    }

    #
    #  Is the result SPAM?
    #
    if ( $result =~ /spam/i )
    {
        my $dir = $state . "/stats/SPAM";

        $self->increaseCount( $dir . "/_global/count" );

        my $site = lc( $struct{ 'site' } || "unknown.example.org" );
        $site =~ s/[^a-z0-9]/_/g;

        # increase site
        $self->increaseCount( $dir . "/$site/count" );
    }

}



=begin doc

Increase an integer counter stored in the specified file.

=end doc

=cut

sub increaseCount
{
    my ( $self, $file ) = (@_);

    my $dir = dirname($file);
    if ( !-d $dir )
    {
        mkpath( $dir, { verbose => 0 } );
    }

    my $count = 0;
    if ( -e $file )
    {
        open( READ, "<", $file );
        $count = <READ>;
        close(READ);
        chomp($count);
    }


    $count += 1;

    open( FILE, ">", $file . "$$" );
    print FILE $count . "\n";
    close(FILE);

    File::Copy::move( $file . "$$", $file );

}



=begin doc

If the specified file exists read a number from it, otherwise
return zero.

=end doc

=cut

sub readCount
{
    my ( $self, $file ) = (@_);

    return 0 if ( !-e $file );

    open( FILE, "<", $file ) or
      return 0;

    my $count = <FILE>;
    chomp($count);

    close(FILE);

    return $count;
}


=begin doc

Find and return the name of the logging directory.

If we were given one via the constructor return that path,
otherwise look for the B<s-blogspam> user upon the system and use
the associated home directory.

If we have neither a defined path, nor the local user, then
we'll use a local directory in the CWD.

=end doc

=cut

sub getStateDir
{
    my ($self) = (@_);

    #
    #  If we were given one in the constructor use it.
    #
    return ( $self->{ 'state' } ) if ( defined( $self->{ 'state' } ) );

    my @user = getpwnam("s-blogspam");
    if (@user)
    {
        return ( $user[7] . "/state/" );
    }
    else
    {
        return "./state/";
    }
}


1;
