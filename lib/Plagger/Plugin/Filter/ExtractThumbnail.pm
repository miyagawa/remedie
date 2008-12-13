package Plagger::Plugin::Filter::ExtractThumbnail;
use strict;
use base qw( Plagger::Plugin );

use HTML::TreeBuilder::XPath;

sub register {
    my ( $self, $context ) = @_;

    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
        'plugin.init'        => \&initialize,
    );
}

sub initialize {
    my $self = shift;
    $self->conf->{min_size} ||= 512;
}

sub update {
    my ( $self, $context, $args ) = @_;

    return if $args->{entry}->icon;

    if (defined $args->{entry}->body && $args->{entry}->body->is_html) {
        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse($args->{entry}->body);
        $tree->eof;

        my $curr;
        for my $img ($tree->findnodes("//img")) {
            my $size = 0;
            if ($img->attr('width') && $img->attr('height')) {
                $size = $img->attr('width') * $img->attr('height');
                next if $size <= $self->conf->{min_size};
            }

            my $current = $curr ? $curr->{size} : 0;
            if ($size > $current) {
                $curr = { image => $img, size => $size  };
            }
        }

        if (my $img = $curr->{image}) {
            $context->log(debug => "Extracted thumbnail " . $img->attr('src'));
            $args->{entry}->icon({
                url    => $img->attr('src'),
                width  => $img->attr('width'),
                height => $img->attr('height'),
            });
        }
    }
}

1;
