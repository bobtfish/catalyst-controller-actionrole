use strict;
use warnings;
use Test::More tests => 24;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

my %roles = (
    foo  => 'TestApp::ActionRole::Moo',
    bar  => 'TestApp::ActionRole::Moo',
    baz  => 'Moo',
    quux => 'Catalyst::ActionRole::Zoo',
);

while (my ($path, $role) = each %roles) {
    my $resp = request("/foo/${path}");
    ok($resp->is_success);
    is($resp->content, $role);
    is($resp->header('X-Affe'), 'Tiger');
    my $resp2 = request("/bar/${path}");
    ok($resp2->is_success);
    is($resp2->content, $role);
    is($resp2->header('X-Affe'), 'Tiger');
}
