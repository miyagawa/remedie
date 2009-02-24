package Remedie::Server::RPC;
use Any::Moose;
has conf => is => 'rw';

my $attr_cache = {};

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub MODIFY_CODE_ATTRIBUTES {
    my($class, $code, @attr) = @_;
    $attr_cache->{$class}{$code} = \@attr;
    return ();
}

sub FETCH_CODE_ATTRIBUTES {
    my($class, $code) = @_;
    @{ $attr_cache->{$class}{$code} || [] };
}

1;
