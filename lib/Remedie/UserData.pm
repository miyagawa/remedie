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
    $base->mkpath(oct 777, { verbose => 0 }) unless -e $base;

    if (@path > 1) {
        my $file = pop @path;
        return $base->subdir(@path)->file($file);
    } else {
        return $base->file($path[0]);
    }
}

# I hate Path::Class
sub path_to_dir {
    my($self, @path) = @_;

    my $dir= $self->base->subdir(@path);
    $dir->mkpath(oct 777, { verbose => 0 }) unless -e $dir;

    return $dir;
}

1;
