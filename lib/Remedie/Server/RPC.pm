package Remedie::Server::RPC;
use Moose;
use MooseX::ClassAttribute;

has       conf => is => 'rw';
class_has attr_cache => (
    is => 'rw', isa => 'HashRef',
    default => sub { +{} },
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub MODIFY_CODE_ATTRIBUTES {
    my($class, $code, @attr) = @_;
    $class->attr_cache->{$code} = \@attr;
    return ();
}

sub FETCH_CODE_ATTRIBUTES {
    my($class, $code) = @_;
    @{ $class->attr_cache->{$code} || [] };
}

1;
