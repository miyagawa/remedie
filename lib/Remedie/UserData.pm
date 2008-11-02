package Remedie::UserData;
use Moose;
use MooseX::Types::Path::Class qw(Dir);

has 'base' => (
    is => 'rw',
    isa => Dir,
    coerce => 1,
    default => sub { Path::Class::Dir->new($ENV{HOME}, '.remedie') },
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub path_to {
    my($self, @path) = @_;

    ## TODO change this to something like Library/Application\ Support/Remedie
    my $base = $self->base;
    $base->mkpath(0777) unless -e $base;

    if (@path > 1) {
        my $file = pop @path;
        return $base->subdir(@path)->file($file);
    } else {
        return $base->file($path[0]);
    }
}

1;
