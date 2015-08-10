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
use Getopt::Long qw(:config gnu_getopt no_ignore_case bundling);
use List::Util qw(sum);
use Scalar::Util qw(blessed);
use Try::Tiny;

# Local FSTreeIntegrityWatch package modules
use FindBin;
use lib "$FindBin::Bin/lib/";
use FSTreeIntegrityWatch;



#
# Global configuration
#
my @files = ();
my $opts = {
    'verbose' => 1,
    'ext-attr-prefix' => 'extattr-file-integrity',
    'verify' => 1,
};
my @opts_def = (
    'help|h',
    'verbose|v!',
    'algorithm|a=s@',
    'ext-attr-prefix|prefix|p=s',
    'store|save|s' => sub {$opts->{'verify'} = 0},
    'verify',
);


#
# Subroutines
#

# Print script usage and exit.
# args
#   optional: exit value
#   optional: error message
sub print_usage_and_exit {

    my ($exit_val, $msg) = @_;

    $exit_val = 0 unless(defined($exit_val));
    my $out = \*STDERR;

    if (defined($msg)) {
        chomp $msg;
        print $out "$msg\n\n";
    }

    print $out  join("\n\t", 'Usage:',
                join(' ',
                     "$FindBin::Script",
                     "[ { --verify | --store|--save|-s } ]",
                     "[ --[no-]verbose|-v ]",
                     "[ --algorithm|-a hash_algorithm_name [ --algorithm|-a hash_algorithm_name ... ] ]",
                     "[ --ext-attr-prefix|--prefix|-p ext_attr_name_prefix ]",
                     "file [ file ... ]"
                ),
                join(' ',
                     "$FindBin::Script",
                     "[--help|-h]",
                ))."\n";
    print $out  join("\n\t", 'Example:',
                join(' ',
                     "$FindBin::Script",
                     "--save",
                     "-a SHA-256",
                     "-a CRC-64",
                     "testdata/data/dir1/file2",
                     "testdata/data/file6",
                ),
                join(' ',
                     "$FindBin::Script",
                     "-a SHA-256",
                     "testdata/data/file6",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--verify",
                     "-v",
                     "--prefix 'file-integrity'",
                     "-a SHA-256",
                     "--algorithm Whirlpool",
                     "-a CRC-64",
                     "testdata/data/dir1/file2",
                     "testdata/data/file6",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--help",
                ))."\n";

    print $out "\n".join("\n\t", 'Valid hash algorithms:',
                        join(' ', sort keys %{FSTreeIntegrityWatch::Digest->algorithms()})
                    )."\n";


    exit($exit_val);

}

# Check validity of provided arguments. In case of an error exit with help
# message.
sub check_options {
    print_usage_and_exit() if ($opts->{'help'});
    print_usage_and_exit(2, 'No files to work on.') unless (scalar(@files) > 0);
}



#
# Main
#
try {
    GetOptions ($opts, @opts_def)
        or print_usage_and_exit(1, "Error in command line arguments");
    @files = @ARGV;
    check_options();
} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        die "$_\n";
    } else {
        die $_;
    }
};

my $intw = FSTreeIntegrityWatch->new(
    'exception_verbosity'  => $opts->{'verbose'},
    'ext_attr_name_prefix' => $opts->{'ext-attr-prefix'},
    'files'                => [ @files ],
);
$intw->algorithms($opts->{'algorithm'}) if (defined($opts->{'algorithm'}));

my $rv = 0;
try {
    # Mode of operation – verify existing saved checksums or save the current
    # state?
    if ($opts->{'verify'}) {
        my $dfc = $intw->verify_checksums();
        if (scalar(keys %$dfc) > 0) {
            # Exit with error exit code only in case of error, warning are OK.
            $rv = sum(map { exists($dfc->{$_}->{'error'}) ? 1 : 0 } keys %$dfc) > 0 ? 1 : 0;
            foreach my $filename (sort keys %$dfc) {
                foreach my $alg (sort keys %{$dfc->{$filename}->{'error'}}) {
                    my $ecsum = $dfc->{$filename}->{'error'}->{$alg}->{'expected_checksum'};
                    my $ccsum = $dfc->{$filename}->{'error'}->{$alg}->{'computed_checksum'};
                    printf STDERR "File corruption detected: file '%s' – algorithm '%s' – expected checksum '%s' – current checkum '%s'\n",
                                  $filename, $alg, $ecsum, $ccsum;
                }
                foreach my $alg (sort keys %{$dfc->{$filename}->{'warning'}}) {
                    my $msg = $dfc->{$filename}->{'warning'}->{$alg}->{'message'};
                    printf STDERR "File integrity verification warning: file '%s' – %s\n",
                                  $filename, $msg;
                }
            }
        }
    } else {
        $intw->store_checksums();
    }
} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        die "$_\n";
    } else {
        die $_;
    }
};

exit($rv);


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
