package Catalyst::Controller::ActionRole;
# ABSTRACT: Apply roles to action instances

use Moose;
use Class::MOP;
use Catalyst::Utils;
use Moose::Meta::Class;
use String::RewritePrefix;
use MooseX::Types::Moose qw/ArrayRef Str RoleName/;
use List::Util qw(first);

use namespace::clean -except => 'meta';

extends 'Catalyst::Controller';

=head1 SYNOPSIS

    package MyApp::Controller::Foo;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends qw/Catalyst::Controller::ActionRole/; }

    sub bar : Local Does('Moo') { ... }

=head1 DESCRIPTION

This module allows one to apply L<Moose::Role> based roles to any 
C<Catalyst::Action>s for more control over behavior reuse.

For that a C<Does> attribute is provided. That attribute takes an argument,
that determines the role, which is going to be applied. If that argument is
prefixed with C<+>, it is assumed to be the full name of the role. If it's
prefixed with C<~>, the name of your application followed by
C<::ActionRole::> is prepended. If it isn't prefixed with C<+> or C<~>,
the role name will be searched for in C<@INC> according to the rules for
L<role prefix searching|/ROLE PREFIX SEARCHING>.

Additionally it's possible to to apply roles to B<all> actions of a controller
without specifying the C<Does> keyword in every action definition:

    package MyApp::Controller::Bar;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends qw/Catalyst::Controller::ActionRole/; }

    __PACKAGE__->config(
        action_roles => ['Foo', '~Bar'],
    );

    # Has Catalyst::ActionRole::Foo and MyApp::ActionRole::Bar applied.
    # If MyApp::ActionRole::Foo exists and is loadable, it will take
    # precedence over Catalyst::ActionRole::Foo
    # If MyApp::ActionRole::Bar exists and is loadable, it will be loaded,
    # but even if it doesn't exist Catalyst::ActionRole::Bar will not be loaded.

    sub moo : Local { ... }

Additionally roles could be applied to selected actions without specifying
C<Does> using L<Catalyst::Controller/action> and configured with
L<Catalyst::Controller/action_args>:

    package MyApp::Controller::Baz;

    use parent qw/Catalyst::Controller::ActionRole/;

    __PACKAGE__->config(
        action_roles => [qw( Foo )],
        action => {
            some_action => { Does => [qw( ~Bar )] },
            another_action => { Does => [qw( +MyActionRole::Baz )] },
        },
        action_args => {
            another_action => { custom_arg => 'arg1' },
        }
    );

    # has Catalyst::ActionRole::Foo and MyApp::ActionRole::Bar applied
    sub some_action : Local { ... }

    # has Catalyst::ActionRole::Foo and MyActionRole::Baz applied
    # and associated action class would get additional arguments passed
    sub another_action : Local { ... }

=head1 ROLE PREFIX SEARCHING

Roles specified with no prefix are looked up under a set of role prefixes.  The
first prefix is always C<MyApp::ActionRole::> (with C<MyApp> replaced as
appropriate for your application); the following prefixes are taken from the
C<_action_role_prefix> attribute.

=attr _action_role_prefix

This class attribute stores an array reference of role prefixes to search for
role names in if they aren't prefixed with C<+> or C<~>. It defaults to
C<[ 'Catalyst::ActionRole::' ]>.  See L</role prefix searching>.

=cut

__PACKAGE__->mk_classdata(qw/_action_role_prefix/);
__PACKAGE__->_action_role_prefix([ 'Catalyst::ActionRole::' ]);

=attr _action_roles

This attribute stores an array reference of role names that will be applied to
every action of this controller. It can be set by passing a C<action_roles>
argument to the constructor. The same expansions as for C<Does> will be
performed.

=cut

has _action_role_args => (
    traits     => [qw(Array)],
    isa        => ArrayRef[Str],
    init_arg   => 'action_roles',
    default    => sub { [] },
    handles    => {
        _action_role_args => 'elements',
    },
);

has _action_roles => (
    traits     => [qw(Array)],
    isa        => ArrayRef[RoleName],
    init_arg   => undef,
    lazy_build => 1,
    handles    => {
        _action_roles => 'elements',
    },
);

sub _build__action_roles {
    my $self = shift;
    my @roles = $self->_expand_role_shortname($self->_action_role_args);
    Class::MOP::load_class($_) for @roles;
    return \@roles;
}

sub BUILD {
    my $self = shift;
    # force this to run at object creation time
    $self->_action_roles;
}

sub _apply_action_class_roles {
    my ($self, $class, @roles) = @_;

    Class::MOP::load_class($_) for @roles;
    my $meta = Moose::Meta::Class->initialize($class)->create_anon_class(
        superclasses => [$class],
        roles        => \@roles,
        cache        => 1,
    );
    $meta->add_method(meta => sub { $meta });

    return $meta->name;
}


around 'action_class', sub {
    my ($orig, $self, %args) = @_;
    my $class = $self->$orig(%args);

    Moose->init_meta(for_class => $class)
        unless Class::MOP::does_metaclass_exist($class);

    my @roles = $self->gather_action_roles(%args);

    $class = $self->_apply_action_class_roles($class, @roles)
      if @roles;

    return $class;
};

sub gather_action_roles {
    my ($self, %args) = @_;
    return (
        (blessed $self ? $self->_action_roles : ()),
        @{ $args{attributes}->{Does} || [] },
    );
}

sub _expand_role_shortname {
    my ($self, @shortnames) = @_;
    my $app = $self->_application;
    my $prefix = $self->can('_action_role_prefix') 
      ? $self->_action_role_prefix
      : ['Catalyst::ActionRole::'];

    my @prefixes = (qq{${app}::ActionRole::}, @$prefix);

    return String::RewritePrefix->rewrite(
        { ''  => sub {
            my $loaded = Class::MOP::load_first_existing_class(
                map { "$_$_[0]" } @prefixes
            );
            return first { $loaded =~ /^$_/ }
              sort { length $b <=> length $a } @prefixes;
          },
          '~' => $prefixes[0],
          '+' => '' },
        @shortnames,
    );
}

sub _parse_Does_attr {
    my ($self, $app, $name, $value) = @_;
    return Does => $self->_expand_role_shortname($value);
}

=begin Pod::Coverage

  BUILD

=end Pod::Coverage

=cut

1;

