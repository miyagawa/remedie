package Plagger::Plugin::Filter::FindEnclosures;
use strict;
use base qw( Plagger::Plugin );

use HTML::TokeParser;
use List::Util qw(first);
use URI;
use URI::QueryParam;
use DirHandle;
use Plagger::Enclosure;
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;

    $context->autoload_plugin({ module => 'Filter::ResolveRelativeLink' });
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
        'enclosure.add' => \&upgrade,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->load_assets('pl', sub { $self->load_plugin_perl(@_) });

    $self->{ua} = Plagger::UserAgent->new;
}

sub asset_key { 'find_enclosures' }


sub load_plugin_perl {
    my($self, $file, $domain) = @_;

    open my $fh, '<', $file or Plagger->context->error("$file: $!");
    (my $pkg = $domain) =~ tr/A-Za-z0-9_/_/c;
    my $plugin_class = "Plagger::Plugin::Filter::FindEnclosures::Site::$pkg";

    my $code = join '', <$fh>;
    unless ($code =~ /^\s*package/s) {
        $code = join "\n",
            ( "package $plugin_class;",
              "use strict;",
              "use base qw( Plagger::Plugin::Filter::FindEnclosures::Site );",
              "sub domain { '$domain' }",
              $code,
              "1;" );
    }

    eval $code;
    Plagger->context->error($@) if $@;

    my $plugin = $plugin_class->new;
    $plugin->init;

    return $plugin;
}

sub load_plugin_yaml { Plagger->context->error("NOT IMPLEMENTED YET") }

sub filter {
    my($self, $context, $args) = @_;

    # check $entry->link first, if it links directly to media files
    $self->add_enclosure($args->{entry}, [ 'a', { href => $args->{entry}->permalink } ], 'href' );

    return unless $args->{entry}->body;

    $self->find_enclosures(\$args->{entry}->body->data, $args->{entry});
}

sub find_enclosures {
    my($self, $data_ref, $entry, %opt) = @_;

    my $parser = HTML::TokeParser->new($data_ref);
    while (my $tag = $parser->get_tag('a', 'embed', 'object', 'head')) {
        if ($tag->[0] eq 'a' ) {
            $self->add_enclosure($entry, $tag, 'href', \%opt);
        } elsif ($tag->[0] eq 'embed') {
            $self->add_enclosure_from_embed($entry, $tag, \%opt);
        } elsif ($tag->[0] eq 'object') {
            $self->add_enclosure_from_object($entry, $parser, %opt);
        } elsif ($tag->[0] eq 'head') {
            $self->add_enclosure_from_head($entry, $parser, %opt);
        }
    }
}

# http://www.facebook.com/share_partners.php
# link rel="video_src" etc.
sub add_enclosure_from_head {
    my($self, $entry, $parser, %opt) = @_;

    my(%meta, %link);
    while (my $tag = $parser->get_tag('meta', 'link', '/head')) {
        last if $tag->[0] eq '/head';
        if ($tag->[0] eq 'meta' && $tag->[1]{name}) {
            $meta{$tag->[1]{name}} = $tag->[1]{content};
        } elsif ($tag->[0] eq 'link' && $tag->[1]{rel}) {
            $link{$tag->[1]{rel}} = $tag->[1]{href};
        }
    }

    if ($link{video_src}) {
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url(URI->new($link{video_src}));
        $enclosure->type($meta{video_type})     if $meta{video_type};
        $enclosure->width($meta{video_width})   if $meta{video_width};
        $enclosure->height($meta{video_height}) if $meta{video_height};
        if ($link{image_src}) {
            $enclosure->thumbnail({ url => $link{image_src} });
        }
        $entry->add_enclosure($enclosure);
    }

    # TODO audio_src
}

sub add_enclosure_from_object {
    my($self, $entry, $parser, %opt) = @_;

    # get param tags and find appropriate FLV movies
    my @params;
    my @embeds;
    while (my $tag = $parser->get_tag('param', 'embed', '/object')) {
        last if $tag->[0] eq '/object';

        if ($tag->[0] eq 'param') {
            push @params, $tag;
        } elsif ($tag->[0] eq 'embed') {
            push @embeds, $tag;
        }
    }

    # find URL inside flashvars parameter
    my $url;
    if (my $flashvars = first { lc($_->[1]->{name}) eq 'flashvars' } @params) {
        my %values = split /[=&]/, $flashvars->[1]->{value} || '';
        $url   = first { m!^https?://.*\flv! } values %values;
        $url ||= first { m!^https?://.*! } values %values;
    }

    # if URL isn't found in flash vars, then fallback to <param name="movie" />
    if (!$url) {
        my $movie = first { lc($_->[1]->{name}) eq 'movie' } @params;
        $url = $movie->[1]->{value} if $movie && $movie->[1]->{value} =~ /\.flv/;
    }

    # found moviepath from flashvars: Just use them
    if ($url) {
        Plagger->context->log(info => "Found enclosure $url from flash params");
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url( URI->new($url) );
        $entry->add_enclosure($enclosure);
    } elsif (@embeds) {
        Plagger->context->log(info => "Use embed tags to create SWF enclosure");
        $self->add_enclosure_from_embed($entry, $embeds[0], \%opt);
    }
}

sub add_enclosure_from_embed {
    my($self, $entry, $embed, $opt) = @_;

    my($url, $image, $type);
    if (my $flashvars = $embed->[1]{flashvars}) {
        my %values = split /[=&]/, $flashvars || '';
        $url = $values{file}
            || first { m!^https?://.*\flv! } values %values
            || first { m!^https?://.*! } values %values
            || $values{movie};
        $image = $values{image};
    }

    unless ($url) {
        $url  = $embed->[1]{src};
        $type = "application/x-shockwave-flash";
        if ($url && $embed->[1]{flashvars}) {
            $url .= "?" . $embed->[1]{flashvars};
        }
        Plagger->context->log(debug => "Extracted swf from embed with flashvars: $url");
    }

    if ($url) {
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url( URI->new_abs($url, $entry->link) );
        $enclosure->type($type);
        $enclosure->thumbnail({ url => URI->new_abs($image, $entry->link) }) if $image;
        $entry->add_enclosure($enclosure);
    }
}

sub add_enclosure {
    my($self, $entry, $tag, $attr, $opt) = @_;
    $opt ||= {};

    if ($self->is_enclosure($tag, $attr, $opt->{type})) {
        Plagger->context->log(info => "Found enclosure $tag->[1]{$attr}");
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($tag->[1]{$attr});
        $enclosure->type($opt->{type});
        $enclosure->width($tag->[1]{width})   if $tag->[1]{width};
        $enclosure->height($tag->[1]{height}) if $tag->[1]{height};
        $entry->add_enclosure($enclosure);
        return;
    }

    return if $opt->{no_plugin};

    my $url = $tag->[1]{$attr};
    my $plugin = $self->asset_for($url);

    if ($plugin) {
        my $content;
        # FIXME there should be a way to suppress this if $entry already has enclosure
        if ($plugin->needs_content) {
            $content = $self->fetch_content($url) or return;
        }

        if (my $enclosure = $plugin->find({ content => $content, url => $url, entry => $entry })) {
            Plagger->context->log(info => "Found enclosure " . $enclosure->url ." with " . $plugin->domain);
            $entry->add_enclosure($enclosure);
            return;
        }
    }
}

sub is_enclosure {
    my($self, $tag, $attr, $type) = @_;

    return 1 if $tag->[1]{rel} && $tag->[1]{rel} eq 'enclosure';
    return 1 if $self->has_enclosure_mime_type($tag->[1]{$attr}, $type || $tag->[1]{type});

    return;
}

sub has_enclosure_mime_type {
    my($self, $url, $type) = @_;

    my $mime = $type ? MIME::Type->new(type => $type) : Plagger::Util::mime_type_of( URI->new($url) );
    Plagger::Util::mime_is_enclosure($mime);
}

sub upgrade {
    my($self, $context, $args) = @_;

    my $plugin = $self->asset_for($args->{enclosure}->url)
        || $self->asset_for($args->{entry}->link);
    if ($plugin) {
        $plugin->upgrade($args);
    }
}

package Plagger::Plugin::Filter::FindEnclosures::Site;
sub new { bless {}, shift }
sub init { Plagger->context->error($_[0]->domain . " should override init()") }
sub handle { "." }
sub upgrade { }
sub needs_content { 0 }
sub domain { '*' }

# by default, scans HTML for links and flashvars etc.
sub find {
    my($self, $args) = @_;
    Plagger->context->current_plugin->find_enclosures(\$args->{content}, $args->{entry}, no_plugin => 1);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FindEnclosures - Auto-find enclosures from entry content using B<< <a> >> / B<< <embed> >> tags

=head1 SYNOPSIS

  - module: Filter::FindEnclosures

=head1 DESCRIPTION

This plugin finds enclosures from C<< $entry->body >> by finding 1)
B<< <a> >> links with I<rel="enclosure"> attribute, 2) B<< <a> >>
links to any URL which filename extensions match with known
audio/video formats and 3) I<src> attributes in B<< <img> >> and B<< <embed> >> tags.

For example:

  Listen to the <a href="http://example.com/foobar.mp3">Podcast</a> now, or <a rel="enclosure"
  href="http://example.com/foobar.m4a">download AAC version</a>.

Those 3 links (I<foobar.mp3>, I<foobar.m4a> and I<logo.gif>) are
extracted as enclosures.

You might want to also use Filter::HEADEnclosureMetadata plugin to
know the actual length (bytes-length) of enclosures by sending HEAD
requests.

=head1 AUTHOR

Tatsuhiko Miyagawa

Masahiro Nagano

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::HEADEnclosureMetadata>, L<http://www.msgilligan.com/rss-enclosure-bp.html>, L<http://forums.feedburner.com/viewtopic.php?t=20>

=cut

