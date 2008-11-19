use inc::Module::Install;

name 'Remedie';
all_from 'lib/Remedie.pm';

requires 'DateTime';
requires 'Encode';
requires 'Feed::Find';
requires 'FindBin::libs';
requires 'HTTP::Engine';
requires 'JSON::XS';
requires 'Log::Log4perl';
requires 'LWP::UserAgent';
requires 'MIME::Types';
requires 'Moose';
requires 'MooseX::ConfigFromFile';
requires 'MooseX::Getopt';
requires 'MooseX::Types::Path::Class';
requires 'Path::Class';
requires 'Rose::DB';
requires 'Rose::DB::Object';
requires 'String::CamelCase';
requires 'URI';
requires 'XML::RSS::LibXML';
requires 'Image::Info';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
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
