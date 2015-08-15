#!/bin/bash

export ifile='extattr-file-integrity.pl'
export dependencie='
-M Class::Tiny
-M DateTime
-M Digest
-M Encode
-M Encode::Locale
-M Exception::Class
-M Exporter
-M File::ExtAttr
-M File::Find::utf8
-M File::Spec
-M FindBin
-M Getopt::Long
-M JSON
-M List::Compare
-M List::MoreUtils
-M List::MoreUtils::PP
-M List::Util
-M Module::Load
-M Scalar::Util
-M Try::Tiny
-M Digest::Adler32
-M Digest::BLAKE
-M Digest::BLAKE2
-M Digest::BMW
-M Digest::CRC
-M Digest::ECHO
-M Digest::ED2K
-M Digest::EdonR
-M Digest::Fugue
-M Digest::GOST
-M Digest::Groestl
-M Digest::Hamsi
-M Digest::JH
-M Digest::Keccak
-M Digest::Luffa
-M Digest::MD2
-M Digest::MD4
-M Digest::MD5
-M Digest::SHA
-M Digest::SHA3
-M Digest::SHAvite3
-M Digest::SIMD
-M Digest::Shabal
-M Digest::Skein
-M Digest::Whirlpool
-I lib
    -M FSTreeIntegrityWatch
'
export PP_OPTS="--verbose=3 --compile --execute --clean --compress 9 $dependencies"


# Stand-alone setup
export ofile='extattr-file-integrity.packed-standalone'
echo "### Building"
echo "###   ${ofile}"
echo "### for use independently of Perl installation"
pp       -o "${ofile}" "${ifile}"

# For use with Perl interpreter only, without core modules
export ofile='extattr-file-integrity.packed-for-perl-interpreter-only-without-core-modules.pl'
echo "### Building"
echo "###   ${ofile}"
echo "### for use with Perl interpreter without core modules installed"
pp -B -P -o "${ofile}" "${ifile}"

# For use with Perl with core module installed
export ofile='extattr-file-integrity.packed-for-perl-interpreter-with-core-modules.pl'
echo "### Building"
echo "###   ${ofile}"
echo "### for use with Perl with core module installed"
pp    -P -o "${ofile}" "${ifile}"

# For use with Perl with PAR.pm and its dependencies installed
export ofile='extattr-file-integrity.packed-for-perl-interpreter-with-PAR.pm-and-its-dependencies.pl'
echo "### Building"
echo "###   ${ofile}"
echo "###   ${ofile%.pl}.par"
echo "### for use with Perl with PAR.pm and its dependencies installed"
pp       -o "${ofile%.pl}.par" -p "${ifile}"
head -n 1 "${ifile}" > "${ofile}"
echo "use PAR '${ofile%.pl}.par';" >> "${ofile}"
tac "${ifile}" | head -n -1 | tac >> "${ofile}"
chmod u+x "${ofile}"
