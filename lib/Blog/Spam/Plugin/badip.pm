
=head1 NAME

Blog::Spam::Plugin::badip - Reject comments from known-bad IP addresses.

=cut

=head1 ABOUT

This plugin is designed to discard comments which have been submitted
from locally blacklisted IP addresses.

=cut

=head1 DETAILS

The plugin handles two cases:

=over 8

=item A file being present with a name such as /etc/blacklist.d/1.2.3.4

=item An entry in /etc/blogspam/badips matching the incoming IP

=back

Note that the server administrator is responsible for populating the
named directory, or file.

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



package Blog::Spam::Plugin::badip;

use Net::CIDR::Lite;

use strict;
use warnings;



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

    # plugin name
    $self->{ 'name' } = $proto;

    # blacklist file.
    $self->{ 'blacklist-file' } = "/etc/blogspam/badips";

    # blacklist dir.
    $self->{ 'blacklist-dir' } = "/etc/blacklist.d/";

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

Block a comment if the IP address it has been submitted from has
been locally blacklisted.

The local blacklist is read from /etc/blogspam/badips and each
line is assumed to be a Class C address.

To handle single IP addreses a test will be made against
/etc/blacklist.d/1.2.3.4 - for the IP address 1.2.3.4.


=end doc

=cut

sub testComment
{
    my ( $self, %params ) = (@_);


    #
    #  We will always have the IP
    #
    my $ip = $params{ 'ip' };

    #
    #  We don't yet block IPv6
    #
    return "OK" if ( $ip =~ /:/ );

    #
    #  We'll not test malformed IPs.
    #
    return "SPAM:malformed IP"
      unless ( $ip =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ );


    #
    #  Has this IP done bad before?
    #
    my $dir = $self->{ 'backlist-dir' } || undef;

    if ( defined($dir) && ( -e "/etc/blacklist.d/$ip" ) )
    {
        return "SPAM:badip:/etc/blacklist.d/$ip";
    }

    #
    #  The source of bad IPs
    #
    my $file = $self->{ 'blacklist-file' } || undef;

    #
    #  If there is no blacklist then we cannot block.
    #
    return "OK" if ( !defined($file) || ( !-e $file ) );

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
    if ( !$self->{ 'fmtime' } ||
         $self->{ 'fmtime' } < $mtime )
    {
        $self->{ 'ips' } = undef;

        $self->{ 'verbose' } &&
          print $self->name() . ": re-reading blacklist file $file\n";

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

                $self->{ 'ips' }{ $addr } = 1;

                $self->{ 'verbose' } && print "Blacklisting: $addr\n";
            }
            close(IPS);
            $self->{ 'fmtime' } = $mtime;
        }
    }


    #
    #  Iterate over each blocked IP
    #
    foreach my $banned ( keys %{ $self->{ 'ips' } } )
    {

        #
        #  Split an IP into a C-class.
        #
        if ( $banned =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ )
        {
            $banned = "$1.$2.$3.0/24";
        }

        my $cidr = Net::CIDR::Lite->new;
        $cidr->add_any($banned);

        return "SPAM:badip:$ip" if ( $cidr->find($ip) );
    }


    return "OK";
}


1;
