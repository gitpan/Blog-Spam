
=head1 NAME

Blog::Spam::Plugin::00whitelist - Always permit comments from some IP addresses.

=cut

=head1 ABOUT

This plugin is designed to automatically accept comments which have been
submitted from known-good IP addresses.

This plugin allows the XML-RPC connection which arrived to contain the
whitelisted IP addresses and also will compare IP addresses to a server-wide
whitelist file.

B<Note>: The server administrator is responsible for populating the
global whitelist file (/etc/blogspam/goodips).

=cut

=head1 DETAILS

When an incoming comment is submitted for SPAM detection a number of
optional parameters may be included.  One of the optional parameters
is a list of CIDR ranges to automatically whitelist, which will always
receive an "OK" result from.

The options are discussed as part of the L<Blog::Spam::API>, in the
section L<TESTING OPTIONS|Blog::Spam::API/"TESTING OPTIONS">.

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

=end doc

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    # whitelist file.
    $self->{ 'whitelist-file' } = "/etc/blogspam/goodips";

    # verbose?
    $self->{ 'verbose' } = $supplied{ 'verbose' } || 0;

    bless( $self, $class );
    return $self;
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
    my $file = $self->{ 'whitelist-file' } || undef;

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
          print "re-reading whitelist file $file\n";

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
