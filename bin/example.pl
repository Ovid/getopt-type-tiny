#!/usr/bin/env perl

use v5.40.0;
use lib 'lib';
use Getopt::Type::Tiny qw(get_opts Str Int);
use Data::Printer;

unless (@ARGV) {
    @ARGV = qw(--foo value_of_foo --bar 12 --verbose);
}

my %options = get_opts(
    foo => { isa => Str },
    bar => { isa => Int, default => 42 },
    'verbose|v',    # defaults to Bool
);
p %options;

__END__

=head1 DESCRIPTION

This is a simple example of how to use Getopt::Type::Tiny to parse command line
options;

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
    #    help    => 0,
    # )

=head1 FUNCTIONS

No functions;
