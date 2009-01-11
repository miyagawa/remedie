package Web::Scraper::Filter;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

1;

__END__

=for stopwords namespace inline callback

=head1 NAME

Web::Scraper::Filter - Base class for Web::Scraper filters

=head1 SYNOPSIS

  package Web::Scraper::Filter::YAML;
  use base qw( Web::Scraper::Filter );
  use YAML ();

  sub filter {
      my($self, $value) = @_;
      YAML::Load($value);
  }

  1;

  use Web::Scraper;

  my $scraper = scraper {
      process ".yaml-code", data => [ 'TEXT', 'YAML' ];
  };

=head1 DESCRIPTION

Web::Scraper::Filter is a base class for text filters in
Web::Scraper. You can create your own text filter by subclassing this
module.

There are two ways to create and use your custom filter. If you name
your filter Web::Scraper::Filter::Something, you just call:

  process $exp, $key => [ 'TEXT', 'Something' ];

If you declare your filter under your own namespace, like
'MyApp::Filter::Foo',

  process $exp, $key => [ 'TEXT', '+MyApp::Filter::Foo' ];

You can also inline your filter function without creating a filter
class:

  process $exp, $key => [ 'TEXT', sub { s/foo/bar/ } ];

Note that this function munges C<$_> and returns the count of
replacement. Filter code special cases if the return value of the
callback is number and C<$_> value is updated.

You can, of course, stack filters like:

  process $exp, $key => [ '@href', 'Foo', '+MyApp::Filter::Bar', \&baz ];

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
