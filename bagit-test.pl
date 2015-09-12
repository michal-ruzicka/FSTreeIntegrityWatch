#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# Set encoding translation according to system locale.
use Encode;
use Encode::Locale;
if (-t) {
    binmode(STDIN,  ":encoding(console_in)");
    binmode(STDOUT, ":encoding(console_out)");
    binmode(STDERR, ":encoding(console_out)");
} else {
    binmode(STDIN,  ":encoding(locale)");
    binmode(STDOUT, ":encoding(locale)");
    binmode(STDERR, ":encoding(locale)");
}
Encode::Locale::decode_argv(Encode::FB_CROAK);


# External modules
use FindBin;
use IPC::Open3;



#
# Global configuration
#
my $bagit_py = "$FindBin::Bin/lib/bagit-python/bagit.py";
my $bagit_valid_dir = 'testdata/bagit/plain-dir/photodkf-54936/';
my $bagit_invalid_dir = 'testdata/bagit/invalid-plain-dir/photodkf-54936/';



#
# Main
#
foreach my $dir ($bagit_valid_dir, $bagit_invalid_dir) {

    print "#\n# Processing '$dir':\n#\n";

    my ($bagit_py_rv, $bagit_py_out, $bagit_py_err, $bagit_py_sum_msg);
    my $pid = open3(\*BAGIT_PY_IN, \*BAGIT_PY_OUT, \*BAGIT_PY_ERR,
                    "$bagit_py",
                    '--validate', "$dir");
    close(BAGIT_PY_IN);
    $bagit_py_out .= $_ while(<BAGIT_PY_OUT>);
    while(<BAGIT_PY_ERR>) {
        $bagit_py_err .= $_;
        $bagit_py_sum_msg = $_;
    }
    waitpid($pid, 0);
    $bagit_py_rv = $? >> 8;

    chomp $bagit_py_sum_msg;
    $bagit_py_sum_msg =~ s/^.*? is ((in)?valid(:|$).*)$/$1/g;

    print "RETURN VALUE: $bagit_py_rv\n";
    print "RESULT SUMMARY: $bagit_py_sum_msg\n";
    if (defined($bagit_py_out)) {
        chomp $bagit_py_out;
        print "STDOUT:\n$bagit_py_out\n";
    }
    if (defined($bagit_py_err)) {
        chomp $bagit_py_err;
        print "STDERR:\n$bagit_py_err\n";
    }

}


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
