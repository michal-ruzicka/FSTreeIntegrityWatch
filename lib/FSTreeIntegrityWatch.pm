
package FSTreeIntegrityWatch;

use strict;
use warnings;
use utf8;


# Package modules
use FSTreeIntegrityWatch::Digest;
use FSTreeIntegrityWatch::Exception;
use FSTreeIntegrityWatch::ExtAttr;


# Use Class::Tiny for class construction.
use subs 'exception_verbosity'; # Necessary to provide our own accessor.
use Class::Tiny {
    'exception_verbosity'  => 0,
    'ext_attr_name_prefix' => 'extattr-file-integrity',
    'algorithms'           => [ "SHA-1" ],
    'files'                => [ ],
    'checksums'            => {},
    'stored_ext_attrs'     => {},
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
# and stores the results to the extended attributes of the files.
# returns
#   stored_ext_attrs hash ref of the used context
# throws
#   FSTreeIntegrityWatch::Exception or their subclasses in case of errors during
#   processing.
sub store_checksums {

    my $self = shift @_;

    my $digest  = FSTreeIntegrityWatch::Digest->new($self);
    my $extattr = FSTreeIntegrityWatch::ExtAttr->new($self);

    $digest->compute_checksums();
    return $extattr->store_checksums();

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
