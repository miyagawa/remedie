package Plagger::Plugin::Filter::FeedBurnerPermalink;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.entry.fixup' => \&fixup,
        'update.entry.fixup' => \&filter,
    );
}

sub fixup {
    my($self, $context, $args) = @_;

    my @ns = ('http://rssnamespace.org/feedburner/ext/1.0', 'http://www.pheedo.com/namespace/pheedo');

    # RSS 1.0 & 2.0
    if (ref($args->{orig_entry}) =~ /RSS/) {
        for my $ns (@ns) {
            if (my $orig_link = $args->{orig_entry}->{entry}->{$ns}->{origLink}) {
                $args->{entry}->permalink($orig_link);
                $context->log(info => "Permalink rewritten to $orig_link");
            }
        }
    }
    # Atom 1.0
    elsif (ref($args->{orig_entry}) =~ /Atom/) {
        for my $ns (@ns) {
            my $atom_ns = XML::Atom::Namespace->new(feedburner => $ns);
            if (my $orig_link = $args->{orig_entry}->{entry}->get($atom_ns, 'origLink')) {
                $args->{entry}->permalink($orig_link);
                $context->log(info => "Permalink rewritten to $orig_link");
            }
        }
    }
}

sub filter {
    my($self, $context, $args) = @_;

    # RSS 2.0 SmartFeed
    my $entry = $args->{entry};
    if ($entry->permalink =~ m!^http://feeds\.feedburner\.(com|jp)/!) {
        $entry->permalink( $entry->id . "" ); # stringify guid
        $context->log(info => "Permalink rewritten to " . $entry->permalink);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FeedBurnerPermalink - Fix FeedBurner's permalink

=head1 SYNOPSIS

  - module: Filter::FeedBurnerPermalink

=head1 DESCRIPTION

Entries in FeedBurner feeds contain links to feedburner's URL
redirector and that breaks some plugins like social bookmarks
integration.

This plugin updates the C<< $entry->permalink >> with I<guid> value in
FeedBurner's feed, so it actually points to the permalink, rather than
redirector.

Note that C<< $entry->link >> will still point to the redirector.

=head1 AUTHOR

Masahiro Nagano

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.feedburner.com/>

=cut
