package Remedie::Server::RPC;
use Moose;

has conf => is => 'rw';

__PACKAGE__->meta->make_immutable;

no Moose;

1;
