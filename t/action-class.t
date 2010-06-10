use strict;
use warnings;
use Test::More tests => 4;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

my $resp = request( "/actionclass/one" );
ok( $resp->is_success );
is( $resp->content, 'Catalyst::Action::TestActionClass' );

my $action_arg_response = request("/boo/foo");
ok( $action_arg_response->is_success );
is( $action_arg_response->content, 'hello' );

