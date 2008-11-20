package Remedie::Server;
use Moose;

use attributes ();
use HTTP::Engine;
use MIME::Types;
use Path::Class;
use POSIX;
use String::CamelCase;

use Remedie::Log;
use Remedie::JSON;

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

    my $exit = sub { CORE::die('caught signal') };
    eval {
        local $SIG{INT}  = $exit;
        local $SIG{QUIT} = $exit;
        local $SIG{TERM} = $exit;
        $self->run;
    };
    Remedie::Log->log(error => "Exiting feed... $@");
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

    Remedie::Log->log(debug => "Initializing with HTTP::Engine version $HTTP::Engine::VERSION");
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
        } elsif ($path =~ s!^/action/!!) {
            $self->serve_action_cgi($path, $req, $res);
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
        Remedie::Log->log(error => $@);
    }
    Remedie::Log->log_request($req, $res);

    return $res;
}

sub dispatch_rpc {
    my($self, $path, $req, $res) = @_;

    my @class  = split '/', $path;
    my $method = pop @class;

    die "Access to non-public methods" if $method =~ /^_/;

    my $rpc_class = join "::", "Remedie::Server::RPC", map String::CamelCase::camelize($_), @class;
    eval "require $rpc_class; 1" or die $@; ## no critic

    my $rpc = $rpc_class->new( conf => $self->conf );

    my $result;
    eval {
        my $code = $rpc->can($method) or die "Not found";
        my @attr = attributes::get($code);
        if ( grep $_ eq 'POST', @attr ) {
            die "Request should be POST and have X-Remedie-Client header"
                unless $req->method eq 'POST' && $req->header('X-Remedie-Client');
        }
        $result = $rpc->$method($req, $res);
    };

    if ($@) {
        $result->{error} = $@;
    } else {
        $result->{success} = 1;
    }

    unless ( $res->body ) {
        $res->status(200);
        $res->content_type("application/json; charset=utf-8");
        $res->body( Remedie::JSON->encode($result) );
        Remedie::Log->log(debug => $res->body);
    }
}

sub serve_action_cgi {
    my($self, $path, $req, $res) = @_;

    my $root = $self->conf->{root};
    my $file = file($root, "action");

    my @targets = split(/\//, $path);
    my $script_name = '';
    while (my $target = shift(@targets)) {
        $file = file($file->stringify, $target);
        $script_name .= "/$target";
        unless ($file->is_dir) {
            my $pid = fork();
            if ($pid) {
                waitpid($pid, &POSIX::WNOHANG);
                return;
            } elsif ($pid == 0) {
                local $ENV{SCRIPT_FILENAME} = "$file";
                local $ENV{SCRIPT_NAME} = $script_name;
                local $ENV{PATH_INFO} = '/'.join '/', @targets;
                package main;
                do "$file";
                exit;
            } else {
                die $!;
            }
        }
    }
    die "Not found";
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
