package Plagger::Plugin::Filter::GoogleVideoPermalink;
use strict;
use base qw( Plagger::Plugin );
use URI;
use URI::QueryParam;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.feed.fixup' => \&handle_feed,
        'aggregator.entry.fixup' => \&filter,
    );
}

sub handle_feed {
    my($self, $context, $args) = @_;

    return unless $args->{feed}->url =~ m!^http://video\.google\.[^/]*/videosearch\?!;

    my $media_ns = 'http://search.yahoo.com/mrss/';
    for my $e ($args->{orig_feed}->entries) {
        # remove invalid media:player
        unless ($e->{entry}{$media_ns}{group}{$media_ns}{player}{width}) {
            delete($e->{entry}{$media_ns}{group}{$media_ns}{player});
        }
    }
}

sub filter {
    my($self, $context, $args) = @_;

    my $entry = $args->{entry};
    if ($entry->permalink =~ m!^http://www\.google\.[^/]*/url\?!) {
        my $permalink = URI->new($entry->permalink)->query_param('q') or return;
        $entry->permalink($permalink);
        $context->log(info => "Permalink rewritten to " . $entry->permalink);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::GoogleVideoPermalink - Fix GoogleVideo's permalink

=head1 SYNOPSIS

  - module: Filter::GoogleVideoPermalink

=head1 DESCRIPTION

Entries in GoogleVideo feeds contain links to Google's URL
redirector and that breaks some plugins like social bookmarks
integration.

This plugin updates the C<< $entry->permalink >> in GoogleVideo's feed,
so it actually points to the permalink, rather than redirector.

Note that C<< $entry->link >> will still point to the redirector.

=head1 AUTHOR

MATSUU Takuto

=head1 SEE ALSO

L<Plagger>, L<http://video.google.com/>

=cut
