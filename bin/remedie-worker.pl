#!/usr/bin/perl
use strict;
use warnings;
use FindBin::libs;
use Remedie::CLI::Worker;

Remedie::CLI::Worker->new_with_options->run();

__END__

=head1 NAME

remedie-job - Run periodic Remedie jobs

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
