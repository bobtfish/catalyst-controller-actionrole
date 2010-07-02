use strict;
use warnings;
use Test::More tests => 4;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

my $action_arg_response = request("/boo/foo");
ok( $action_arg_response->is_success );
is( $action_arg_response->content, 'hello' );

my $action_arg_response1 = request("/boo/foo2");
ok( $action_arg_response1->is_success );
is( $action_arg_response1->content, 'world' );

