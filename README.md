# NAME

Getopt::Type::Tiny - Clean Getopt::Long wrapper with Type::Tiny support

# VERSION

version 0.01

# SYNOPSIS

```perl
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
```

# DESCRIPTION

This module is a thin wrapper around [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) that adds support for
[Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) type constraints. It is intended to be a clean and simple way to
parse command line options with type constraints.

# FUNCTIONS

## get\_opts

```perl
my %opts = get_opts(
    foo => { isa => Str },
    bar => { isa => Int, default => 42 },
    'verbose|v', # defaults to Bool
);
```

Parses the command line options and returns a hash of the parsed options. The
arguments to `get_opts` are a list of option specifications.

# OPTION SPECIFICATIONS

Option specifications are passed to `get_opts` as a list of key/value pairs. If no
option spec is passed, the option is assumed to be a boolean option:

```perl
my %options = get_opts(
);
```

- isa

    The `isa` key specifies the type constraint for the option. This can be any
    [Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard), [Types::Common::Numeric](https://metacpan.org/pod/Types%3A%3ACommon%3A%3ANumeric), or [Types::Common::String](https://metacpan.org/pod/Types%3A%3ACommon%3A%3AString)
    type.  If more complex types are needed, you can create your own type
    constraints with [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny).

- default

    The `default` key specifies the default value for the option. If the option is
    not present on the command line, this value will be used.

- rename

    The `rename` key specifies a new name for the option. The value of the option
    will be stored in the hash under this new name.

- required

    The `required` key specifies that the option is required. If the option is not
    present on the command line, an error will be thrown.

# HELP OPTIONS

By default, `get_opts` will add a `--help|?` and `man` options that use
[Pod::Usage](https://metacpan.org/pod/Pod%3A%3AUsage) to display the usage message and exit. The `--help` and `-?`
options will display a brief usage message and exit. The `--man` option will
display the full documentation and exit.

# LIMITATIONS

Currently, we do not natively support multi-valued options. You can use
[GetOpt::Long](https://metacpan.org/pod/GetOpt%3A%3ALong) style multi-valued options:

```perl
my %opt_for = get_opts(

    # default should be a subref to ensure we don't get the same arrayref
    # if this is called multiple times, but it's not strictly necessary
    # default => [] works if this is called only once
    'servers=s@' => { isa => ArrayRef [Str], default => sub { [] } },
);
```

And as called from the command line:

```perl
perl my_script.pl --servers=server1 --servers=server2 --servers=server3
```

# AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Curtis "Ovid" Poe.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
