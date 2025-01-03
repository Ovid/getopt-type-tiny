#!/usr/bin/env perl

use v5.20.0;
use feature 'postderef';
use Test::Most;
use PerlX::Maybe       qw(maybe);
use Getopt::Type::Tiny qw(get_opts ArrayRef Str Int Bool);

# Helper function to simulate command line arguments
sub with_args {
    my %arg_for = @_;
    local @ARGV = $arg_for{argv} ? $arg_for{argv}->@* : ();
    return get_opts( $arg_for{spec} ? $arg_for{spec}->@* : () );
}

my @test_cases = (
    'Basic functionality' => {
        argv => [ '--foo', 'test', '--bar', '42', '--baz' ],
        spec => [
            'foo' => { isa => Str },
            'bar' => { isa => Int },
            'baz',
        ],
        expected => {
            foo => 'test',
            bar => 42,
            baz => 1,
        },
    },
    'Default values' => {
        spec => [
            'foo' => { default => 'default_foo', isa => Str },
            'bar' => { default => 10,            isa => Int },
            'baz' => { default => 0 },
        ],
        expected => {
            foo => 'default_foo',
            bar => 10,
            baz => 0,
        },
    },
    'Required options' => {
        spec     => [ 'foo' => { required => 1, isa => Int } ],
        expected => qr/Required option 'foo' is missing/,
    },
    'Required option provided' => {
        argv     => [ '--foo', 'bar' ],
        spec     => [ foo => { required => 1, isa => Str } ],
        expected => { foo => 'bar' },
    },
    'Type checking' => {
        argv     => [ '--foo', 'not_an_int' ],
        spec     => [ 'foo' => { isa => Int } ],
        expected => qr/Invalid value for option 'foo'/,
    },
    'Renaming options' => {
        argv     => [ '--foo', 'test' ],
        spec     => [ 'foo' => { rename => 'bar', isa => Str } ],
        expected => { bar => 'test' },
    },
    'Boolean options' => {
        argv     => ['--foo'],
        spec     => ['foo'],        # Bool is the default type
        expected => { foo => 1 },
    },
    'Negated boolean options' => {
        argv     => ['--nofoo'],
        spec     => ['foo!'],
        expected => { foo => 0 },
    },
    'Multi-valued options' => {
        argv     => [ '--foo',  'bar', '--foo', 'baz' ],
        spec     => [ 'foo=s@', { isa => ArrayRef [Str] } ],
        expected => { foo => [ 'bar', 'baz' ] },
    },
    'Multi-valued options without options' => {
        argv     => [],
        spec     => [ 'foo=s@', { isa => ArrayRef [Str], default => sub { [] } } ],
        expected => { foo => [] },
    },
);

while ( my ( $test_name, $test_case ) = splice @test_cases, 0, 2 ) {
    subtest $test_name => sub {
        my @args = (
            maybe spec => $test_case->{spec},
            maybe argv => $test_case->{argv},
        );
        if ( 'Regexp' eq ref $test_case->{expected} ) {
            throws_ok(
                sub {
                    with_args(@args);
                },
                $test_case->{expected},
                'Error thrown'
            );
        }
        else {
            my %opts = with_args(@args);
            is_deeply(
                \%opts, $test_case->{expected},
                'Options parsed correctly'
            );
        }
    };
}

done_testing;
