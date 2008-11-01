use inc::Module::Install;
name 'Remedie';
all_from 'lib/Remedie.pm';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
WriteAll;
