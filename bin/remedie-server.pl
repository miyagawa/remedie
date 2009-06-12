#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib qw( $FindBin::Bin/../lib $FindBin::Bin/../extlib );
use local::lib qw( $FindBin::Bin/../cpanlib );
use Remedie::CLI::Server;

Remedie::CLI::Server->new_with_options->run();

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
