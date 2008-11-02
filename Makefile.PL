use inc::Module::Install;
name 'Remedie';
all_from 'lib/Remedie.pm';

requires 'DateTime';
requires 'Feed::Find';
requires 'FindBin::libs';
requires 'JSON::XS';
requires 'LWP::UserAgent';
requires 'MIME::Types';
requires 'Moose';
requires 'Path::Class';
requires 'URI';
requires 'XML::RSS::LibXML';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
WriteAll;
