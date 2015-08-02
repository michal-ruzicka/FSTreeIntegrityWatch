
package FSTreeIntegrityWatch::Exception;

# Great tutorial:
# http://www.drdobbs.com/web-development/exception-handling-in-perl-with-exceptio/184416129

use strict;
use warnings;
use utf8;


# Public methods
use Exporter 'import';
our @EXPORT_OK = qw(
    general_error
    config_error
    digest_error
    extattr_error
);
our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
);



# Configures inclusion/exclusion of stack trace in exception error messages.
our $exception_verbosity = 0;

# Declare hierarchy of exceptions.
use Exception::Class (

    'FSTreeIntegrityWatch::Exception' => {
        'alias'       => 'general_error',
        'description' => 'generic base class for all FSTreeIntegrityWatch exceptions',
    },

    'FSTreeIntegrityWatch::Exception::Configuration' => {
        'alias'       => 'config_error',
        'isa'         => 'FSTreeIntegrityWatch::Exception',
        'description' => 'improper FSTreeIntegrityWatch module configuration',
    },

    'FSTreeIntegrityWatch::Exception::Digest' => {
        'alias'       => 'digest_error',
        'isa'         => 'FSTreeIntegrityWatch::Exception',
        'description' => 'error thrown during hash computation',
    },

    'FSTreeIntegrityWatch::Exception::ExtAttr' => {
        'alias'       => 'extattr_error',
        'isa'         => 'FSTreeIntegrityWatch::Exception',
        'description' => 'error thrown when working with extended attributes',
    },

);

# Controls whether or not a stack trace is included in the value of the
# as_string() method for an object of a class. If Trace() is set to a true
# value, then the class and its children will default to including a trace.
sub Trace {
    return $exception_verbosity;
}


1;


# vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
