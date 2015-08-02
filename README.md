FSTreeIntegrityWatch
====================

Filesystem Extended Attributes File Integrity Tool
--------------------------------------------------

Tool to store/check file integrity information in filesystem extended
attributes.

See
 * http://man7.org/linux/man-pages/man5/attr.5.html


### FSTreeIntegrityWatch::Digest

The module loads `Digest::*` modules dynamically based on arbitrary algorithm
name provided by the caller. An exception is thrown if appropriate digest module 
is not available in the system.

See
 * http://search.cpan.org/~gaas/Digest/Digest.pm


### FSTreeIntegrityWatch::ExtAttr

The module uses `File::ExtAttr` module that depends on `libattr`.

In case of `cpan File::ExtAttr` installation error your system possibly needs
`libattr-devel` packages to be installed.

See
 * http://search.cpan.org/~richdawe/File-ExtAttr/lib/File/ExtAttr.pm


### Error Handling

The module uses `FSTreeIntegrityWatch::Exception::*` exceptions to handles
errors. The system is base on `Exception::Class` modules.

See
 * http://search.cpan.org/~drolsky/Exception-Class/lib/Exception/Class.pm
 * http://www.drdobbs.com/web-development/exception-handling-in-perl-with-exceptio/184416129


### Object-Oriented Programming

FSTreeIntegrityWatch modules construct objects using `Class::Tiny` minimalist
class constructor module.

At least version 1.001 of the `Class::Tiny` module is required as older versions
lack the BUILDARGS method some of the `FSTreeIntegrityWatch::*` modules use.

See
 * http://search.cpan.org/~dagolden/Class-Tiny/lib/Class/Tiny.pm
 * http://perldoc.perl.org/perlootut.html



<!--
  vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
-->
