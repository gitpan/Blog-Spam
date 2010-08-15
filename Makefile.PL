# $Id$

use strict;
use lib './t/lib';
use ExtUtils::MakeMaker;

my %prereq_pm = (
    'Test::More'         => undef,
    'CGI::Session'  => undef,
    'Test::More' =>undef,
    'Getopt::Long' => undef,
    'IPC::Open2' => undef,
    'LWP::Simple' =>undef,
    'Module::Pluggable' =>undef,
    'Net::CIDR::Lite' => undef,
    'Net::DNS::Resolver' => undef,
    'RPC::XML::Server' => undef,
    'Sys::Syslog' => undef,
    'URI::Find' => undef,

);

WriteMakefile(
    NAME            => 'Blog::Spam',
    VERSION_FROM    => 'lib/Blog/Spam/Server.pm',
    EXE_FILES      => ['bin/blogspam'],
    PREREQ_PM       => \%prereq_pm,
    ABSTRACT        => 'Test blog comments for SPAM, in real-time',
    AUTHOR          => 'Steve Kemp <steve@steve.org.uk>',
);


package MY;
use strict;

sub postamble {
    return <<'MAKE_TEXT';
prepare_dist ::	metafile manifest dist
	$(NOECHO) $(NOOP)
MAKE_TEXT
}

#sub libscan {
#    my ($self, $path) = @_;
#    return '' if $path =~ m/\.svn/;
#    return $path;
#}

