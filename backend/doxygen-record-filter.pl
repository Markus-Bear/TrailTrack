#!/usr/bin/env perl
# Doxygen input filter: Doxygen does not parse Java records, so each record
# header is shown to it as a class. The components are dropped (they are
# described by the record's @param tags) and their line breaks kept, so line
# numbers still match the source.
local $/;
my $src = <>;
$src =~ s/\brecord(\s+[A-Z]\w*)\s*(\((?:[^()]++|(?-1))*\))/"class$1 " . ("\n" x ($2 =~ tr{\n}{}))/ge;
print $src;
