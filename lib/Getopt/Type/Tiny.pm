package Getopt::Type::Tiny;

# ABSTRACT: Clean Getopt::Long wrapper with Type::Tiny support

use v5.20.0;
use warnings;
use experimental 'signatures';

# this is very sloppy, pulling in all type names,
# but it makes them re-exportable via our @EXPORT_OK
use Getopt::Type::Tiny::Types qw(:all);
use Getopt::Long 'GetOptionsFromArray';
use Pod::Usage qw(pod2usage);
use Carp       qw(croak);
use Ref::Util  qw(is_coderef);
use parent 'Exporter';

our $VERSION = '0.01';

our @EXPORT_OK = (
    qw(get_opts),
    @Getopt::Type::Tiny::Types::EXPORT_OK
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub get_opts (@arg_specs) {

    # forces Carp to ignore this package
    local $Carp::Internal{ +__PACKAGE__ } = 1;
    my %opt_for;         # store the options
    my @getopt_specs;    # the option specs
    my %defaults;        # default values
    my %renames;         # rename option keys
    my %types;           # type constraints
    my %required;        # required options

    while (@arg_specs) {
        my $this_getopt_spec = shift @arg_specs;
        my $options = ref $arg_specs[0] eq 'HASH' ? shift @arg_specs : {};

        my ($name) = $this_getopt_spec =~ /^([\w_]+)/;

        if ( exists $options->{isa} ) {
            $types{$name} = $options->{isa};

            # if they've specified a type and the option spec has =\w at the
            # end, replace it with =s to allow us to handle the type check
            # rather than the limited facilities of Getopt::Long
            if ( $this_getopt_spec =~ s/=[a-z]$/=s/ ) {

                # do nothing
            }
            elsif ($types{$name}->name ne 'Bool'
                && $this_getopt_spec !~ /=/ )
            {
                $this_getopt_spec .= '=s';
            }
        }
        push @getopt_specs, $this_getopt_spec;

        if ( exists $options->{default} && exists $options->{required} ) {
            croak(
                "Option '$name' cannot be both required and have a default value"
            );
        }
        if ( exists $options->{default} ) {
            $defaults{$name} = $options->{default};
            if ( is_coderef( $options->{default} ) ) {
                $defaults{$name} = $options->{default}->();
            }
        }
        $renames{$name}  = $options->{rename} if exists $options->{rename};
        $required{$name} = $options->{required}
          if exists $options->{required};

        # If no type is specified and the option doesn't have =s or =i,
        # assume Bool
        $types{$name} //= Bool unless $this_getopt_spec =~ /=/;
    }

    # this has proven so incredibly useful that it's now a default,
    # but perhaps it should be optional. Will need to think of the cleanest
    # interface for that.
    push @getopt_specs, 'help|?';
    push @getopt_specs, 'man';

    # Note: this will mutate @ARGV if any options are present
    my $result = GetOptionsFromArray( \@ARGV, \%opt_for, @getopt_specs );

    if ( $opt_for{help} ) {
        pod2usage(1);
    }

    if ( $opt_for{man} ) {
        pod2usage( -exitval => 0, -verbose => 2 );
    }

    unless ($result) {
        croak( pod2usage(2) );
    }

    # Apply defaults
    for my $name ( keys %defaults ) {
        $opt_for{$name} = $defaults{$name} unless exists $opt_for{$name};
    }

    # Type checking
    for my $name ( keys %types ) {
        my $type = $types{$name};
        if ( exists $opt_for{$name} && !$type->check( $opt_for{$name} ) ) {
            croak( "Invalid value for option '$name': "
                  . $type->get_message( $opt_for{$name} ) );
        }
    }

    # Check required options
    for my $name ( keys %required ) {
        if ( $required{$name} && !exists $opt_for{$name} ) {
            croak("Required option '$name' is missing");
        }
    }

    # Rename keys
    for my $name ( keys %renames ) {
        $opt_for{ $renames{$name} } = delete $opt_for{$name}
          if exists $opt_for{$name};
    }

    return %opt_for;
}
1;

__END__

=head1 SYNOPSIS

    use Getopt::Type::Tiny qw(get_opts Str Int);
    my %opts = get_opts(
        foo => { isa => Str },
        bar => { isa => Int, default => 42 },
        'verbose|v', # defaults to Bool
    );
    
    # %opts now contains the parsed options:
    # (
    #    foo     => 'value of foo',
    #    bar     => 42,
    #    verbose => 1,
    # )    

=head1 DESCRIPTION

This module is a thin wrapper around L<Getopt::Long> that adds support for
L<Type::Tiny> type constraints. It is intended to be a clean and simple way to
parse command line options with type constraints.

=head1 FUNCTIONS

=head2 get_opts

    my %opts = get_opts(
        foo => { isa => Str },
        bar => { isa => Int, default => 42 },
        'verbose|v', # defaults to Bool
    );

Parses the command line options and returns a hash of the parsed options. The
arguments to C<get_opts> are a list of option specifications.

=head1 OPTION SPECIFICATIONS

Option specifications are passed to C<get_opts> as a list of key/value pairs. If no
option spec is passed, the option is assumed to be a boolean option:

    my %options = get_opts(
    );

=over 4

=item isa

The C<isa> key specifies the type constraint for the option. This can be any
L<Types::Standard>, L<Types::Common::Numeric>, or L<Types::Common::String>
type.  If more complex types are needed, you can create your own type
constraints with L<Type::Tiny>.

=item default

The C<default> key specifies the default value for the option. If the option is
not present on the command line, this value will be used.

=item rename

The C<rename> key specifies a new name for the option. The value of the option
will be stored in the hash under this new name.

=item required

The C<required> key specifies that the option is required. If the option is not
present on the command line, an error will be thrown.

=back

=head1 HELP OPTIONS

By default, C<get_opts> will add a C<--help|?> and C<man> options that use
L<Pod::Usage> to display the usage message and exit. The C<--help> and C<-?>
options will display a brief usage message and exit. The C<--man> option will
display the full documentation and exit.

=head1 LIMITATIONS

Currently, we do not natively support multi-valued options. You can use
L<GetOpt::Long> style multi-valued options:

   my %opt_for = get_opts(

       # default should be a subref to ensure we don't get the same arrayref
       # if this is called multiple times, but it's not strictly necessary
       # default => [] works if this is called only once
       'servers=s@' => { isa => ArrayRef [Str], default => sub { [] } },
   );

And as called from the command line:

    perl my_script.pl --servers=server1 --servers=server2 --servers=server3
