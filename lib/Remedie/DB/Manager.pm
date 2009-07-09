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
    $self->_run_search('get_objects', @_);
}

sub search_iter {
    my $self = shift;
    $self->_run_search('get_objects_iterator', @_);
}

sub _run_search {
    my($self, $method, %args) = @_;

    my $db = delete $args{db};
    return $self->$method(
        query => [ %args ],
        object_class => $self->object_class,
        ($db ? (db => $db) : ()),
    );
}

1;
