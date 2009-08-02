package Remedie::Server;
use Any::Moose;

use attributes ();
use HTTP::Engine;
use MIME::Types;
use Net::Rendezvous::Publish;
use Path::Class;
use Path::Class::Unicode;
use String::CamelCase;
use HTTP::Date;
use URI::Escape;

use Remedie::Log;
use Remedie::JSON;
use Remedie::Updater;
use Remedie::PubSub;

use AnyEvent;
use Coro;
use Coro::AnyEvent;

my $coro_debug;

has 'conf' => is => 'rw';

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub bootstrap {
    my($class, $conf) = @_;

    my $self = $class->new(conf => $conf);

    $self->load_rpc_class([ $_ ]) for qw( channel collection item events remote );

    my $exit = sub { CORE::die('caught signal') };
    eval {
        local $SIG{INT}  = $exit if !$ENV{REMEDIE_DEBUG};
        local $SIG{QUIT} = $exit;
        local $SIG{TERM} = $exit;
        $self->run;
    };
    warn $@;
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

sub make_request_handler {
    my $self = shift;

    my $check_leak = $ENV{REMEDIE_DEBUG} && eval { require Devel::LeakGuard::Object; 1 };

    my $callback = $check_leak ?
        unblock_sub {
            my($req, $cb) = @_;
            Devel::LeakGuard::Object::leakguard(sub {
                my $res = $self->handle_request($req);
                $cb->($res);
            });
        } :
        unblock_sub {
            my($req, $cb) = @_;
            my $res = $self->handle_request($req);
            $cb->($res);
        };

    return $callback;
}

sub run {
    my $self = shift;

    Remedie::Log->log(debug => "Initializing with HTTP::Engine version $HTTP::Engine::VERSION");
    my $engine = HTTP::Engine->new(
        interface => {
            module => 'AnyEvent', # Change this to AnyEvent!
            args   => $self->conf,
            request_handler => $self->make_request_handler,
        },
    );

    my $owner_name = $self->owner_name;

    for my $proto (qw( http remedie )) {
        # TODO: make this AnyEvent::Bonjour
        my $w; $w = AnyEvent->timer(
            after => 0, cb => sub {
                undef $w;
                my $publisher = Net::Rendezvous::Publish->new
                    or return;
                my $service = $publisher->publish(
                    name => sprintf("%s's Remedie Server", $owner_name),
                    type => "_$proto._tcp",
                    port => $self->conf->{port},
                    domain => 'local',
                );
            },
        );
    }

    $engine->run;
    Remedie::Updater->start_workers(32); # TODO configurable
    Remedie::Updater->start_periodic_updater($self->conf);
    Remedie::PubSub->start_sweeper;

    if ($ENV{REMEDIE_DEBUG}) {
        require Coro::Debug;
        $coro_debug = new_tcp_server Coro::Debug 10011;
    }

    {
        my $t; $t = AnyEvent->timer(
            after => 0,
            interval => 1,
            cb => sub {
                scalar $t;
                # just loop forever to avoid runaway processes
                schedule;
            },
        );
    }

    AnyEvent->condvar->recv;
}

sub owner_name {
    my $self = shift;
    my $user = getlogin || getpwuid($<) || $ENV{USER};
    return eval { (getpwnam($user))[6] } || $user;
}

sub default_root {
    my($self, $req) = @_;
    $req->user_agent =~ /Mobile.*Safari|AppleWebKit.*Pre/ ? "/static/html/iui.html" : "/static/html/index.html";
}

sub handle_request {
    my($self, $req) = @_;

    my $path = $req->path;

    my $res = HTTP::Engine::Response->new;
    $path = $self->default_root($req) if $path eq "/";
    $path = "/static/crossdomain.xml" if $path eq "/crossdomain.xml";

    eval {
        if ($path =~ s!^/rpc/!!) {
            $self->dispatch_rpc($path, $req, $res);
        } elsif ($path =~ s!^/static/!!) {
            $self->serve_static_file($path, $req, $res);
        } elsif ($path =~ s!^/thumb/!!) {
            $self->serve_thumbnail($path, $req, $res);
        } else {
            die "Not found";
        }
    };

    if ($@ && $@ =~ /Not found/) {
        $res->status(404);
        $res->body("404 Not Found");
    } elsif ($@ && $@ =~ /Forbidden/) {
        $res->status(403);
        $res->body("403 Forbidden");
    } elsif ($@) {
        $res->status(500);
        $res->body("Internal Server Error: $@");
        Remedie::Log->log(error => $@);
    }
    Remedie::Log->log_request($req, $res);

    return $res;
}

sub load_rpc_class {
    my($self, $class_r) = @_;

    my $rpc_class = join "::", "Remedie::Server::RPC", map String::CamelCase::camelize($_), @$class_r;
    eval "require $rpc_class; 1" or die "$@"; ## no critic

    return $rpc_class;
}

sub dispatch_rpc {
    my($self, $path, $req, $res) = @_;

    my @class  = split '/', $path;
    my $method = pop @class;

    die "Access to non-public methods" if $method =~ /^_/;

    my $rpc_class = $self->load_rpc_class(\@class);

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
    } elsif (ref $result eq 'HASH') {
        $result->{success} = 1 unless defined $result->{success};
    }

    unless ( $res->body ) {
        $res->status(200);
        $res->content_type("application/json; charset=utf-8");
        $res->body( my $json = Remedie::JSON->encode($result) ); # store to $json to avoid Coro reference (?)
        Remedie::Log->log(debug => $res->body);
    }
}

sub serve_static_file {
    my($self, $path, $req, $res) = @_;

    my $root = $self->conf->{root};
    my $file = ufile($root, "static", $path);

    $self->do_serve_static($file, $req, $res);
}

sub serve_thumbnail {
    my($self, $path, $req, $res) = @_;

    if ($path =~ /%2f/i) {
        die "Forbidden: directory traversal";
    }

    $path = Encode::decode_utf8( URI::Escape::uri_unescape($path) );
    my $file = ufile($self->conf->{user_data}->path_to("thumb", $path));
    $self->do_serve_static($file, $req, $res);
}

sub do_serve_static {
    my($self, $file, $req, $res) = @_;

    my $exists      = -e $file;
    my $is_dir      = -d _;
    my $is_readable = -r _;

    if ($exists) {
        if ($is_dir || !$is_readable) {
            die "Forbidden";
        }
        my $size  = -s _;
        my $mtime = (stat(_))[9];
        my $ext = ($file =~ /\.(\w+)$/)[0];
        $res->content_type( MIME::Types->new->mimeTypeOf($ext) || "text/plain" );

        if (my $ims = $req->headers->header('If-Modified-Since')) {
            my $time = HTTP::Date::str2time($ims);
            if ($mtime <= $time) {
                $res->status(304);
                return;
            }
        }

        open my $fh, "<:raw", $file or die "$file: $!";
        $res->headers->header('Last-Modified' => HTTP::Date::time2str($mtime));
        $res->headers->header('Content-Length' => $size);
        $res->body($fh);
    } else {
        die "Not found";
    }
}

1;
