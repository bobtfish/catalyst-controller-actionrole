package TestApp::Controller::FormFuRHS;

use Moose;

our $HAVE_FORMFU;
BEGIN {
    $HAVE_FORMFU = eval { require Catalyst::Controller::HTML::FormFu; };

    if ($HAVE_FORMFU) {
        extends qw/
            Catalyst::Controller::ActionRole
            Catalyst::Controller::HTML::FormFu
        /;
    }
    else {
        extends 'Catalyst::Controller::ActionRole';
    }
}

sub foo  : Local Does('Moo') {
    my ($self, $c) = @_;
    die('->form method does not show up')
        if ($HAVE_FORMFU && !$self->can('form'));
}

1;

