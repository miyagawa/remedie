use inc::Module::Install;

name 'Remedie';
license 'perl';
all_from 'lib/Remedie.pm';

requires 'Cache::Cache';
requires 'Class::Accessor::Fast';
requires 'Date::Parse';
requires 'DateTime';
requires 'DateTime::Format::ISO8601';
requires 'DateTime::Format::Mail';
requires 'DateTime::Format::Strptime';
requires 'DateTime::TimeZone';
requires 'DBI';
requires 'DBD::SQLite', '1.1901';
requires 'Digest::MD5';
requires 'Encode';
requires 'Feed::Find';
requires 'File::Find::Rule';
requires 'File::Find::Rule::Filesys::Virtual';
requires 'File::Temp';
requires 'Filesys::Virtual';
requires 'Filesys::Virtual::Plain';
requires 'FindBin::libs';
requires 'HTML::Entities';
requires 'HTML::ResolveLink';
requires 'HTML::Scrubber';
requires 'HTML::Selector::XPath';
requires 'HTML::Tagset';
requires 'HTML::TokeParser';
requires 'HTML::TreeBuilder';
requires 'HTML::TreeBuilder::XPath', 0.09;
requires 'HTTP::Date';
requires 'HTTP::Engine';
requires 'Image::Info';
requires 'JSON::XS';
requires 'List::Util';
requires 'Log::Dispatch';
requires 'Log::Dispatch::File';
requires 'Log::Log4perl';
requires 'LWP::UserAgent';
requires 'MIME::Types';
requires 'Any::Moose', 0.05;
requires 'Mouse';
requires 'MouseX::ConfigFromFile';
requires 'MouseX::Getopt';
requires 'MouseX::Types::Path::Class';
requires 'Path::Class';
requires 'Path::Class::Unicode';
requires 'Pod::Usage';
requires 'Rose::DB';
requires 'Rose::DB::Object';
requires 'String::CamelCase';
requires 'String::ShellQuote';
requires 'Template';
requires 'Term::Encoding';
requires 'Text::Tags::Parser';
requires 'Tie::File';
requires 'UNIVERSAL::require';
requires 'URI';
requires 'URI::Escape';
requires 'URI::Fetch';
requires 'URI::QueryParam';
requires 'Web::Scraper', 0.26;
requires 'XML::Atom';
requires 'XML::LibXML';
requires 'XML::LibXML::Simple';
requires 'XML::RSS::LibXML';
requires 'XML::Feed', 0.41;
requires 'XML::OPML::LibXML';
requires 'YAML';
requires 'YAML::Syck';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
tests 't/*.t t/plagger/core/*.t t/plagger/plugins/*/*.t';
author_tests('xt');
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
