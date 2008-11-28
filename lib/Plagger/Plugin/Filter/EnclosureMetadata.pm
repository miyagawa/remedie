package Plagger::Plugin::Filter::EnclosureMetadata;
use strict;
use base qw( Plagger::Plugin );

use HTML::TokeParser;
use Plagger::Enclosure;
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'enclosure.add' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    my $enclosure = $args->{enclosure};
    return unless $enclosure->url;

    # Check the filename and type mismatch. Override with the one from filename if it doesn't match
    my $type = $enclosure->type;
    my $mime = Plagger::Util::mime_type_of($enclosure->url);

    if (Plagger::Util::mime_is_enclosure($mime) and
        $self->should_update($type, $mime->type)) {
        $context->log(info => "Auto-setting MIME type " .  $mime->type . " on " . $enclosure->url);
        $enclosure->type($mime->type);
    }
}

sub should_update {
    my($self, $orig, $new) = @_;

    return 1 unless $orig;

    # .avi divx file should be explicitly set as video/divx
    return if $orig =~ /video\/(?:x-)?divx/;

    return lc($orig) ne lc($new);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::EnclosureMetadata - Fixes enclosures metadata by looking at filenames etc.

=head1 SYNOPSIS

  - module: Filter::EnclosureMetadata

=head1 DESCRIPTION

This plugin fixes, guesses or auto-adds enclosures type metadata by
checking its filenames, sending HEAD requests or chcking content magic
header if available.

For example:

  <enclosure type="audio/mpeg" url="http://example.com/foo.mp4" />

=head1 AUTHOR

Tatsuhiko Miyagawa

Masayoshi Sekimura

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::HEADEnclosureMetadata>, L<http://subtech.g.hatena.ne.jp/sekimura/20081119/p1>

=cut

