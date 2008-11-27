package Plagger::Plugin::Filter::RewriteThumbnailURL;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->conf->{rewrite} or Plagger->context->error("config 'rewrite' is not set.");
    $self->conf->{rewrite} = [ $self->conf->{rewrite} ] unless ref $self->conf->{rewrite};
}

sub filter {
    my($self, $context, $args) = @_;

    if (my $thumb = $args->{entry}->thumbnail) {
        my $orig = $thumb->{url};
        for my $rewrite (@{ $self->conf->{rewrite} }) {
            if ($orig =~ s/^\Q$rewrite->{local}\E//) {
                $thumb->{url} = $rewrite->{url} . $orig;
                $context->log(info => "thumbnail URL set to $thumb->{url}");
                last;
            }
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::RewriteThumbnailURL - Rewrite thumbnail URL for republishing

=head1 SYNOPSIS

  - module: Filter::RewriteThumbnailURL
    config:
      rewrite:
        - local: file:///home/miyagawa/.remedie/thumb
          url:   http://localhost:10010/thumb

=head1 DESCRIPTION

This plugin rewrites thumbnail URL using rewrite rule.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut

