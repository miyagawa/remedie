package Remedie::DB::Manager;
use strict;
use base qw( Rose::DB::Object::Manager );

sub lookup {
    my $self = shift;

    my $objs = $self->search(@_);
    return $objs->[0] if @$objs;
    return;
}

sub search {
    my $self = shift;

    return $self->get_objects(
        query => [ @_ ],
        object_class => $self->object_class,
    );
}

sub search_iter {
    my $self = shift;

    return $self->get_objects_iterator(
        query => [ @_ ],
        object_class => $self->object_class,
    );
}

1;
