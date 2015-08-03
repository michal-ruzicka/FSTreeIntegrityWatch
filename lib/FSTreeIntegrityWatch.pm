
package FSTreeIntegrityWatch;

use strict;
use warnings;
use utf8;


# Package modules
use FSTreeIntegrityWatch::Digest qw(:standard);
use FSTreeIntegrityWatch::ExtAttr qw(:standard);


# Use Class::Tiny for class construction.
use subs 'exception_verbosity'; # Necessary to provide our own accessor.
use Class::Tiny {
    'exception_verbosity' => 0,
    'algorithms' => [ "SHA-1" ],
    'files' => [ ],
};



# Constructor hook validates parameters.
sub BUILD {

    my ($self, $args) = @_;

    $self->exception_verbosity($self->{'exception_verbosity'}) if (defined($self->{'exception_verbosity'}));

}

# Enable/disable stack trace as part of the standard exception error message.
# args
#   1 or 0 (default) to enable/disable stack trace in exception error messages
# throws
#   FSTreeIntegrityWatch::Exception::Configuration in case of an invalid
#                                                  argument
sub exception_verbosity {

    my $self = shift @_;

    if (@_) {

        my $value = shift @_;

        if ($value =~ /^[10]$/) {
            $FSTreeIntegrityWatch::Exception::exception_verbosity = $value;
            return $self->{'exception_verbosity'} = $value;
        } else {
            my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
            $self->{'exception_verbosity'} = $defaults->{'exception_verbosity'};
            $self->exp('Config', "Invalid parameter, use '0' or '1'.");
        }

    } elsif ( exists $self->{'exception_verbosity'} ) {

        return $self->{'exception_verbosity'};

    } else {

        my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
        return $self->{'exception_verbosity'} = $defaults->{'exception_verbosity'};

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

# For $self->files() computes their checksums using all the $self->algorithms()
# and stores them to the extended attributes of the files.
# returns
#   hash ref with results formatted as follows
#   {
#     'file/path1' => {
#       'alg1' => {
#         'checksum'  => 'checksum of file/path1 using alg1',
#         'attr_name' => 'name of the used extended attribute',
#       },
#     },
#     'file/path2' => {
#       'alg2' => {
#         'checksum'  => 'checksum of file/path2 using alg2',
#         'attr_name' => 'name of the used extended attribute',
#       },
#     },
#   }
# throws
#   FSTreeIntegrityWatch::Exception or their subclasses in case of errors during
#   processing.
sub store_checksums {

    my $self = shift @_;

    my $results = {};

    foreach my $file (@{$self->files()}) {
        foreach my $alg (@{$self->algorithms()}) {
            my $attr = $alg;
            my $checksum = get_file_checksum($alg, $file);
            store_file_checksum($file, $attr, $checksum);
            $results->{$file}->{$alg}->{'checksum'} = $checksum;
            $results->{$file}->{$alg}->{'attr_name'} = $alg;
        }
    }

    return $results;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
