package Remedie::CLI::Server;
use Moose;
use MooseX::Types::Path::Class qw(File Dir);
use Remedie::DB::Schema;
use Remedie::Server;
use Remedie::UserData;
use Pod::Usage;
use YAML();

with 'MooseX::Getopt',
     'MooseX::ConfigFromFile';

has '+configfile' => (
    default => Remedie::UserData->new->path_to("config.yaml")->stringify,
);

has 'root' => (
    traits      => [ 'Getopt' ],
    cmd_aliases => 'r',
    is          => 'rw',
    isa         => Dir,
    required    => 1,
    coerce      => 1,
    default     => sub { Path::Class::Dir->new('root')->absolute },
);

has 'user_data' => (
    is          => 'rw',
    isa         => 'Remedie::UserData',
    required    => 1,
    coerce      => 1,
    default     => sub { Remedie::UserData->new },
);

has 'net_server' => (
    traits      => [ 'Getopt' ],
    is          => 'rw',
    isa         => 'Str',
    required    => 0,
);

has 'host' => (
    traits      => [ 'Getopt' ],
    cmd_aliases => 'h',
    is          => 'rw',
    isa         => 'Str',
    default     => 0,
);

has 'port' => (
    traits      => [ 'Getopt' ],
    cmd_aliases => 'p',
    is          => 'rw',
    isa         => 'Int',
    default     => 10010,
    required    => 1,
);

has 'debug' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0
);

has 'help' => (
    traits      => [ 'Getopt' ],
    cmd_aliases => 'h',
    is          => 'rw',
    isa         => 'Bool',
    default     => 0
);

has 'access_log' => (
    traits      => [ 'Getopt' ],
    cmd_aliases => 'a',
    is          => 'rw',
    isa         => File,
    required    => 1,
    lazy        => 1,
    coerce      => 1,
    builder     => 'build_access_log'
);

has 'error_log' => (
    traits      => [ 'Getopt' ],
    cmd_aliases => 'e',
    is          => 'rw',
    isa         => File,
    required    => 1,
    lazy        => 1,
    coerce      => 1,
    builder     => 'build_error_log'
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub build_access_log { shift->user_data->path_to('logs', 'access.log') }
sub build_error_log  { shift->user_data->path_to('logs', 'error.log') }

sub get_config_from_file {
    my ($class, $file) = @_;

    if (-f $file) {
        return YAML::LoadFile($file);
    } else {
        return {};
    }
}

sub run {
    my $self = shift;
    if ($self->help) {
        pod2usage(
            -input => (caller(0))[1],
            -exitval => 1,
        );
    }

    Remedie::DB::Schema->upgrade();

    Remedie::Server->bootstrap({
        host       => $self->host,
        port       => $self->port,
        net_server => $self->net_server,
        root       => $self->root,
        error_log  => $self->error_log,
        access_log => $self->access_log,
        debug      => $self->debug,
        user_data  => $self->user_data,
    });
}

1;
