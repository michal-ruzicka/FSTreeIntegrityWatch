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
use File::Spec;
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
    'stdin' => 0,
    'null' => 0,
    'recursive' => 0,
    'verify' => 1,
    'ext-attr-prefix' => 'extattr-file-integrity',
    'verbose' => 1,
};
my @opts_def = (
    '' => sub {$opts->{'stdin'} = 1},
    'null|0',
    'recursive|r!',
    'verify',
    'store|save|s' => sub {$opts->{'verify'} = 0},
    'dump-file|f=s',
    'dump-relative-to|relative-to|t:s',
    'algorithm|a=s@',
    'ext-attr-prefix|prefix|p=s',
    'batch-size|b=i',
    'verbose|v+',
    'quiet|q' => sub {$opts->{'verbose'} = 0},
    'help|h',
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


    if ($opts->{'verbose'} >= 1) {

        if (defined($msg)) {
            chomp $msg;
            print $out "$msg\n\n";
        }

        print $out join("\n\n",
            join("\n\t", 'Usage:',
                join(' ',
                     "$FindBin::Script",
                     "[ { --verify | --store|--save|-s } ]",
                     "[ --dump-file|-f path/to/dump_file.json ]",
                     "[ --dump-relative-to|--relative-to|-t [ path/to/dir/ ] ]",
                     "[ { --verbose|-v [ --verbose|-v ... ] | --quiet|-q } ]",
                     "[ --algorithm|-a hash_algorithm_name [ --algorithm|-a hash_algorithm_name ... ] ]",
                     "[ --ext-attr-prefix|--prefix|-p ext_attr_name_prefix ]",
                     "[ --batch-size|-b size ]",
                     "--",
                     "{ - | file [ file ... ] }",
                ),
                join(' ',
                     "$FindBin::Script",
                     "[--help|-h]",
                ),
            ),
            join("\n\t", 'Example:',
                join(' ',
                     "$FindBin::Script",
                     "--save",
                     "--verbose",
                     "-a SHA-256",
                     "-a CRC-64",
                     "--recursive",
                     "--",
                     "testdata/data/dir1/",
                     "testdata/data/file6",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--save",
                     "--dump-file testdata.json",
                     "-a CRC-64",
                     "-r",
                     "testdata/",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--save",
                     "--dump-file testdata.json",
                     "--dump-relative-to testdata/data/",
                     "-a CRC-64",
                     "-r",
                     "testdata/",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--dump-file testdata.json",
                     "--dump-relative-to testdata/data/",
                     "-a SHA-256",
                     "-a CRC-64",
                     "-r",
                     "testdata/",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--save",
                     "--dump-file testdata.json",
                     "--dump-relative-to",
                     "-a CRC-64",
                     "-r",
                     "testdata/",
                ),
                join(' ',
                     "$FindBin::Script",
                     "-a SHA-256",
                     "testdata/data/file6",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--verify",
                     "-vv",
                     "--prefix 'file-integrity'",
                     "-a SHA-256",
                     "--algorithm Whirlpool",
                     "-a CRC-64",
                     "testdata/data/dir1/file2",
                     "testdata/data/file6",
                ),
                join(' ',
                     "find testdata/ -type f -print0",
                     "|",
                     "$FindBin::Script",
                     "--store",
                     "-vv",
                     "--null",
                     "-a CRC-32",
                     "--batch-size 20",
                     "-",
                ),
                join(' ',
                     "$FindBin::Script",
                     "--help",
                ),
            ),
            join("\n\t", 'Options:',
                join("\t\n\t\t",
                     "{ - | file [ file ... ] }",
                     "List of file paths to work on.",
                     "If dash (`-') is used instead of file path, file paths will be read from the standard input in addition."),
                join("\t\n\t\t",
                     "-0, --null",
                     "If dash (`-') argument is used to read file paths from the standard input this option changes the file paths separator from the new line characted to the NULL byte.",
                     "Useful for handling `find some/path/ -print0' outputs."),
                join("\t\n\t\t",
                     "-r, --[no-]recursive",
                     "If enabled, directories in the file list will not be skiped but traversed recursively and found files will also be added to the list.",
                     "Default is `--no-recursive'."),
                join("\t\n\t\t",
                     "--",
                     "`End of options' indicator.",
                     "Any argument after will not be consider a configuration option even though it looks like one."),
                join("\t\n\t\t",
                     "--verify",
                     "Integrity verification mode – load checksums from the extended attributes of files and compare them with newly computed checksums on the files.",
                     "The verification is done only on existing extended attributes with matching name prefix (see `--ext-attr-prefix') using selected digest algorithm(s) (see `--algorithm').",
                     "Exit with non-zero exit value in case of any error is found.",
                     "Default mode of operation."),
                join("\t\n\t\t",
                     "-s, --save, --store",
                     "Integrity storing mode – computed checksums on the filesusing selected digest algorithm(s) (see `--algorithm') and save them to extended attributes of the files.",
                     "Selected digest algorithm(s) (see `--algorithm') and extended attributes name prefix (see `--ext-attr-prefix') are used.",
                     "Exit with non-zero exit value in case of any error."),
                join("\t\n\t\t",
                     "-f, --dump-file <path/to/dump_file.json>",
                     "Path to file in JSON format the computed checksums save to / read from.",
                     "Contents of the JSON integrity database is equivalent to contents of the extended attributes contents.",
                     "In integrity storing mode (see `--save'): computed data is stored to the dump file in addition to writing them to the extended attributes.",
                     "In integrity verification mode (see `--verify'): file checksums are read from the dump file instead of reading the extended attributes (useful for use with filesystem without extended attributes support)."),
                join("\t\n\t\t",
                     "-t, --relative-to, --dump-relative-to [ <path/to/dir/> ]",
                     "Directory path to read/write file paths in the dump file (see `--dump-file') relatively to.",
                     "Dir path specification is optional. If omitted the current working directory is used."),
                join("\t\n\t\t",
                     "-a, --algorithm <algorithm_name>",
                     "Use the particular digest algorithm.",
                     "Use this option multiple times to use multipe algorithms in parallel.",
                     "Default is 'SHA-256'."),
                join("\t\n\t\t",
                     "-p, --prefix, --ext-attr-prefix <ext_attr_prefix_string>",
                     "Prefix of names of filesystem extended attributes used to store the checksums of files.",
                     "Extended attribute names on the files are assembled as: <ext_attr_prefix_string>.<digest_algorithm_name>",
                     "Default is 'extattr-file-integrity'."),
                join("\t\n\t\t",
                     "-b, --batch-size",
                     "Defines processing batch size, i.e.",
                     "– the number of files the hash is computed from prior storing the checksums to their extended attributes,",
                     "– the number of files the hash is loaded from their extended attributes and verified against newly computed checksum prior processing next `batch-size' of files.",
                     "Use '0' to process all input files in a single batch or a positive integer to set exact batch size.",
                     "Default is '10'."),
                join("\t\n\t\t",
                     "-v, --verbose",
                     "Set verbosity level. Multiple uses of this option increase the detail of info messages.",
                     "level 1 (default): print warning and error messages",
                     "level 2: in addition print processing info messages",
                     "level 3: in addition print stack trace in case of errors",
                     "level 4: in addition print script configuration summary at start up"),
                join("\t\n\t\t",
                     "-q, --quiet",
                     "Silent mode. Sets verbosity level 0 discarding any info and error messages.",
                     "Non-zero exit value of the script indicates error."),
                join("\t\n\t\t",
                     "-h, --help",
                     "Print the usage info and exit."),
            ),
            join("\n\t",
                'Valid digest algorithms:',
                join(' ', sort keys %{FSTreeIntegrityWatch::Digest->algorithms()})
            )
        )."\n";

    }

    exit($exit_val);

}

# Check validity of provided arguments. In case of an error exit with help
# message.
sub check_options {

    # path argument of the `dump-relative-to' option is optional; if no argument
    # is specified use the current directory
    $opts->{'dump-relative-to'} = File::Spec->curdir()
            if (defined($opts->{'dump-relative-to'}) and $opts->{'dump-relative-to'} eq '');

    print_usage_and_exit() if ($opts->{'help'});
    print_usage_and_exit(2, 'No files to work on.') unless (scalar(@files) > 0);
    print_usage_and_exit(3, 'Invalid batch size: '.$opts->{'batch-size'})
            if (defined($opts->{'batch-size'}) and $opts->{'batch-size'} < 0);
    print_usage_and_exit(4, "Invalid directory path of the `--dump-relative-to' option: ".$opts->{'dump-relative-to'})
            if (defined($opts->{'dump-relative-to'}) and not -d $opts->{'dump-relative-to'});
}



#
# Main
#

# Check and process command line options.
try {

    # Parse command line.
    GetOptions ($opts, @opts_def)
        or print_usage_and_exit(1, "Error in command line arguments");

    @files = @ARGV; # Use file paths from the command line.
    if ($opts->{'stdin'}) { # Use file paths from STDIN in configured.
        my $orig_separator = $/;
        # Allow NULL separated strings if configured – useful for handling `find
        # some/dir/ -print0' outputs.
        $/ = "\0" if ($opts->{'null'});
        while (my $fp = <STDIN>) {
            chomp $fp;
            push(@files, $fp);
        }
        $/ = $orig_separator;
    }

    # Check the configuration.
    check_options();

} catch {
    if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
        die "$_\n";
    } else {
        die $_;
    }
};

# Setup FSTreeIntegrityWatch according to our configuration.
my $intw = FSTreeIntegrityWatch->new(
    'ext_attr_name_prefix' => $opts->{'ext-attr-prefix'},
    'files'                => [ @files ],
    'recursive'            => $opts->{'recursive'},
);
$intw->algorithms($opts->{'algorithm'}) if (defined($opts->{'algorithm'}));
$intw->batch_size($opts->{'batch-size'}) if (defined($opts->{'batch-size'}));
$intw->verbosity($opts->{'verbose'} > 2 ? 2 : $opts->{'verbose'});
$intw->exception_verbosity(1) if ($opts->{'verbose'} >= 3);

# Print internal configuration state in the very verbose mode.
if ($opts->{'verbose'} >= 4) {
    print STDERR join("\n\t",
                      'Options:',
                      map {
                          sprintf("'%s': '%s'",
                                  $_,
                                  ref ($opts->{$_}) eq 'ARRAY'
                                    ? join(', ', @{$opts->{$_}})
                                      : $opts->{$_})
                      } sort keys %$opts)."\n";
    print STDERR join("\n\t", 'File paths entered by the user:', sort @files)."\n";
    print STDERR join("\n\t", 'File paths to work with:', sort @{$intw->files()})."\n";
    print STDERR "\n";
}

my $rv = 0;
try {
    # Mode of operation – verify existing saved checksums or save the current
    # state?
    if ($opts->{'verify'}) { # Verification mode

        my $dfc;
        if (defined($opts->{'dump-file'})) {
            $dfc = $intw->verify_checksums($opts->{'dump-file'}, $opts->{'dump-relative-to'});
        } else {
            $dfc = $intw->verify_checksums();
        }

        if (scalar(keys %$dfc) > 0) {
            # Exit with error exit code only in case of error, warnings are OK.
            $rv = sum(map { exists($dfc->{$_}->{'error'}) ? 1 : 0 } keys %$dfc) > 0 ? 1 : 0;
            # Print verification errors and warnings unless in silent mode.
            # Otherwise script exit value is error state indication.
            if ($opts->{'verbose'} >= 1) {
                foreach my $filename (sort keys %$dfc) {
                    foreach my $alg (sort keys %{$dfc->{$filename}->{'error'}}) {
                        my $ecsum    = $dfc->{$filename}->{'error'}->{$alg}->{'expected_checksum'};
                        my $ecsum_ts = $dfc->{$filename}->{'error'}->{$alg}->{'expected_checksum_stored_at'};
                        my $ccsum    = $dfc->{$filename}->{'error'}->{$alg}->{'computed_checksum'};
                        printf STDERR "File corruption detected: file '%s' – algorithm '%s' – expected checksum '%s' (stored at '%s') – current checksum '%s'\n",
                                      $filename, $alg, $ecsum, $ecsum_ts, $ccsum;
                    }
                    foreach my $alg (sort keys %{$dfc->{$filename}->{'warning'}}) {
                        my $msg = $dfc->{$filename}->{'warning'}->{$alg}->{'message'};
                        printf STDERR "File integrity verification warning: file '%s' – %s\n",
                                      $filename, $msg;
                    }
                }
            }
        }

    } else { # Save mode

        $intw->store_checksums();
        $intw->dump_stored_attrs_as_json_to_file($opts->{'dump-file'},
                                                 $opts->{'dump-relative-to'}) if (defined($opts->{'dump-file'}));

    }
} catch {
    if ($opts->{'verbose'} >= 1) {
        if ( blessed $_ && $_->isa('FSTreeIntegrityWatch::Exception') ) {
            die "$_\n";
        } else {
            die $_;
        }
    } else {
        exit($rv == 0 ? 1 : $rv);
    }
};

exit($rv);


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
