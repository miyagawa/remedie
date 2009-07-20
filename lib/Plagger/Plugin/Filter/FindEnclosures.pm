package Plagger::Plugin::Filter::FindEnclosures;
use strict;
use base qw( Plagger::Plugin );

use List::Util qw(first);
use URI;
use URI::QueryParam;
use DirHandle;
use Plagger::Enclosure;
use Plagger::UserAgent;
use HTML::TreeBuilder::LibXML;
use Scalar::Util;

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
    $self->load_assets('pl', sub { load_plugin_perl(@_) });

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
    $plugin->parent($self);
    Scalar::Util::weaken($plugin->{parent});

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

    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($$data_ref);
    $tree->eof;

    $self->findnodes($tree, '//a', sub {
        $self->add_enclosure($entry, $_[0], 'href', \%opt);
    });

    $self->findnodes($tree, '//object', sub {
        $self->add_enclosure_from_object($entry, $_[0], \%opt);
    });

    $self->findnodes($tree, '//embed', sub {
        $self->add_enclosure_from_embed($entry, $_[0], \%opt);
    });

    $self->findnodes($tree, '//head', sub {
        $self->add_enclosure_from_head($entry, $_[0], \%opt);
    });

    $tree->delete;
}

sub findnodes {
    my($self, $tree, $xpath, $callback) = @_;

    for my $node ($tree->findnodes($xpath)) {
        $callback->($node);
    }
}

# http://www.facebook.com/share_partners.php
# link rel="video_src" etc.
sub add_enclosure_from_head {
    my($self, $entry, $node, %opt) = @_;

    my(%meta, %link);

    for my $tag ($node->findnodes('./meta')) {
        $meta{$tag->attr('name')} = $tag->attr('content')
            if $tag->attr('name');
    }

    for my $tag ($node->findnodes('./link')) {
        $link{$tag->attr('rel')} = $tag->attr('href')
            if $tag->attr('rel');
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
    my($self, $entry, $node, %opt) = @_;

    # get param tags and find appropriate FLV movies
    my @params = map $self->_get_attrs($_), $node->findnodes('./param');

    # find URL inside flashvars parameter
    my $url;
    if (my $flashvars = first { lc($_->('name')) eq 'flashvars' } @params) {
        my %values = split /[=&]/, $flashvars->('value') || '';
        $url   = first { m!^https?://.*\flv! } values %values;
        $url ||= first { m!^https?://.*! } values %values;
    }

    # if URL isn't found in flash vars, then fallback to <param name="movie" />
    if (!$url) {
        my $movie = first { lc($_->('name')) eq 'movie' } @params;
        $url = $movie->('value') if $movie && $movie->('value') =~ /\.flv/;
    }

    # found moviepath from flashvars: Just use them
    if ($url) {
        Plagger->context->log(info => "Found enclosure $url from flash params");
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url( URI->new($url) );
        $entry->add_enclosure($enclosure);
    }
}

sub add_enclosure_from_embed {
    my($self, $entry, $embed, $opt) = @_;

    my $attrs = $self->_get_attrs($embed);

    my($url, $image, $type);
    if (my $flashvars = $attrs->('flashvars')) {
        my %values = split /[=&]/, $flashvars || '';
        $url = $values{file}
            || first { m!^https?://.*\flv! } values %values
            || first { m!^https?://.*! } values %values
            || $values{movie};
        $image = $values{image};
    }

    unless ($url) {
        $url  = $attrs->('src');
        $type = "application/x-shockwave-flash";
        if ($url && $attrs->('flashvars')) {
            $url .= "?" . $attrs->('flashvars');
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

sub _get_attrs {
    my($self, $tag) = @_;

    if (ref $tag eq 'HTML::TreeBuilder::LibXML::Node') {
        return sub { $tag->attr($_[0]) };
    } else {
        return sub { $tag->[1]{$_[0]} };
    }
}

sub add_enclosure {
    my($self, $entry, $tag, $attr, $opt) = @_;
    $opt ||= {};

    my $attrs = $self->_get_attrs($tag);

    if ($self->is_enclosure($attrs, $attr, $opt->{type})) {
        Plagger->context->log(info => "Found enclosure " . $attrs->($attr));
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($attrs->($attr));
        $enclosure->type($opt->{type});
        $enclosure->width($attrs->('width'))  if $attrs->('width');
        $enclosure->height($attr->('height')) if $attrs->('height');
        $entry->add_enclosure($enclosure);
        return;
    }

    return if $opt->{no_plugin};

    my $url = $attrs->($attr);
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
    my($self, $attrs, $attr, $type) = @_;

    return 1 if $attrs->('rel') && $attrs->('rel') eq 'enclosure';
    return 1 if $self->has_enclosure_mime_type($attrs->($attr), $type || $attrs->('type'));

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

sub parent {
    my $self = shift;
    $self->{parent} = shift if @_;
    $self->{parent};
}

# by default, scans HTML for links and flashvars etc.
sub find {
    my($self, $args) = @_;
    $self->parent->find_enclosures(\$args->{content}, $args->{entry}, no_plugin => 1);
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

