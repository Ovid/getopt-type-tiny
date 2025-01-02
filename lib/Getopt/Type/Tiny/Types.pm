package Getopt::Type::Tiny::Types;

# ABSTRACT: No user-serviceable parts inside

use strict;
use warnings;
use Type::Library -base;
use Type::Utils -all;

our @EXPORT_OK;

BEGIN {
    extends qw(
      Types::Standard
      Types::Common::Numeric
      Types::Common::String
    );
    @EXPORT_OK = grep {/\A[[:upper:]]/} (
        Types::Standard->type_names,
        Types::Common::Numeric->type_names,
        Types::Common::String->type_names,
    );
}

__END__

=head1 DESCRIPTION

This module is merely intended to provide core types to our getopts wrapper.
It is not intended to be used directly.
