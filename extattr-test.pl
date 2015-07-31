#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Basename;
use File::ExtAttr ':all';
use File::Spec;

binmode(STDIN,  "utf8");
binmode(STDOUT, "utf8");
binmode(STDERR, "utf8");


#
# Global configuration
#
my $file = 'testdata/data/file6';


#
# Main
#
$file = File::Spec->canonpath(File::Spec->rel2abs(File::Spec->catpath(dirname($0), $file)));

print "Working on file: '$file'\n";

print "\n";

# Manipulate the extended attributes of files.
my ($a, $v) = ('myTestExtAttrName', 'My test ExtAttr value.');
print "Setting extended attribute '$a' to '$v'.\n";
setfattr($file, $a, $v)
    or warn "$!";

print "\n";

# List attributes in the default namespace.
print "Attributes in the default namespace:\n";
foreach my $attr (listfattr($file)) {
    my $value = getfattr($file, $attr);
    print "\t'$attr' : '$value'\n";
}

print "\n";

# Examine attributes in a namespace-aware manner.
print "Attributes per namespaces:\n";
my @namespaces = listfattrns($file);
foreach my $ns (@namespaces) {
    print "\tin namespace '$ns':\n";
    my @attrs = listfattr($file, { namespace => $ns });
    foreach my $attr (@attrs) {
        my $value = getfattr($file, $attr);
        print "\t\t'$attr' : '$value'\n";
    }
}

print "\n";

print "Deleting extended attribute '$a' from '$file'.\n";
delfattr($file, $a)
    or warn "$!";
