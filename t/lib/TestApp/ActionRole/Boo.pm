package TestApp::ActionRole::Boo;

use Moose::Role;

has boo => (is=>'ro', required=>1, default=>'wrong');

around execute => sub {
    my ($orig, $self, $controller, $c, @rest) = @_;
    $c->stash(action_boo => $self->boo);
    return $self->$orig($controller, $c, @rest);
};

1;
