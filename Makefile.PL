use inc::Module::Install;

name 'Remedie';
license 'perl';
all_from 'lib/Remedie.pm';

if ($^O eq 'darwin' && !-e 'inc/.author') {
    recommend_binary_install();
}

requires 'AnyEvent', 4.82;
requires 'AnyEvent::HTTP';
requires 'Bit::Vector';
requires 'Cache::Cache';
requires 'Class::Accessor::Fast';
requires 'Coro', 5.161;
requires 'EV', 3.6;
requires 'Date::Parse';
requires 'DateTime';
requires 'DateTime::Format::ISO8601';
requires 'DateTime::Format::Mail';
requires 'DateTime::Format::Strptime';
requires 'DateTime::TimeZone';
requires 'DBI', '1.607';
requires 'DBD::SQLite', '1.25';
requires 'Devel::LeakGuard::Object';
requires 'Digest::MD5';
requires 'Encode';
requires 'Feed::Find';
requires 'File::Find::Rule';
requires 'File::Find::Rule::Filesys::Virtual';
requires 'File::Temp';
requires 'Filesys::Virtual';
requires 'Filesys::Virtual::Plain';
requires 'HTML::Entities';
requires 'HTML::ResolveLink';
requires 'HTML::Selector::XPath';
requires 'HTML::Tagset';
requires 'HTML::TreeBuilder';
requires 'HTML::TreeBuilder::XPath', 0.09;
requires 'HTML::TreeBuilder::LibXML', 0.09;
requires 'HTTP::Date';
requires 'HTTP::Engine', '0.02002';
requires 'HTTP::Parser';
requires 'Image::Info';
requires 'JSON::XS';
requires 'List::Util';
requires 'Log::Dispatch';
requires 'Log::Dispatch::File';
requires 'LWP', 5.827;
requires 'MIME::Types';
requires 'Module::Pluggable', '3.9';
requires 'Net::Rendezvous::Publish';
requires 'Net::SSLeay';
requires 'Path::Class';
requires 'Path::Class::Unicode';
requires 'Pod::Usage';
requires 'Rose::DB';
requires 'Rose::DB::Object';
requires 'String::CamelCase';
requires 'String::ShellQuote';
requires 'Template';
requires 'Term::Encoding';
requires 'Text::Tags';
requires 'Tie::File';
requires 'UNIVERSAL::require';
requires 'URI', 1.37;
requires 'URI::Escape';
requires 'URI::Fetch';
requires 'Web::Scraper', 0.29;
requires 'XML::Atom';
requires 'XML::LibXML';
requires 'XML::LibXML::Simple';
requires 'XML::RSS::LibXML';
requires 'XML::Feed', 0.42;
requires 'XML::OPML::LibXML';
requires 'YAML::XS';

requires 'Any::Moose', 0.08;
requires_any_moose 'X::ConfigFromFile';
requires_any_moose 'X::Getopt';
requires_any_moose 'X::Types::Path::Class';

if ($^O eq 'darwin') {
    requires 'Mac::AppleScript';
    requires 'File::Spotlight', 0.04;
    requires 'Net::Rendezvous::Publish::Backend::Apple';
}

build_requires 'Test::More';
use_test_base;
auto_include_deps;
tests 't/*.t t/plagger/core/*.t t/plagger/plugins/*/*.t';
author_tests('xt');
include 'Module::AutoInstall';
auto_install;

WriteAll;

eval { require Plagger };
unless ($@) {
    warn <<WARN;
---------------------------------------------------------------

You seem to have Plagger $Plagger::VERSION in your system. Running
'make install' will overwrite forked Plagger modules and that will
break your existent Plagger installation. I recommend you not doing
that.

  DO NOT RUN 'make install'

You have been warned.

---------------------------------------------------------------
WARN
}

sub recommend_binary_install {
    warn <<WARN;
---------------------------------------------------------------

You're trying to build your own Remedie using Makefile.PL on Mac OS X.

There's a binary .app package available at http://github.com/miyagawa/remedie/downloads
and it is hightly recommended to install the binary unless you're a developer.

---------------------------------------------------------------
WARN
    sleep 5;
}
