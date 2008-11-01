package Remedie::DB::Object;
use strict;

use base qw( Rose::DB::Object );
use Remedie::DB;

sub init_db { Remedie::DB->new }
use Encode;
use JSON::XS;

sub json_encoded_columns {
    my($class, $col) = @_;
    $class->meta->column($col)->add_trigger(
        # needs to encode utf-8 before decoding JSON since we enable 'unicode' in Remedie::DB
        inflate => sub { $_[1] && !ref $_[1] ? JSON::XS::decode_json( encode_utf8($_[1]) ) : ( $_[1] || {} ) },
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
