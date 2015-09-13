FSTreeIntegrityWatch
====================

Filesystem Tree File Integrity Watch Tool with BagIt Validation Support
-----------------------------------------------------------------------

A tool to store/check file integrity information in filesystem extended
attributes or JSON integrity database dump able to validate BagIt format.

See
 * http://man7.org/linux/man-pages/man5/attr.5.html
 * http://man7.org/linux/man-pages/man1/getfattr.1.html
 * http://man7.org/linux/man-pages/man1/setfattr.1.html
 * http://purl.org/net/bagit


## Usage

The tools has build-in help. To see usage information run

`fstree-integrity-watch.pl --help`


## BagIt Support

To work with BagIt format we are using Library of Congress implementation of the
validation tool. The tool is implemented in Python.

See
 * http://purl.org/net/bagit
 * https://github.com/LibraryOfCongress/bagit-python

### Installation

#### System installation

`pip install bagit`

Python v2.6+ is required.

#### Git

The official Git repository of the tools
(https://github.com/LibraryOfCongress/bagit-python) is available as submodule
under the `utils/bagit-python/` directory:

```bash
# after checkout
git submodule update --init --recursive
...
# to update working copy
git submodule update --recursive
```


## Dependencies & Implementation Notes

### CPAN Modules

The tools uses bunch of CPAN modules implementing useful functionality. To run
the tool install the needed modules using your distribution software management
tool or install up-to-date versions directly from CPAN:

`cpan Class::Tiny DateTime Digest Encode Encode::Locale Exception::Class
Exporter File::Basename File::ExtAttr File::Find File::Spec FindBin
Getopt::Long IPC::Open3 JSON List::Compare List::MoreUtils List::Util
Module::Load Scalar::Util Try::Tiny`

Various digest algorithms are implemented in separate modules. The modules are
loaded dynamically at runtime when needed so it is sufficient to install the
implementation of algorithms you are going to use.

`cpan Digest::Adler32 Digest::BLAKE Digest::BLAKE2 Digest::BMW Digest::CRC
Digest::ECHO Digest::ED2K Digest::EdonR Digest::Fugue Digest::GOST
Digest::Groestl Digest::Hamsi Digest::JH Digest::Keccak Digest::Luffa
Digest::MD2 Digest::MD4 Digest::MD5 Digest::SHA Digest::SHA3 Digest::SHAvite3
Digest::SIMD Digest::Shabal Digest::Skein Digest::Whirlpool`

See
  * http://www.cpan.org/

### FSTreeIntegrityWatch::Digest

The module loads `Digest::*` modules dynamically using `Module::Load` based on
algorithm selected by the caller. An exception is thrown if appropriate digest
module is not available in the system.

See
 * https://metacpan.org/pod/Digest
 * https://metacpan.org/pod/Module::Load


### FSTreeIntegrityWatch::ExtAttr

The module uses `File::ExtAttr` module that depends on `libattr`.

**In case of `cpan File::ExtAttr` installation error your system possibly needs
`libattr-devel` packages to be installed.**

See
 * https://metacpan.org/pod/File::ExtAttr


### Error Handling

The module uses `FSTreeIntegrityWatch::Exception::*` exceptions to handles
errors. The system is base on `Exception::Class` modules.

See
 * https://metacpan.org/pod/Exception::Class
 * http://www.drdobbs.com/web-development/exception-handling-in-perl-with-exceptio/184416129


### Object-Oriented Programming

FSTreeIntegrityWatch modules construct objects using `Class::Tiny` minimalist
class constructor module.

At least version 1.001 of the `Class::Tiny` module is required as older versions
lack the BUILDARGS method some of the `FSTreeIntegrityWatch::*` modules use.

See
 * https://metacpan.org/pod/Class::Tiny
 * http://perldoc.perl.org/perlootut.html


### Command Line Parsing

Command line arguments are processed using `Getopt::Long` module. GNU getopt
and advanced features such as options bundling and auto completion can be used.

See
 * https://metacpan.org/pod/Getopt::Long


## All-in-one executable

**This feature is highly experimental!**

You can use Perl Archive Toolkit (PAR) to create a single all-in-one binary
executable of the tool.

It is necessary to have `PAR::Packer` tool installed:

`cpan PAR::Packer`

Than you can pack the script with all the dependencies running

`pack-to-executable.sh`

producing standalone binary executable `fstree-integrity-watch.packed-standalone`
and Perl scripts `fstree-integrity-watch.packed-*.pl` with various level of
dependencies packed inside to be run on slim Perl installations.

See
  * https://metacpan.org/pod/pp
  * https://metacpan.org/pod/PAR::Tutorial
  * https://metacpan.org/pod/PAR::Packer
  * https://metacpan.org/pod/PAR



<!--
  vim:textwidth=80:expandtab:tabstop=4:shiftwidth=4:fileencodings=utf8:spelllang=en
-->
