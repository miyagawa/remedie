package Plagger::Plugin::Filter::MediaFilename;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Plagger::Enclosure;
use URI::filename;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    my $entry = $args->{entry};
    no warnings 'uninitialized';
    unless (URI->new($entry->link)->raw_filename eq encode_utf8($entry->title)) {
        return;
    }

    $context->log(debug => "Title equals filename. Extract info from the filename: " . $entry->title);

    my $orig = my $base = $entry->title;

    my $ext;
    $base =~ s/\.(\w+)$/$ext = $1; ""/e;

    $base =~ s/_/ /g;

    my $tag_re = '[\[\(\x{3010}]([^\)\]\x{3011}]*)[\)\]\x{3011}]';
    my @tags;
    while ( $base =~ s/^$tag_re\s*|\s*$tag_re\.?$// ) {
        push @tags, split /\s+/, ($1 || $2);
    }

    if ($base =~ s/\.(HR|[HP]DTV|WS|AAC|AC3|DVDRip|PROPER|DVDSCR|720p|1080p|[hx]264(?:-\w+)?|dd51)\.(.*)//i) {
        my $tags = "$1.$2";
        $base =~ s/\./ /g;
        # ad-hoc: rescue DD.MM.YY(YY)
        $base =~ s/(\d\d) (\d\d) (\d\d(\d\d)?)\b/$1.$2.$3/;
        push @tags, split /\./, $tags;
    }

    if ($base =~ s/\s+(RAW)$//i) {
        push @tags, $1;
    }

    if ($orig ne $base) {
        $context->log(debug => "Renamed to $base with tags: " . join(", ", @tags));
        $entry->title($base) if $base =~ /\S/;
        $entry->summary( Plagger::Text->new_from_text($orig) ) unless $entry->summary;
        $entry->add_tag($_) for (@tags, $ext);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::MediaFilename - Extract info from filename if entry doesn't have any title

=head1 SYNOPSIS

  - module: Filter::MediaFilename

=head1 DESCRIPTION

This plugin tries to extract some information from entry filename if
its title and URL filename are the same.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut

