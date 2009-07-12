package HTTP::Engine::Interface::AnyEvent;
use Any::Moose;
use AnyEvent::Handle;
use AnyEvent::Socket;
use HTTP::Parser;
use URI::WithBase;

our $CLIENT;
use HTTP::Engine::Interface
    builder => 'NoEnv',
    writer  =>  {
        response_line => 1,
        'write' => sub {
            my ($self, $buffer) = @_;
            $CLIENT->push_write($buffer);
            return 1;
        }
    },
;

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => '127.0.0.1',
    trigger  => sub {
        my $self = shift;
        utf8::downgrade($self->{host});
    },
);

has port => (
    is       => 'ro',
    isa      => 'Int',
    default  => 1978,
    trigger  => sub {
        my $self = shift;
        utf8::downgrade($self->{port});
    },
);

has listen_guard => (
    is => 'rw',
    isa => 'Guard',
);

sub run {
    my $self = shift;

    my $guard = tcp_server $self->host, $self->port, sub {
        my($sock, $peer_host, $peer_port) = @_;

        if (!$sock) {
            return;
        }

        my $parser = HTTP::Parser->new;
        my $handle; $handle = AnyEvent::Handle->new(
            fh         => $sock,
            timeout    => 30,
            on_eof     => sub { undef $handle },
            on_error   => sub { undef $handle; warn $! },
            on_timeout => sub { undef $handle },
        );

        $handle->on_read(sub {
            my $handle = shift;
            my $buf = delete $handle->{rbuf};
            my $status = $parser->add($buf);
            if ($status == 0) {
                $self->handle_request($handle, %{ $self->_make_request($parser->request, { remote_ip => $peer_host }) });
            }
        });

        return;
    };

    $self->listen_guard($guard);
}

# FIXME: almost copied from POE.pm
sub handle_request {
    my($self, $socket, %args) = @_;

    my $req = HTTP::Engine::Request->new(
        request_builder => $self->request_builder,
        %args,
    );

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
        local $CLIENT = $socket; # Ugh
        $self->response_writer->finalize( $req => $res );
        $socket->push_shutdown;
    };

    my $res;
    eval { $res = $self->request_handler->($req, $cb) };

    if ($@) {
        return $cb->(undef, $@);
    }

    # support the standard interface too.
    if ( Scalar::Util::blessed($res)
         && $res->isa('HTTP::Engine::Response') ) {
        return $cb->($res);
    }
}

# FIXME: copied from POE.pm
sub _make_request {
    my ($self, $request, $heap) = @_;

    my ($host, $port) = $request->headers->header('Host') ?
        split(':', $request->headers->header('Host')) : ($self->host, $self->port);

    {
        headers => $request->headers,
        uri     => URI::WithBase->new(do {
            my $uri = $request->uri->clone;
            $uri->scheme('http');
            $uri->host($host);
            $uri->port($port);
            $uri->path('/') if $request->uri =~ m!^https?://!i;

            my $b = $uri->clone;
            $b->path_query('/');

            ($uri, $b);
        }),
        connection_info => {
            address    => $heap->{remote_ip},
            method     => $request->method,
            port       => $port,
            user       => undef,
            _https_info => 'OFF',
            protocol   => "HTTP/" . $request->header('X_HTTP_Version'), # XXX ->protocol is not set in HTTP::Parser
            request_uri => "".$request->uri,
        },
        _connection => {
            input_handle  => do {
                my $buf = $request->content;
                open my $fh, '<', \$buf;
                $fh;
            },
            output_handle => undef,
            env           => \%ENV,
        },
    };
}

__INTERFACE__

__END__
