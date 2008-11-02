package Remedie::Server;
use Moose;

use JSON::XS;
use HTTP::Engine;
use MIME::Types;
use Path::Class;
use String::CamelCase;

use Remedie::Log;

has 'conf' => is => 'rw';

has 'engine' => (
    is      => 'rw',
    isa     => 'HTTP::Engine',
    lazy    => 1,
    builder => 'build_engine',
    handles => [ qw(run) ],
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub bootstrap {
    my($class, $conf) = @_;

    my $self = $class->new(conf => $conf);
    $self->run;
}

sub BUILD {
    my $self = shift;

    my $conf = $self->conf;
    local $ENV{REMEDIE_ACCESS_LOG} = 
        $ENV{REMEDIE_ACCESS_LOG} || $conf->{access_log} || 'access.log';
    local $ENV{REMEDIE_ERROR_LOG} = 
        $ENV{REMEDIE_ERROR_LOG} || $conf->{error_log} || 'error.log';
    local $ENV{REMEDIE_DEBUG} = 
        $ENV{REMEDIE_DEBUG} || $conf->{debug};

    Remedie::Log->init();

    return $self;
}

sub build_engine {
    my $self = shift;

    DEBUG "Initializing with HTTP::Engine version $HTTP::Engine::VERSION";
    return HTTP::Engine->new(
        interface => {
            module => 'ServerSimple',
            args   => $self->conf,
            request_handler => sub { $self->handle_request(@_) },
        },
    );
}

sub handle_request {
    my($self, $req) = @_;

    my $path = $req->path;

    my $res = HTTP::Engine::Response->new;
    $path = "/static/html/index.html" if $path eq "/";

    eval {
        if ($path =~ s!^/rpc/!!) {
            $self->dispatch_rpc($path, $req, $res);
        } elsif ($path =~ s!^/static/!!) {
            $self->serve_static_file($path, $req, $res);
        } else {
            die "Not found";
        }
    };

    if ($@ && $@ =~ /Not found/) {
        $res->status(404);
        $res->body("404 Not Found");
    } elsif ($@) {
        $res->status(500);
        $res->body("Internal Server Error");
        ERROR $@;
    }
    LOG_REQUEST($req, $res);

    return $res;
}

sub dispatch_rpc {
    my($self, $path, $req, $res) = @_;

    my @class  = split '/', $path;
    my $method = pop @class;

    die "Access to non-public methods" if $method =~ /^_/;

    my $rpc_class = join "::", "Remedie::Server::RPC", map String::CamelCase::camelize($_), @class;
    eval "require $rpc_class; 1" or die $@;

    my $rpc = $rpc_class->new( conf => $self->conf );

    my $result;
    eval {
        $result = $rpc->$method($req, $res);
    };

    if ($@) {
        $result->{error} = $@;
    } else {
        $result->{success} = 1;
    }

    $res->status(200);
    $res->content_type("application/json; charset=utf-8");
    $res->body( JSON::XS->new->allow_blessed->convert_blessed->utf8->encode($result) );
    DEBUG $res->body;
}

sub serve_static_file {
    my($self, $path, $req, $res) = @_;

    my $root = $self->conf->{root};
    my $file = file($root, "static", $path);

    if (-s $file && -r _) {
        my $ext = ($file =~ /\.(\w+)$/)[0];
        $res->content_type( MIME::Types->new->mimeTypeOf($ext) || "text/plain" );
        open my $fh, "<", $file or die "$file: $!";
        $res->body( join '', <$fh> );
    } else {
        die "Not found";
    }
}

1;
