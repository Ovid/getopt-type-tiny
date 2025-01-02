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
        my $getopt_spec = shift @arg_specs;
        my $options     = ref $arg_specs[0] eq 'HASH' ? shift @arg_specs : {};

        my ($name) = $getopt_spec =~ /^([\w_]+)/;

        if ( exists $options->{isa} ) {
            $types{$name} = $options->{isa};

            # if they've specified a type and the option spec has =\w at the
            # end, replace it with =s to allow us to handle the type check
            # rather than the limited facilities of Getopt::Long
            $getopt_spec =~ s/=[a-z]$/=s/;
        }
        push @getopt_specs, $getopt_spec;

        $defaults{$name} = $options->{default} if exists $options->{default};
        $renames{$name}  = $options->{rename}  if exists $options->{rename};
        $required{$name} = $options->{required}
          if exists $options->{required};

        # If no type is specified and the option doesn't have =s or =i,
        # assume Bool
        $types{$name} //= Bool unless $getopt_spec =~ /=/;
    }

    push @getopt_specs, 'help|?';

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
            croak( "Invalid value for option '$name': " . $type->get_message( $opt_for{$name} ) );
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
        'foo=s' => { isa => Str },
        'bar=i' => { isa => Int },
        'verbose|v', # defaults to Bool
    );

=head1 DESCRIPTION
