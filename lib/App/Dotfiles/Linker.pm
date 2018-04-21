package App::Dotfiles::Linker;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;
with 'App::Dotfiles::Role::Runtime';

use App::Dotfiles::Error;

use Carp;
use File::Copy;
use Path::Tiny;

use namespace::clean;

has _dirs => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

has _links => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

sub plan_module {
    my ( $self, $module ) = @_;

    my $target_path_prefix = path( $module->target_path_prefix );

    if ( $target_path_prefix eq q{.} ) {

        # Module will be linked into the root of the home directory
        $self->_plan_directory_content( $module, q{.} );
        return;
    }

    # Module will be linked into the sub directory $target_path_prefix of the
    # home directory
    my $dir = $target_path_prefix;
    while ( ( $dir = $dir->parent() ) ne q{.} ) {
        $self->_plan_directory_ignore_shift( $module, $dir );
    }

    $self->_plan_link( $module, q{.} );
    return;
}

sub run {
    my ($self) = @_;

    my $actions_ref = $self->_create_actions();

    my $runtime   = $self->runtime;
    my $home_path = path( $runtime->home_path );

  ACTION:
    for my $action ( @{$actions_ref} ) {
        my ( $target, $task, $module, $source ) = @{$action};

        if ( $task eq 'link' ) {
            my $module_path        = path( $module->module_path );
            my $source_path        = $module_path;
            my $source_path_prefix = $module->source_path_prefix;
            if ( defined $source_path_prefix ) {
                $source_path = $source_path->child($source_path_prefix);
            }
            $source_path = $source_path->child($source);
            my $target_path = $home_path->child($target);

            my $diff = $source_path->relative( $target_path->parent );

            print "Linking $target_path to $diff\n";
            symlink $diff, $target_path or App::Dotfiles::Error->throw("Cannot create symlink '$target_path' (pointing to '$diff'): $!");

            next ACTION;
        }

        if ( $task eq 'mkdir' ) {
            my $target_path = $home_path->child($target);

            print "Creating directory $target_path\n";
            mkdir $target_path or App::Dotfiles::Error->throw("Cannot create directory '$target_path': $!");

            next ACTION;
        }

        if ( $task eq 'move' ) {
            my $module_path        = path( $module->module_path );
            my $source_path        = $module_path;
            my $source_path_prefix = $module->source_path_prefix;
            if ( defined $source_path_prefix ) {
                $source_path = $source_path->child($source_path_prefix);
            }
            $source_path = $source_path->child($source);
            my $target_path = $home_path->child($target);

            # yes, this is link target and link source, which is the reverse
            # of what we are going to move. We will move from target to source

            print "Moving $target_path to $source_path\n";
            move( $target_path, $source_path ) or App::Dotfiles::Error->throw("Cannot move '$target_path' to '$source_path': $!");

            next ACTION;
        }

        if ( $task eq 'unlink' ) {
            my $target_path = $home_path->child($target);

            confess "internal error: unlink action for non-symlink '$target_path'" if !-l $target_path;

            print "Unlinking $target_path\n";
            unlink $target_path or App::Dotfiles::Error->throw("Cannot unlink '$target_path': $!");

            next ACTION;
        }

        confess "internal error: unknown action '$task'";
    }

    return;
}

sub _create_actions {
    my ($self) = @_;

    my $dirs  = $self->_dirs;
    my $links = $self->_links;

    my $runtime       = $self->runtime;
    my $home_path     = path( $runtime->home_path );
    my $dotfiles_path = path( $runtime->dotfiles_path )->realpath();

    my @actions;
    my %action;

  FITTING_RUN:
    while (1) {

      LINKABLE:
        for my $linkable ( sort keys %{$dirs}, keys %{$links} ) {
            confess "internal error: '_dirs' and '_links' both contain a '$linkable'" if exists $dirs->{$linkable} && exists $links->{$linkable};

            # skip actions that were already generated (affects only
            # subsequent iterations of the fitting loop)

            next LINKABLE if exists $action{$linkable};

            # We only have to check for conflicts if there is no action
            # planned for our parents. If there is something planned, it
            # must be a mkdir, maybe coubled with an unlink, otherwise we
            # would have seen a conflict in the planning phase.

            my $dir = path($linkable);
          PARENT_DIR:
            while ( ( $dir = $dir->parent() ) ne q{.} ) {

                if ( exists $action{$dir} ) {

                    # We don't have to check if we exist because '$dir' has an action planned

                    my $action = [ $linkable, exists $dirs->{$linkable} ? 'mkdir' : ( 'link', @{ $links->{$linkable} } ) ];
                    push @actions, $action;
                    $action{$linkable} = 1;

                    next LINKABLE;
                }
            }

            # checks are required, parent is not an action

            my $link_path = $home_path->child($linkable);

            if ( exists $dirs->{$linkable} ) {
                if ( -l $link_path ) {
                    if ( !$dotfiles_path->subsumes( $self->_read_first_link_and_realpath_nd($link_path) ) ) {
                        my $module = $dirs->{$linkable};
                        my $name   = $module->name;
                        App::Dotfiles::Error->throw("Linking module '$name' would cause conflicts: link target '$link_path' is a symlink that is not managed by us");
                    }

                    # the link is managed by us - we remove it and replace it with a dir
                    $action{$linkable} = 1;

                    push @actions, [ $linkable, 'unlink' ], [ $linkable, 'mkdir' ];

                    next LINKABLE;
                }

                if ( -d $link_path ) {
                    next LINKABLE;
                }

                if ( -e $link_path ) {
                    my $module = $dirs->{$linkable};
                    my $name   = $module->name;
                    App::Dotfiles::Error->throw("Linking module '$name' would cause conflicts: link target '$link_path' already exists");
                }

                my $action = [ $linkable, 'mkdir' ];
                push @actions, $action;
                $action{$linkable} = 1;

                next LINKABLE;
            }

            my ( $module, $source ) = @{ $links->{$linkable} };

            if ( -l $link_path ) {
                if ( !$dotfiles_path->subsumes( $self->_read_first_link_and_realpath_nd($link_path) ) ) {
                    my $name = $module->name;
                    App::Dotfiles::Error->throw("Linking module '$name' would cause conflicts: link target '$link_path' is a symlink that is not managed by us");
                }

                # the link is managed by us - we don't have to check this link again
                # and nothing can scheduled for below it
                $action{$linkable} = 1;

                my $module_path = path( $module->module_path );
                my $source_path = $module_path->child($source);

                my $diff = $source_path->relative( $link_path->parent );

                my $link_target = readlink $link_path or App::Dotfiles::Error("Could not read link '$link_path': $!");

                # If the link is correct, we don't need to change anything
                next LINKABLE if $link_target eq $diff;

                # Link is not correct but is managed by us
                push @actions, [ $linkable, 'unlink' ], [ $linkable, 'link', @{ $links->{$linkable} } ];

                next LINKABLE;
            }

            if ( -d $link_path ) {
                $self->_plan_directory( $module, $source );

                # restart
                next FITTING_RUN;
            }

            if ( -f $link_path ) {
                my $module_path = path( $module->module_path );
                my $source_path = $module_path->child($source);

                if ( ( -l $source_path ) || ( !-f $source_path ) ) {
                    my $name = $module->name;

                    App::Dotfiles::Error->throw("Linking module '$name' would cause conflicts: link target '$link_path' is a file but link source '$source_path' is not");
                }

                push @actions, [ $linkable, 'move', @{ $links->{$linkable} } ], [ $linkable, 'link', @{ $links->{$linkable} } ];
                $action{$linkable} = 1;

                next LINKABLE;
            }

            if ( -e $link_path ) {
                my $name = $module->name;
                App::Dotfiles::Error->throw("Linking module '$name' would cause conflicts: link target '$link_path' exists already");
            }

            my $action = [ $linkable, 'link', @{ $links->{$linkable} } ];
            push @actions, $action;
            $action{$linkable} = 1;

        }

        return \@actions;
    }

    confess 'internal error';
}

sub _plan_directory {
    my ( $self, $module, $path ) = @_;

    my $new_path = path( $module->target_path_prefix )->child($path);

    $self->_plan_directory_ignore_shift( $module, $new_path );
    return;
}

sub _plan_directory_content {
    my ( $self, $module, $path ) = @_;

    for my $new_link ( @{ $module->get_linkables($path) } ) {
        $self->_plan_link( $module, $new_link );
    }

    return;
}

sub _plan_directory_ignore_shift {
    my ( $self, $module, $path ) = @_;

    my $dirs  = $self->_dirs;
    my $links = $self->_links;

    return if exists $dirs->{$path};

    if ( !exists $links->{$path} ) {
        $dirs->{$path} = $module;
        return;
    }

    my ( $conflicting_module, $conflicting_path ) = @{ $links->{$path} };
    delete $links->{$path};
    $dirs->{$path} = $conflicting_module;
    $self->_plan_directory_content( $conflicting_module, $conflicting_path );

    return;
}

sub _plan_link {
    my ( $self, $module, $path ) = @_;

    my $dirs  = $self->_dirs;
    my $links = $self->_links;

    my $new_path = path( $module->target_path_prefix, $path );

    if ( exists $dirs->{$new_path} ) {
        $self->_plan_directory_content( $module, $path );
        return;
    }

    if ( exists $links->{$new_path} ) {
        my ( $conflicting_module, $conflicting_path ) = @{ $links->{$new_path} };
        $self->_plan_directory( $conflicting_module, $conflicting_path );
        $self->_plan_directory_content( $module, $path );
        return;
    }

    $links->{$new_path} = [ $module, $path ];

    return;
}

sub _read_first_link_and_realpath_nd {
    my ( $self, $file ) = @_;

    my $path = path($file);
    App::Dotfiles::Error->throw("File '$file' is not absolute")  if !$path->is_absolute();
    App::Dotfiles::Error->throw("File '$file' is not a symlink") if !-l $file;

    my $link_target = readlink $file or App::Dotfiles::Error->throw("Cannot resolve symlink '$file': $!");
    $link_target = path($link_target);
    $link_target = $link_target->is_absolute() ? $link_target : $path->sibling($link_target);

    if ( -l $link_target ) {

        # target is a symlink that points to a symlink
        #
        # Run realpath not on the symlink itself, but it's parent. Otherwise
        # we would resolve the symlink.
        return $link_target->parent()->realpath()->child( $link_target->basename() );
    }

    if ( -e $link_target ) {

        # target is a symlink that points to a non-symlink
        return $link_target->realpath();
    }

    # target is a symlink that point to a non-existing file
    #
    # Cut the link down until we have an existing file, resolve the existing
    # part and append the cut off pieces.
    my $invalid_part = path(q{.});
    while ( !-e $link_target ) {
        $invalid_part = path( $link_target->basename() )->child($invalid_part);
        $link_target  = $link_target->parent();
    }

    return $link_target->realpath->child($invalid_part);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Dotfiles::Linker

=head1 VERSION

Version 0.001

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/App-Dotfiles/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/App-Dotfiles>

  git clone https://github.com/skirmess/App-Dotfiles.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
