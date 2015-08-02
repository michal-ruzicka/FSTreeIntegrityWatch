
package FSTreeIntegrityWatch::ExtAttr;

use strict;
use warnings;
use utf8;


# Package modules
use FSTreeIntegrityWatch::Tools qw(decode_locale_if_necessary);

# External modules
use File::ExtAttr ':all';
use Try::Tiny;


# Use Class::Tiny for class construction.
use Class::Tiny 1.001 qw(context); # BUILDARGS method was introduced in version 1.001 of the module.



# Constructor arguments hook validates parameters.
sub BUILDARGS {

    my $class = shift @_;
    my $context = shift @_;

    # If not context (i.e. FSTreeIntegrityWatch base class instance) is provided
    # by the caller, create an instance with default parameters.
    if (not defined($context)) {
        $context = FSTreeIntegrityWatch->new();
    }

    return { 'context' => $context };

}

# Store checksums in extended attributes for all files in checksums hash ref of
# the instance's context.
# returns
#   stored_ext_attrs hash ref of the instance's context
# throws
#   FSTreeIntegrityWatch::Exception::ExtAttr in case of any error
sub store_checksums {

    my $self = shift @_;

    my $cs        = $self->context->checksums();
    my $sa        = $self->context->stored_ext_attrs();
    my $attr_pref = $self->context->ext_attr_name_prefix();

    foreach my $filename (keys %$cs) {
        foreach my $alg (keys %{$cs->{$filename}}) {

            my $checksum = $cs->{$filename}->{$alg}->{'checksum_value'};

            my $err = undef;
            if (not defined($filename)) {
                $err = "No filename specified.";
            } elsif (-e $filename and -f $filename and -w $filename) {
                $err = "No valid extended attribute name provided." if (not defined($attr_pref) or $attr_pref =~ /^\s*$/);
                $err = "No valid checksum provided." if (not defined($checksum) or $checksum =~ /^\s*$/);
            } else {
                $err = "'$filename' is not a writable file.";
            }

            my $attr_name = sprintf("%s.%s", $attr_pref, $alg);

            $self->context->exp('ExtAttr', $err) if (defined($err));
            setfattr($filename, $attr_name, $checksum)
                or $self->context->exp('ExtAttr', "Failed to store checksum '$checksum' to file '$filename' in extended attribute '$attr_name': ".decode_locale_if_necessary($!));

            $sa->{$filename}->{$alg}->{'stored_at'} = time;
            $sa->{$filename}->{$alg}->{'attr_name'} = $attr_name;
            $sa->{$filename}->{$alg}->{'attr_value'} = $checksum;

        }
    }

    return $sa;

}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
