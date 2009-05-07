#line 1
package Module::Install::Base;

use strict 'vars';
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.87';
}

# Suspend handler for "redefined" warnings
BEGIN {
	my $w = $SIG{__WARN__};
	$SIG{__WARN__} = sub { $w };
}

### This is the ONLY module that shouldn't have strict on
# use strict;

#line 45

sub new {
	my ($class, %args) = @_;

	foreach my $method ( qw(call load) ) {
		next if defined &{"$class\::$method"};
		*{"$class\::$method"} = sub {
			shift()->_top->$method(@_);
		};
	}

	bless( \%args, $class );
}

#line 66

sub AUTOLOAD {
	my $self = shift;
	local $@;
	my $autoload = eval {
		$self->_top->autoload
	} or return;
	goto &$autoload;
}

#line 83

sub _top {
	$_[0]->{_top};
}

#line 98

sub admin {
	$_[0]->_top->{admin}
	or
	Module::Install::Base::FakeAdmin->new;
}

#line 114

sub is_admin {
	$_[0]->admin->VERSION;
}

sub DESTROY {}

package Module::Install::Base::FakeAdmin;

my $fake;

sub new {
	$fake ||= bless(\@_, $_[0]);
}

sub AUTOLOAD {}

sub DESTROY {}

# Restore warning handler
BEGIN {
	$SIG{__WARN__} = $SIG{__WARN__}->();
}

1;

#line 162
