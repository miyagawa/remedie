package Remedie::DB::Object;
use strict;

use base qw( Rose::DB::Object );
use Remedie::DB;

sub init_db { Remedie::DB->new }
use Encode;
use Remedie::JSON;

sub json_encoded_columns {
    my($class, $col) = @_;
    $class->meta->column($col)->add_trigger(
        # needs to encode utf-8 before decoding JSON since we enable 'unicode' in Remedie::DB
        inflate => sub { $_[1] && !ref $_[1] ? Remedie::JSON->decode($_[1], 1) : ( $_[1] || {} ) },
    );
    $class->meta->column($col)->add_trigger(
        deflate => sub { !ref $_[1] ? $_[1] : Remedie::JSON->encode($_[1] || {}) },
    );
}

sub TO_JSON {
    my $self = shift;

    my $obj;
    for my $key ( $self->meta->columns, $self->columns_to_serialize ) {
        $obj->{$key} = $self->$key;
    }

    return $obj;
}

sub columns_to_serialize { }

1;
