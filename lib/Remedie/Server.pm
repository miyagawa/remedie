package Remedie::Server;
use strict;
use warnings;

use Moose;
use JSON::XS;
use HTTP::Engine;
use MIME::Types;
use Path::Class;
use String::CamelCase;

has 'conf' => is => 'rw';

sub bootstrap {
    my($class, $conf) = @_;

    my $self = $class->new(conf => $conf);

    my $engine = HTTP::Engine->new(
        interface => {
            module => 'ServerSimple',
            args   => $conf,
            request_handler => sub { $self->handle_request(@_) },
        },
    );

    $engine->run;
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
        warn $@;
    }

    $self->log_request($req, $res);

    return $res;
}

sub dispatch_rpc {
    my($self, $path, $req, $res) = @_;

    my @class  = split '/', $path;
    my $method = pop @class;
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

sub log_request {
    my($self, $req, $res) = @_;

    warn sprintf "%s %s %s [%s] \"%s %s %s\" %s %s \"%s\" \"%s\"\n",
        $req->address,
        '-', $req->user || '-',
        scalar localtime, # not compatible with CLF
        $req->method, $req->uri->path_query, $req->protocol, $res->status, length($res->body) || '-',
        $req->referer || '-', $req->user_agent || '-';
}

1;
