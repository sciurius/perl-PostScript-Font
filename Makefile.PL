# Makefile.PL -- Makefile for makepatch
# Author          : Ulrich Pfeifer
# Created On      : Mon Feb 17 10:51:47 1997
# Last Modified By: Johan Vromans
# Last Modified On: Mon Feb  8 11:46:56 1999
# Update Count    : 59
# Status          : Released

# Verify perl version.
require 5.000;

use ExtUtils::MakeMaker;

my @scripts = qw(fontsampler pfb2pfa);

WriteMakefile
  (
   NAME         => 'PostScript::Fonts',
   AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
   ABSTRACT	=> 'Modules to get info from PostScript fonts',
   VERSION      => "0.01",
   PREREQ_PM	=> { 'Getopt::Long' => 2.00, 'IO' => 0 },
   EXE_FILES    => [ map { "scripts/$_" } @scripts ],
   # *.pm files will be picked up automatically from ./lib
 );
