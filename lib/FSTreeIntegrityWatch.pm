
package FSTreeIntegrityWatch;

use strict;
use warnings;
use utf8;


# Package modules
use FSTreeIntegrityWatch::Digest;
use FSTreeIntegrityWatch::Exception;
use FSTreeIntegrityWatch::ExtAttr;

# External modules
use feature qw(say);
use File::Find::utf8;
use File::Spec;
use JSON;
use List::Compare;
use List::MoreUtils qw(uniq);
use Try::Tiny;


# Use Class::Tiny for class construction.
use subs 'exception_verbosity'; # Necessary to provide our own 'exception_verbosity' accessor.
use subs 'verbosity'; # Necessary to provide our own 'verbosity' accessor.
use subs 'files'; # Necessary to provide our own 'files' accessor.
use subs 'recursive'; # Necessary to provide our own 'recursive' accessor.
use Class::Tiny {
    'exception_verbosity'      => 0,
    'verbosity'                => 0,
    'ext_attr_name_prefix'     => 'extattr-file-integrity',
    'algorithms'               => [ "SHA-256" ],
    'files'                    => [ ],
    'recursive'                => 0,
    'checksums'                => {},
    'stored_ext_attrs'         => {},
    'loaded_ext_attrs'         => {},
    'detected_file_corruption' => {},
};



# Constructor hook validates parameters.
sub BUILD {

    my ($self, $args) = @_;

    $self->exception_verbosity($self->{'exception_verbosity'}) if (defined($self->{'exception_verbosity'}));
    $self->verbosity($self->{'verbosity'}) if (defined($self->{'verbosity'}));
    $self->files($self->{'files'}) if (defined($self->{'files'}));

}

# Enable/disable stack trace as part of the standard exception error message.
# args
#   1 or 0 (default) to enable/disable stack trace in exception error messages
# throws
#   FSTreeIntegrityWatch::Exception::Config in case of an invalid argument
sub exception_verbosity {

    my $self = shift @_;

    if (@_) {

        my $value = shift @_;

        if ($value =~ /^[0-1]$/) {
            $FSTreeIntegrityWatch::Exception::exception_verbosity = $value;
            return $self->{'exception_verbosity'} = $value;
        } else {
            my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
            $self->{'exception_verbosity'} = $defaults->{'exception_verbosity'};
            $self->exp('Config', "Invalid 'exception_verbosity' configuration value, use '0' or '1'.");
        }

    } elsif ( exists $self->{'exception_verbosity'} ) {

        return $self->{'exception_verbosity'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'exception_verbosity'} = $defaults->{'exception_verbosity'};

    }

}

# Set/get verbosity of info prints during processing.
# args
#   int >= 0 set verbosity level
#     level 0 (default): no printing, exceptions with included error messages are thrown
#     level 1: print processing warning and error messages
#     level 2: in addition print processing info messages
# throws
#   FSTreeIntegrityWatch::Exception::Config in case of an invalid argument
sub verbosity {

    my $self = shift @_;

    if (@_) {

        my $value = shift @_;

        if ($value =~ /^[0-2]$/) {
            return $self->{'verbosity'} = $value;
        } else {
            my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
            $self->{'verbosity'} = $defaults->{'verbosity'};
            $self->exp('Config', "Invalid 'verbosity' configuration value, use integer between '0' and '2'.");
        }

    } elsif ( exists $self->{'verbosity'} ) {

        return $self->{'verbosity'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'verbosity'} = $defaults->{'verbosity'};

    }

}

# Set/get list of files to work on. Duplicate entries are eliminated from the
# list.
# args
#   array ref of file paths to work on
sub files {

    my $self = shift @_;

    if (@_) {

        my $files = shift @_;

        @$files = map { File::Spec->canonpath(File::Spec->rel2abs($_)) } @$files;

        if ($self->{'recursive'}) {
            my $find_dirs = [];
            foreach my $f (@$files) {
                push(@$find_dirs, $f) if (-d $f);
            }
            my $find_files = [];
            find({ follow => 1,
                   no_chdir => 1,
                   wanted => sub {
                       push(@$find_files,
                            File::Spec->canonpath(File::Spec->rel2abs($File::Find::name)))
                   }
                 }, @$find_dirs) if (scalar(@$find_dirs) > 0);
            push(@$files, @$find_files);
        }

        @$files = uniq sort @$files;

        return $self->{'files'} = $files;

    } elsif ( exists $self->{'files'} ) {

        return $self->{'files'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'files'} = $defaults->{'files'};

    }

}

# Set/get directory behaviour.
# args
#   0 (default) to skip directories in the list of file path to work on or
#   1 to traverse directories recursively and add found files to the list of
#     file paths to work on
# throws
#   FSTreeIntegrityWatch::Exception::Config in case of an invalid argument
sub recursive {

    my $self = shift @_;

    if (@_) {

        my $value = shift @_;

        if ($value =~ /^[01]$/) {
            return $self->{'recursive'} = $value;
        } else {
            my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
            $self->{'recursive'} = $defaults->{'1rbosity'};
            $self->exp('Config', "Invalid 'recursive' configuration value, use '0' or '1'.");
        }

    } elsif ( exists $self->{'recursive'} ) {

        return $self->{'recursive'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'recursive'} = $defaults->{'recursive'};

    }

}

# Throw some of the FSTreeIntegrityWatch::Exception exceptions following
# exception verbosity setting.
# args
#   exception type, i.e. FSTreeIntegrityWatch::Exception::$type
#     or undef to throw generic FSTreeIntegrityWatch::Exception.
#   exception throw() arguments
sub exp {

    my $self = shift @_;
    my $type = shift @_;
    my @args = @_;

    # If only one argument is given it is an error message.
    @args = ('message' => $args[0]) if (scalar(@args) == 1);
    # Force the use of our show stack trace setting.
    push(@args, show_trace => $self->exception_verbosity());

    # Throw exception of requested type.
    my $class = 'FSTreeIntegrityWatch::Exception'.(defined($type) ? "::$type" : '');

    $class->throw(@args);

}

# Print processing warning message if the current verbosity level instructs us
# to do so.
# args
#   message to print
sub print_warning {

    my $self = shift @_;
    my $msg = shift @_;

    chomp $msg;

    say STDERR "$msg" if ($self->verbosity >= 1);

}

# Print processing info message if the current verbosity level instructs us to
# do so.
# args
#   message to print
sub print_info {

    my $self = shift @_;
    my $msg = shift @_;

    chomp $msg;

    say "$msg" if ($self->verbosity >= 2);

}

# For $self->files() computes their checksums using all the $self->algorithms()
# and stores the results to the extended attributes of the files.
# returns
#   stored_ext_attrs hash ref of the used context
# throws
#   FSTreeIntegrityWatch::Exception or their subclasses in case of errors during
#   processing.
sub store_checksums {

    my $self = shift @_;

    $self->print_info("Storing checksums...");

    my $digest  = FSTreeIntegrityWatch::Digest->new($self);
    my $extattr = FSTreeIntegrityWatch::ExtAttr->new($self);

    $digest->compute_checksums();
    my $scsum = $extattr->store_checksums();

    $self->print_info("Storing checksums done.");

    return $scsum;

}

# For $self->files() loads their saved checksums from the extended attributes.
# returns
#   loaded_ext_attrs hash ref of the used context
# throws
#   FSTreeIntegrityWatch::Exception or their subclasses in case of errors during
#   processing.
sub load_checksums {

    my $self = shift @_;

    $self->print_info("Loading checksums...");

    my $extattr = FSTreeIntegrityWatch::ExtAttr->new($self);
    my $lcsums = $extattr->load_checksums();

    $self->print_info("Loading checksums done.");

    return $lcsums;

}

# For $self->files() loads their saved checksums from the extended attributes,
# recalculates the checksums using $self->algorithms() and compare the loaded
# checksums with the newly computed checksums.
# returns
#   detected_file_corruption hash ref of the used context
# throws
#   FSTreeIntegrityWatch::Exception or their subclasses in case of errors during
#   processing.
sub verify_checksums {

    my $self = shift @_;

    $self->print_info("Verifying checksums...");

    my $dfc = $self->detected_file_corruption();

    try {
        my $extattr = FSTreeIntegrityWatch::ExtAttr->new($self);
        my $loaded_checksums = $extattr->load_checksums();

        # It is not necessary to computed checksums for files/algorithm we do
        # not know the previous values to compare with. Thus, prepare a new
        # context containing only these files and filters current algorithms to
        # the ones used on these files.
        my @used_files = ();
        my $used_algs = {};
        foreach my $filepath (keys %$loaded_checksums) {
            push(@used_files, $filepath);
            foreach my $alg (keys %{$loaded_checksums->{$filepath}}) {
                $used_algs->{$alg}++;
            }
        }
        my $lc = List::Compare->new([keys %$used_algs], $self->algorithms());
        my @used_algorithms = $lc->get_intersection();
        my $digest_ctx = FSTreeIntegrityWatch->new(
            'exception_verbosity'  => $self->exception_verbosity(),
            'verbosity'            => $self->verbosity(),
            'ext_attr_name_prefix' => $self->ext_attr_name_prefix(),
            'files'                => [ @used_files ],
            'algorithms'           => [ @used_algorithms ],
        );
        my $digest = FSTreeIntegrityWatch::Digest->new($digest_ctx);
        my $computed_checksums = $digest->compute_checksums();

        foreach my $filename (sort keys %$loaded_checksums) {
            foreach my $alg (sort keys %{$loaded_checksums->{$filename}}) {

                my $attr_value = from_json($loaded_checksums->{$filename}->{$alg}->{'attr_value'});
                my $lcsum      = $attr_value->{'checksum'};
                my $lcsum_time = $attr_value->{'storedAt'};

                if (exists($computed_checksums->{$filename}->{$alg})) {

                    my $ccsum = $computed_checksums->{$filename}->{$alg}->{'checksum_value'};

                    unless ($lcsum eq $ccsum) {
                        $dfc->{$filename}->{'error'}->{$alg}->{'verified_at'}       = time;
                        $dfc->{$filename}->{'error'}->{$alg}->{'expected_checksum'} = $lcsum;
                        $dfc->{$filename}->{'error'}->{$alg}->{'computed_checksum'} = $ccsum;
                        $dfc->{$filename}->{'error'}->{$alg}->{'expected_checksum_stored_at'} = $lcsum_time;
                    }

                } else {

                    $dfc->{$filename}->{'warning'}->{$alg}->{'message'}
                        = sprintf("Unknown algorithm '%s', checksum '%s' not verified.",
                                  $alg, $lcsum);

                }

            }
        }
    } catch {
        $self->exp(undef, "Verification of checksums failed: $_");
    };

    $self->print_info("Verifying checksums done.");

    return $dfc;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
