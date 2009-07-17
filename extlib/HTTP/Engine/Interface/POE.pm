package HTTP::Engine::Interface::POE;
use Any::Moose;
our $CLIENT; ## no critic
use HTTP::Engine::Interface
    builder => 'NoEnv',
    writer  =>  {
        response_line => 1,
        'write' => sub {
            my ($self, $buffer) = @_;
            $CLIENT->put($buffer);
            return 1;
        }
    }
;

use POE qw/
    Component::Server::TCP
    Filter::HTTPD
/;
use URI::WithBase;

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

has alias => (
    is       => 'ro',
    isa      => 'Str | Undef',
);

my $filter = any_moose('::Meta::Class')->create(
    'HTTP::Engine::Interface::POE::Filter',
    superclasses => ['POE::Filter::HTTPD'],
    methods => {
        put => sub { # omit output filter
            shift; # class name
            return @_;
        }
    },
)->name;

sub run {
    my ($self) = @_;

    # setup poe session
    POE::Component::Server::TCP->new(
        Port         => $self->port,
        Address      => $self->host,
        ClientFilter => $filter->new,
        ( $self->alias ? ( Alias => $self->alias ) : () ),
        ClientInput  => _client_input($self),
        Started      => sub {
            warn( __PACKAGE__
                 . " : You can connect to your server at "
                 . "http://" . ($self->host || 'localhost') . ":"
                 . $self->port
                 . "/\n" );
        },
    );
}

sub handle_request {
    my($self, $client, %args) = @_;

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
        local $CLIENT = $client; # Ugh
        $self->response_writer->finalize( $req => $res );
        POE::Kernel->yield('shutdown');
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

sub _client_input {
    my $self = shift;

    sub {
        my ( $kernel, $heap, $request ) = @_[ KERNEL, HEAP, ARG0 ];

        # Filter::HTTPD sometimes generates HTTP::Response objects.
        # They indicate (and contain the response for) errors that occur
        # while parsing the client's HTTP request.  It's easiest to send
        # the responses as they are and finish up.
        if ( $request->isa('HTTP::Response') ) {
            $heap->{client}->put($request->as_string);
        } else {
            $self->handle_request($heap->{client}, %{ $self->_make_request($request, $heap) });
        }
    }
}

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
            protocol   => $request->protocol(),
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

=head1 NAME

HTTP::Engine::Interface::POE - POE interface for HTTP::Engine.

=head1 SYNOPSIS

    use POE;

    HTTP::Engine->new(
        interface => {
            module => 'POE',
            args   => {
                host => '127.0.0.1',
                port => 1984,
            },
            request_handler => sub {
                HTTP::Engine::Response->new(
                    status => 200,
                    body   => 'foo'
                )
            }
        },
    )->run;

    POE::Kernel->run();

=head1 DESCRIPTION

This is POE interface for HTTP::Engine.

=head1 ATTRIBUTES

=over 4

=item host

The bind address of TCP server.

=item port

The port number of TCP server.

=back

=head1 SEE ALSO

L<HTTP::Engine>

