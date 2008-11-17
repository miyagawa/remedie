package Plagger::Plugin::Namespace::iTunesDTD;
use strict;
use base qw( Plagger::Plugin );

# Stupid!
our @iTunesNS = (
    'http://www.itunes.com/dtds/podcast-1.0.dtd',
    'http://www.itunes.com/dtds/Podcast-1.0.dtd',
    'http://www.itunes.com/DTDs/Podcast-1.0.dtd',
);

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.feed.fixup' => \&handle_feed,
        'aggregator.entry.fixup' => \&handle,
    );
}

sub handle_feed {
    my($self, $context, $args) = @_;

    for my $ns (@iTunesNS) {
        my $itunes;
        if ($args->{orig_feed}{rss} and $itunes = $args->{orig_feed}{rss}{channel}{$ns}) {
            if ($itunes->{image}) {
                $context->log(debug => "Image URL rewritten to $itunes->{image}{href}");
                $args->{feed}->image({ url => $itunes->{image}{href} });
            }
        }
    }

    1;
}

sub handle {
    my($self, $context, $args) = @_;

    for my $ns (@iTunesNS) {
        if (my $itunes = $args->{orig_entry}{entry}{$ns}) {
            my $summary = $itunes->{subtitle} || $itunes->{summary};
            if ($summary) {
                $context->log(debug => "Got summary from iTunes metadata: $summary");
                $args->{entry}->summary( Plagger::Text->new_from_text($summary) );
            }
        }
    }

    1;
}

1;
__END__
