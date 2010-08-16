
=head1 NAME

Blog::Spam::Plugin::00whitelist - Always permit comments from some IP addresses.

=cut

=head1 ABOUT

This plugin is designed to automatically accept comments which have been
submitted from known-good IP addresses.

This plugin allows the XML-RPC connection which arrived to contain the
whitelisted IP addresses - it doesn't whitelist addresses which are
recorded upon the server this code is running upon.

There is also a locally tested file which is consulted for a list of
IP addresses, which is /etc/blogspam/goodips.

=cut

=head1 DETAILS

When an incoming comment is submitted for SPAM detection a number of
optional parameters may be included.  One of the optional parameters
is a list of CIDR ranges to automatically blacklist, and always return
a "SPAM" result from.

The options are discussed as part of the L<Blog::Server::API>, in the
section L<TESTING OPTIONS|Blog::Server::API/"TESTING OPTIONS">.

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


package Blog::Spam::Plugin::00whitelist;

use Net::CIDR::Lite;



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

    # blacklist file.
    $self->{ 'whitelist-file' } = "/etc/blogspam/goodips";

    # blacklist dir.
    $self->{ 'whitelist-dir' } = "/etc/whitelist.d/";

    # verbose?
    $self->{ 'verbose' } = $supplied{ 'verbose' } || 0;

    bless( $self, $class );
    return $self;
}


sub name
{
    my ($self) = (@_);
    return ( $self->{ 'name' } );
}



=begin doc

Is the given IP whitelisted?

=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);

    #
    #  Get the IP - this is mandatory, but it might be ipv6.
    #
    my $ip = $params{ 'ip' };


    #
    #  See if there is a whitelisting option in place.
    #
    my $options = $params{ 'options' };
    return "OK" if ( !defined($options) || !length($options) );

    #
    #  Split the options up.
    #
    foreach my $option ( split( /,/, $options ) )
    {
        if ( $option =~ /whitelist=(.*)/i )
        {
            my $val = $1;

            my $cidr = Net::CIDR::Lite->new;
            $cidr->add_any($val);

            return "GOOD" if ( $cidr->find($ip) );
        }
    }

    #
    #  Now look for a local whitelist file.
    #
    my $file = $self->{ 'blacklist-file' } || undef;

    #
    #  If there is no list then we cannot block.
    #
    return "OK" if ( !-e $file );

    #
    #  Get the modification time of the file.
    #
    my ( $dev,  $ino,   $mode,  $nlink, $uid,     $gid, $rdev,
         $size, $atime, $mtime, $ctime, $blksize, $blocks
       ) = stat($file);

    #
    #  If we've not loaded, or the file modification time has
    # changed then reload.
    #
    if ( !$self->{ 'gmtime' } ||
         $self->{ 'gmtime' } < $mtime )
    {
        $self->{ 'gips' } = undef;

        $self->{ 'verbose' } &&
          print $self->name() . ": re-reading whitelist file $file\n";

        if ( open( IPS, "<", $file ) )
        {
            while ( my $addr = <IPS> )
            {

                # skip blank lines
                next unless ( $addr && length($addr) );

                # Skip lines beginning with comments
                next if ( $addr =~ /^([ \t]*)\#/ );

                # strip spaces
                $addr =~ s/^\s+|\s+$//g;

                # strip newline
                chomp($addr);

                # empty now?
                next unless length($addr);

                $self->{ 'gips' }{ $addr } = 1;

                $self->{ 'verbose' } && print "Blacklisting: $addr\n";
            }

            close(IPS);
            $self->{ 'gmtime' } = $mtime;
        }
    }


    #
    #  Iterate over each blocked IP
    #
    foreach my $good ( keys %{ $self->{ 'gips' } } )
    {

        #
        #  Split an IP into a C-class.
        #
        if ( $good =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ )
        {
            $good = "$1.$2.$3.0/24";
        }

        my $cidr = Net::CIDR::Lite->new;
        $cidr->add_any($good);

        return "GOOD" if ( $cidr->find($ip) );
    }

    return "OK";
}


1;
