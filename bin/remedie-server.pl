#!/usr/bin/perl
use strict;
use warnings;
use FindBin::libs;
use Getopt::Long;
use Pod::Usage;
use Cwd;
use Path::Class;

use Remedie::Server;

my %config = (
    port => 10010,
    host => 0, # ANY
    root => dir( Cwd::cwd, 'root' ),
);

GetOptions(\%config, "port=i", "host=s", "help");

if ($config{help}) {
    pod2usage(1);
}

Remedie::Server->bootstrap(\%config);

__END__

=head1 NAME

remedie-server - Remedie web server

=head1 SYNOPSIS

  remedie-server.pl --port=PORT --host=HOST

  --port PORT
    specifies the port number it listens to. Default: 10010

  --host HOST
    specifies the host address it binds to (e.g. 127.0.0.1). Default to any address.

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
