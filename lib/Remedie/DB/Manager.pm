package Remedie::DB::Manager;
use strict;
use base qw( Rose::DB::Object::Manager );

sub lookup {
    my $self = shift;

    my $objs = $self->get_objects(
        query => [ @_ ],
        object_class => $self->object_class,
    );

    return $objs->[0] if @$objs;
    return;
}

1;
