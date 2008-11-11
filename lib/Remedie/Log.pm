
package Remedie::Log;
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Sub::Exporter -setup => {
    exports => [ 
        qw(TRACE DEBUG ERROR INFO WARN FATAL LOG_REQUEST),
    ],
    groups => { default => [ qw(:all) ] },
};

# sigh, log4perl is pretty dumb
$INC{'Remedie/Log/Filter/MultiLevels.pm'} = 1;

sub unimport {
    my $package = caller(0);
    foreach my $name qw(TRACE DEBUG ERROR INFO WARN FATAL) {
        no strict 'refs'; ## no critic

        if ( defined &{ $package . '::' . $name } ) {
            my $sub = \&{ $package . '::' . $name };
            next unless \&{$name} == $sub;

            delete ${ $package . '::' }{$name};
        }
    }
}

sub init {
    my $conf = '';
    if ($ENV{REMEDIE_DEBUG}) {
        $conf .= <<'        EOCONF'
            log4perl.logger = DEBUG, AppError, AppAccess

            # Filter to match level DEBUG
            log4perl.filter.MatchError  = Remedie::Log::Filter::MultiLevels
            log4perl.filter.MatchError.LevelToMatch  = DEBUG, ERROR
            log4perl.filter.MatchError.AcceptOnMatch = true
        EOCONF
    } else {
        $conf .= <<'        EOCONF'
            log4perl.logger = INFO, AppError, AppAccess

            # Filter to match level ERROR
            log4perl.filter.MatchError = Log::Log4perl::Filter::LevelMatch
            log4perl.filter.MatchError.LevelToMatch  = ERROR
            log4perl.filter.MatchError.AcceptOnMatch = true
        EOCONF
    }

    $conf .= <<'    EOCONF';
        # Error appender
        log4perl.appender.AppError = Log::Log4perl::Appender::File
        log4perl.appender.AppError.filename = sub { $ENV{REMEDIE_ERROR_LOG} }
        log4perl.appender.AppError.layout   = PatternLayout
        log4perl.appender.AppError.layout.ConversionPattern = %d{ISO8601} %m%n
        log4perl.appender.AppError.Filter   = MatchError

        # Filter to match level INFO
        log4perl.filter.MatchAccess = Log::Log4perl::Filter::LevelMatch
        log4perl.filter.MatchAccess.LevelToMatch  = INFO
        log4perl.filter.MatchAccess.AcceptOnMatch = true
    
        # Access appender
        log4perl.appender.AppAccess = Log::Log4perl::Appender::File
        log4perl.appender.AppAccess.filename = sub { $ENV{REMEDIE_ACCESS_LOG} }
        log4perl.appender.AppAccess.layout   = PatternLayout
        log4perl.appender.AppAccess.Filter   = MatchAccess
        log4perl.appender.AppAccess.layout.ConversionPattern = %X{request_address} - %X{request_user} [%d{ISO8601}] "%X{request_method} %X{request_path_query} %X{request_protocol}" %X{response_status} %X{response_length} "%X{request_referer}" "%X{request_user_agent}"%n
    EOCONF

    Log::Log4perl->init(\$conf);
}
    
sub LOG_REQUEST {
    my($req, $res) = @_;

    Log::Log4perl::MDC->put( request_address    => $req->address );
    Log::Log4perl::MDC->put( request_user       => $req->user || '-');
    Log::Log4perl::MDC->put( request_method     => $req->method);
    Log::Log4perl::MDC->put( request_path_query => $req->uri->path_query);
    Log::Log4perl::MDC->put( request_protocol   => $req->protocol);
    Log::Log4perl::MDC->put( response_status    => $res->status);
    Log::Log4perl::MDC->put( response_length    => 
        $res->body ? bytes::length($res->body) : '-');
    Log::Log4perl::MDC->put( request_referer    => $req->referer || '-');
    Log::Log4perl::MDC->put( request_user_agent => $req->user_agent || '-');
    
    INFO '';
}

package Remedie::Log::Filter::MultiLevels;
use strict;
use base qw(Log::Log4perl::Filter::LevelMatch);

sub ok {
    my ($self, %p) = @_;

    my $levels = $self->{LevelsToMatch} ||
        ($self->{LevelsToMatch} = [ split(/\s*,\s*/, $self->{LevelToMatch}) ])
    ;
    foreach my $level ( @$levels ) {
        if($level eq $p{log4p_level}) {
            return $self->{AcceptOnMatch};
        }
    }
    
    return !$self->{AcceptOnMatch};
}

1;
