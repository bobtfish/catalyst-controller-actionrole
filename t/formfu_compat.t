use strict;
use warnings;
use Test::More;

if (eval { require Catalyst::Controller::HTML::FormFu; }
    && Catalyst::Controller::HTML::FormFu->VERSION('0.04003')
) {
    plan tests => 2;
    diag "Testing with Catalyst::Controller::HTML::FormFu version "
        . Catalyst::Controller::HTML::FormFu->VERSION;
}
else {
    plan skip_all => 'Catalyst::Controller::HTML::FormFu not installed';
    exit 0;
}

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

ok(request('/formfurhs/foo')->is_success);
ok(request('/formfulhs/foo')->is_success);

