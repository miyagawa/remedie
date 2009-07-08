use inc::Module::Install;

name 'Remedie';
license 'perl';
all_from 'lib/Remedie.pm';

requires 'AnyEvent';
requires 'AnyEvent::HTTP';
requires 'Cache::Cache';
requires 'Class::Accessor::Fast';
requires 'Coro';
requires 'Date::Parse';
requires 'DateTime';
requires 'DateTime::Format::ISO8601';
requires 'DateTime::Format::Mail';
requires 'DateTime::Format::Strptime';
requires 'DateTime::TimeZone';
requires 'DBI', '1.607';
requires 'DBD::SQLite', '1.25';
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
requires 'HTML::Scrubber';
requires 'HTML::Selector::XPath';
requires 'HTML::Tagset';
requires 'HTML::TokeParser';
requires 'HTML::TreeBuilder';
requires 'HTML::TreeBuilder::XPath', 0.09;
requires 'HTTP::Date';
requires 'HTTP::Engine', '0.02002';
requires 'Image::Info';
requires 'JSON::XS';
requires 'List::Util';
requires 'Log::Dispatch';
requires 'Log::Dispatch::File';
requires 'LWP';
requires 'MIME::Types';
requires 'Net::Rendezvous::Publish';
requires 'Path::Class';
requires 'Path::Class::Unicode';
requires 'Pod::Usage';
requires 'POE';
requires 'POE::Component::Server::TCP';
requires 'POE::Filter::HTTPD';
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
requires 'Web::Scraper', 0.26;
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

WARNING WARNING WARNING WARNING WARNING WARNING

You seem to have Plagger $Plagger::VERSION in your system. Running
'make install' will overwrite forked Plagger modules and that will
break your existent Plagger installation. I recommend you not doing
that.

  DO NOT RUN 'make install'

You have been warned.

WARNING WARNING WARNING WARNING WARNING WARNING
WARN
}
