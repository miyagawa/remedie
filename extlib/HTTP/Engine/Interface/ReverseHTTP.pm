package HTTP::Engine::Interface::ReverseHTTP;
use Any::Moose;
use AnyEvent::ReverseHTTP;
use URI;
use URI::WithBase;

use HTTP::Engine::Interface
    builder => 'NoEnv',
    writer  => { };

has label => (
    is => 'rw', isa => 'Str',
);

has token => (
    is => 'rw', isa => 'Str',
);

has endpoint => (
    is => 'rw', isa => 'Str',
);

has app_uri => (
    is => 'rw', isa => 'URI',
);

has guard => (
    is => 'rw', isa => 'Guard',
);

sub run {
    my $self = shift;

    my $server = AnyEvent::ReverseHTTP->new(
        on_register => sub {
            my $app_uri = shift;
            warn __PACKAGE__, ": reversehttp running at $app_uri\n";
            $self->app_uri(URI->new($app_uri));
        },
        on_request => sub {
            my $http_req = shift;
            $self->handle_request(%{ $self->_make_request($http_req) });
        },
    );

    $server->label($self->label)       if $self->label;
    $server->token($self->token)       if $self->token;
    $server->endpoint($self->endpoint) if $self->endpoint;

    $self->guard($server->connect);
}

sub handle_request {
    my($self, %args) = @_;

    my $req = HTTP::Engine::Request->new(
        request_builder => $self->request_builder,
        %args,
    );

    my $cv = AnyEvent->condvar;

    my $cb = sub {
        my($res, $err) = @_;

        unless ( Scalar::Util::blessed($res)
                && $res->isa('HTTP::Engine::Response') ) {
            $err = "You should return instance of HTTP::Engine::Response.";
        }

        if ($err) {
            print STDERR $err;
            $res = HTTP::Engine::Response->new(
                status => 500,
                body   => 'internal server error',
            );
        }

        HTTP::Engine::ResponseFinalizer->finalize( $req => $res );

        my $http_res = $res->as_http_response;

        # Really finalize the response here
        my $content;
        my $body = $http_res->content;
        if ((Scalar::Util::blessed($body) && $body->can('read')) || (ref($body) eq 'GLOB')) {
            while (!eof $body) {
                read $body, my ($buffer), 4096;
                $content .= $buffer;
            }
            close $body;
        } else {
            $content = $body;
        }

        $http_res->content($content);
        $cv->send($http_res);
    };

    # TODO we should rewrite request_handler to directly support
    # Condvar based HTTP::Engine::Response for continuation
    my $res;
    eval { $res = $self->request_handler->($req, $cb) };

    if ($@) {
        $cb->(undef, $@);
        return $cv;
    }

    # support the standard interface too.
    if ( Scalar::Util::blessed($res)
         && $res->isa('HTTP::Engine::Response') ) {
        $cb->($res);
    }

    return $cv;
}

sub _make_request {
    my($self, $request) = @_;

    return {
        headers  => $request->headers,
        uri  => URI::WithBase->new($request->uri),
        base => do {
            my $base = $request->uri->clone;
            $base->path_query('/');
            $base;
        },
        port    => $self->app_uri->port,
        connection_info => {
            address  => $request->header('Requesting-Client'),
            method   => $request->method,
            protocol => $request->protocol,
            user     => undef,
            _https_info => undef,
            request_uri => $request->uri . "",
        },
        _connection => {
            input_handle => do {
                my $buf = $request->content;
                open my $fh, "<", \$buf;
                $fh;
            },
            env => {},
        },
    };
}

__INTERFACE__

__END__
