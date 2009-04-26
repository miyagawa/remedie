package Plagger::Cache;
use strict;
use CHI;
use File::Path;
use File::Spec;
use HTTP::Cookies;
use UNIVERSAL::require;

sub new {
    my($class, $conf, $name) = @_;

    mkdir $conf->{base}, 0700 unless -e $conf->{base} && -d _;

    # Cache default configuration
    $conf->{driver} ||= 'File';
    $conf->{params} ||= {
        root_dir => File::Spec->catfile($conf->{base}, 'cache'),
        $conf->{expires} ? (expires_in => $conf->{expires}) : (),
    };

    my $self = bless {
        base  => $conf->{base},
        cache => CHI->new( driver => $conf->{driver}, %{$conf->{params}} ),
        to_purge => $conf->{expires} ? 1 : 0,
    }, $class;
}

sub path_to {
    my($self, @path) = @_;
    if (@path > 1) {
        my @chunk = @path[0..$#path-1];
        mkpath(File::Spec->catfile($self->{base}, @chunk), 0, 0700);
    }
    File::Spec->catfile($self->{base}, @path);
}

sub get {
    my $self = shift;

    my $value = $self->{cache}->get(@_);
    my $hit_miss = defined $value ? "HIT" : "MISS";
    Plagger->context->log(debug => "Cache $hit_miss: $_[0]");

    $value;
}

sub get_callback {
    my $self = shift;
    my($key, $callback, $expiry) = @_;

    my $data = $self->get($key);
    if (defined $data) {
        return $data;
    }

    $data = $callback->();
    if (defined $data) {
        $self->set($key => $data, $expiry);
    }

    $data;
}

sub set {
    my $self = shift;
    my($key, $value, $expiry) = @_;
    $self->{cache}->set(@_);
}

sub remove {
    my $self = shift;
    $self->{cache}->remove(@_);
}

sub cookie_jar {
    my($self, $ns) = @_;
    my $file = $ns ? "$ns.dat" : "global.dat";

    my $dir = File::Spec->catfile($self->{base}, 'cookies');
    mkdir $dir, 0700 unless -e $dir && -d _;

    return HTTP::Cookies->new(
        file => File::Spec->catfile($dir, $file),
        autosave => 1,
    );
}

sub DESTROY {
    my $self = shift;
    $self->{cache}->purge() if $self->{to_purge};
}

1;
