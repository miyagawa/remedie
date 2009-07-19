package Plagger::Plugin::Filter::StripHTML;
use strict;
use base qw( Plagger::Plugin );

use HTML::TreeBuilder::LibXML;

sub register {
    my ( $self, $context ) = @_;

    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my ( $self, $context, $args ) = @_;

    if (defined $args->{entry}->body && $args->{entry}->body->is_html) {
        $context->log(debug => "Stripping HTML body for " . $args->{entry}->permalink || '(no-link)');
        $args->{entry}->body( $self->as_text($args->{entry}->body) );

        if ($args->{entry}->summary && $args->{entry}->summary->type eq 'html') {
            my $scrubbed = $self->as_text( $args->{entry}->summary->data );
            $args->{entry}->summary( Plagger::Text->new_from_text($scrubbed) )
        }
    }
}

sub as_text {
    my($self, $html) = @_;

    my $tree = HTML::TreeBuilder::LibXML->new;
    $tree->parse($html);
    $tree->eof;

    return $tree->as_text;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::StripHTML - Strip HTML from entry body

=head1 SYNOPSIS

  - module: Filter::StripHTML

=head1 DESCRIPTION

This plugin scrubs feed content using L<HTML::TreeBuilder::LibXML>

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<HTML::TreeBuilder::LibXML>

=cut
