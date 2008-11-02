package Remedie::CLI::Worker;
use Moose;
use Remedie::Worker;

with 'MooseX::Getopt';

__PACKAGE__->meta->make_immutable;

no Moose;

sub run {
    Remedie::Worker->new->run();
}

1;