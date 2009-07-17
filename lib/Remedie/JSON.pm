package Remedie::JSON;
use strict;
use Carp;
use JSON::XS ();
use Encode ();
use overload ();

sub roundtrip {
    my($class, $data) = @_;
    $class->decode($class->encode($data));
}

sub decode {
    my $class = shift;
    my($str, $encode_utf8) = @_;

    $str = Encode::encode_utf8($str) if $encode_utf8;
    JSON::XS::decode_json($str);
}

sub encode {
    my $class = shift;
    my($stuff) = @_;

    local *UNIVERSAL::TO_JSON = sub {
        my $obj = shift;
        if (my $method = overload::Method($obj, q(""))) {
            return $obj->$method();
        } else {
            croak sprintf qq(Can't locate object method "TO_JSON" via pacakge "%s"), ref $obj;
        }
    };

    # for future DBD::SQLite with proper Unicode bug fixes, this
    # SHOULD return decoded string instead of UTF-8 encoded strings
    # (with utf8 option). For now we always use ->ascii, so there's no
    # forward compatiblity problem.
    JSON::XS->new->allow_blessed->convert_blessed->ascii->encode($stuff);
}

1;
