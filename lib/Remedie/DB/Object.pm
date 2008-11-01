package Remedie::DB::Object;
use strict;

use base qw( Rose::DB::Object );
use Remedie::DB;

sub init_db { Remedie::DB->new }
use JSON::XS;

sub json_encoded_columns {
    my($class, $col) = @_;
    $class->meta->column($col)->add_trigger(
        inflate => sub { $_[1] && !ref $_[1] ? JSON::XS::decode_json($_[1]) : ( $_[1] || {} ) },
    );
    $class->meta->column($col)->add_trigger(
        deflate => sub { JSON::XS::encode_json($_[1] || {}) },
    );
}

sub TO_JSON {
    my $self = shift;

    my $obj;
    for my $key ( $self->meta->columns ) {
        $obj->{$key} = $self->$key;
    }

    return $obj;
}

1;
